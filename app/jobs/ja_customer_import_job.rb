class JaCustomerImportJob < ApplicationJob
  queue_as :default

  def perform(file_content, filename, user_id)
    require 'csv'
    require 'tempfile'

    user = User.find(user_id)
    imported = 0
    updated = 0
    errors = []
    start_time = Time.current

    # 一時ファイルを作成
    tempfile = Tempfile.new(['import', File.extname(filename)])
    begin
      tempfile.binmode
      tempfile.write(file_content.force_encoding('UTF-8'))
      tempfile.rewind

      # CSVを処理
      CSV.foreach(tempfile.path, headers: true, encoding: 'Shift_JIS:UTF-8') do |row|
        result = process_row(row)
        case result[:status]
        when :created
          imported += 1
        when :updated
          updated += 1
        when :error
          errors << result[:error]
        end
      rescue => e
        errors << { row: row.to_h, error: e.message }
      end
    ensure
      tempfile.close
      tempfile.unlink
    end

    # ログ記録（ImportLogモデルがある場合）
    log_import_result(
      import_type: 'ja_customers',
      user: user,
      filename: filename,
      imported: imported,
      updated: updated,
      errors: errors,
      duration: Time.current - start_time
    )

    Rails.logger.info "[JaCustomerImportJob] Completed: #{imported} created, #{updated} updated, #{errors.size} errors"
  end

  private

  def process_row(row)
    customer_number = row['顧客番号']&.strip
    return { status: :error, error: { row: row.to_h, error: '顧客番号がありません' } } if customer_number.blank?

    customer = JaCustomer.find_or_initialize_by(customer_number: customer_number)
    is_new = customer.new_record?

    customer.assign_attributes(
      household_number: row['世帯番号']&.strip,
      name: row['氏名']&.strip,
      name_kana: row['氏名カナ']&.strip,
      birth_date: parse_date(row['生年月日']),
      postal_code: row['郵便番号']&.strip,
      address: row['住所']&.strip,
      phone: row['電話番号']&.strip,
      deposit_balance: parse_decimal(row['預金残高']),
      loan_balance: parse_decimal(row['貸出残高']),
      has_banking: row['金融取引'] == '1',
      has_mutual_aid: row['共済加入'] == '1',
      has_agriculture: row['営農取引'] == '1',
      has_funeral: row['葬祭加入'] == '1',
      has_gas: row['ガス契約'] == '1',
      has_real_estate: row['不動産取引'] == '1',
      last_synced_at: Time.current
    )

    # 支店紐付け
    if row['支店コード'].present?
      branch = Branch.find_by(code: row['支店コード'].strip)
      customer.branch = branch if branch
    end

    if customer.save
      { status: is_new ? :created : :updated }
    else
      { status: :error, error: { row: customer_number, errors: customer.errors.full_messages } }
    end
  end

  def parse_date(str)
    return nil if str.blank?
    Date.parse(str.strip)
  rescue ArgumentError
    nil
  end

  def parse_decimal(str)
    return nil if str.blank?
    str.to_s.gsub(/[,¥]/, '').to_d
  rescue
    nil
  end

  def log_import_result(import_type:, user:, filename:, imported:, updated:, errors:, duration:)
    # ImportLogモデルが存在する場合のみログを記録
    return unless defined?(ImportLog)

    ImportLog.create!(
      import_type: import_type,
      user: user,
      filename: filename,
      imported_count: imported,
      updated_count: updated,
      error_count: errors.size,
      error_details: errors.to_json,
      duration_seconds: duration.to_i,
      completed_at: Time.current
    )
  end
end
