class CustomerImportJob < ApplicationJob
  queue_as :default

  def perform(file_content, filename, user_id)
    require 'csv'
    require 'tempfile'

    user = User.find(user_id)
    imported = 0
    skipped = 0
    errors = []
    start_time = Time.current

    tempfile = Tempfile.new(['import', File.extname(filename)])
    begin
      tempfile.binmode
      tempfile.write(file_content.force_encoding('UTF-8'))
      tempfile.rewind

      CSV.foreach(tempfile.path, headers: true, encoding: 'Shift_JIS:UTF-8') do |row|
        result = process_row(row)
        case result[:status]
        when :created
          imported += 1
        when :skipped
          skipped += 1
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

    log_import_result(
      import_type: 'customers',
      user: user,
      filename: filename,
      imported: imported,
      skipped: skipped,
      errors: errors,
      duration: Time.current - start_time
    )

    Rails.logger.info "[CustomerImportJob] Completed: #{imported} imported, #{skipped} skipped, #{errors.size} errors"
  end

  private

  def process_row(row)
    customer_number = row['顧客番号']&.strip
    return { status: :error, error: { row: row.to_h, error: '顧客番号がありません' } } if customer_number.blank?

    # 既に重要取引先として登録済みならスキップ
    if Customer.exists?(customer_number: customer_number)
      return { status: :skipped }
    end

    # JA全顧客マスタから情報を取得
    ja_customer = JaCustomer.find_by(customer_number: customer_number)

    if ja_customer
      # JA全顧客マスタの情報を使用
      customer = Customer.new(
        customer_number: customer_number,
        household_number: ja_customer.household_number,
        name: ja_customer.name,
        name_kana: ja_customer.name_kana,
        postal_code: ja_customer.postal_code,
        address: ja_customer.address,
        phone: ja_customer.phone,
        branch: ja_customer.branch
      )
    else
      # CSVから直接情報を取得（JA全顧客マスタにない場合）
      branch = Branch.find_by(code: row['支店コード']&.strip)
      customer = Customer.new(
        customer_number: customer_number,
        household_number: row['世帯番号']&.strip,
        name: row['氏名']&.strip,
        name_kana: row['氏名カナ']&.strip,
        postal_code: row['郵便番号']&.strip,
        address: row['住所']&.strip,
        phone: row['電話番号']&.strip,
        branch: branch
      )
    end

    if customer.save
      { status: :created }
    else
      { status: :error, error: { row: customer_number, errors: customer.errors.full_messages } }
    end
  end

  def log_import_result(import_type:, user:, filename:, imported:, skipped:, errors:, duration:)
    return unless defined?(ImportLog)

    ImportLog.create!(
      import_type: import_type,
      user: user,
      filename: filename,
      imported_count: imported,
      skipped_count: skipped,
      error_count: errors.size,
      error_details: errors.to_json,
      duration_seconds: duration.to_i,
      completed_at: Time.current
    )
  end
end
