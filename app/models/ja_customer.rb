# app/models/ja_customer.rb
class JaCustomer < ApplicationRecord
  # リレーション
  belongs_to :branch, optional: true

  # バリデーション
  validates :customer_number, presence: true, uniqueness: true
  validates :name, presence: true

  # スコープ
  scope :by_branch, ->(branch_id) { where(branch_id: branch_id) }
  scope :with_banking, -> { where(has_banking: true) }
  scope :with_mutual_aid, -> { where(has_mutual_aid: true) }
  scope :with_agriculture, -> { where(has_agriculture: true) }
  scope :search, ->(query) {
    where("name LIKE ? OR name_kana LIKE ? OR customer_number LIKE ?",
          "%#{query}%", "%#{query}%", "%#{query}%")
  }

  # メソッド
  def age
    return nil unless birth_date
    today = Date.current
    age = today.year - birth_date.year
    age -= 1 if today < birth_date + age.years
    age
  end

  def display_name
    parts = [ name ]
    parts << "(#{name_kana})" if name_kana.present?
    parts.join(" ")
  end

  # 事業取引状況
  def business_flags
    {
      banking: has_banking?,
      mutual_aid: has_mutual_aid?,
      agriculture: has_agriculture?,
      funeral: has_funeral?,
      gas: has_gas?,
      real_estate: has_real_estate?
    }
  end

  def business_summary
    flags = []
    flags << "金融" if has_banking?
    flags << "共済" if has_mutual_aid?
    flags << "営農" if has_agriculture?
    flags << "葬祭" if has_funeral?
    flags << "ガス" if has_gas?
    flags << "不動産" if has_real_estate?
    flags.join("・")
  end

  def total_balance
    (deposit_balance || 0) + (loan_balance || 0)
  end

  # 重要取引先として登録されているか
  def registered_as_customer?
    Customer.exists?(customer_number: customer_number)
  end

  def customer
    Customer.find_by(customer_number: customer_number)
  end

  # CSVインポート用クラスメソッド
  class << self
    def import_from_csv(file)
      require "csv"

      imported = 0
      errors = []

      CSV.foreach(file.path, headers: true, encoding: "Shift_JIS:UTF-8") do |row|
        customer = find_or_initialize_by(customer_number: row["顧客番号"])

        customer.assign_attributes(
          household_number: row["世帯番号"],
          name: row["氏名"],
          name_kana: row["氏名カナ"],
          birth_date: parse_date(row["生年月日"]),
          postal_code: row["郵便番号"],
          address: row["住所"],
          phone: row["電話番号"],
          deposit_balance: row["預金残高"],
          loan_balance: row["貸出残高"],
          has_banking: row["金融取引"] == "1",
          has_mutual_aid: row["共済加入"] == "1",
          has_agriculture: row["営農取引"] == "1",
          has_funeral: row["葬祭加入"] == "1",
          has_gas: row["ガス契約"] == "1",
          has_real_estate: row["不動産取引"] == "1",
          last_synced_at: Time.current
        )

        # 支店紐付け
        if row["支店コード"].present?
          customer.branch = Branch.find_by(code: row["支店コード"])
        end

        if customer.save
          imported += 1
        else
          errors << { row: row["顧客番号"], errors: customer.errors.full_messages }
        end
      end

      { imported: imported, errors: errors }
    end

    private

    def parse_date(str)
      return nil if str.blank?
      Date.parse(str)
    rescue ArgumentError
      nil
    end
  end
end
