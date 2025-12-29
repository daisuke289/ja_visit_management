# app/models/customer.rb
class Customer < ApplicationRecord
  # リレーション
  belongs_to :branch
  has_many :family_members, dependent: :destroy
  has_many :visit_plans, dependent: :destroy
  has_many :visit_records, dependent: :destroy
  has_many :actions, dependent: :destroy
  has_many :diagnoses, dependent: :destroy

  # バリデーション
  validates :customer_number, presence: true, uniqueness: true
  validates :name, presence: true
  validates :branch, presence: true

  # スコープ
  scope :by_branch, ->(branch_id) { where(branch_id: branch_id) }
  scope :unvisited_for, ->(days) {
    where("last_visit_date IS NULL OR last_visit_date < ?", days.days.ago)
  }
  scope :search, ->(query) {
    where("name LIKE ? OR name_kana LIKE ? OR customer_number LIKE ?",
          "%#{query}%", "%#{query}%", "%#{query}%")
  }

  # コールバック
  after_save :update_last_visit_date, if: :saved_change_to_id?

  # メソッド
  def update_last_visit_date!
    last_visit = visit_records.order(visited_at: :desc).first
    update_column(:last_visit_date, last_visit&.visited_at&.to_date)
  end

  def days_since_last_visit
    return nil if last_visit_date.nil?
    (Date.current - last_visit_date).to_i
  end

  def visit_status
    days = days_since_last_visit
    return :never if days.nil?
    return :overdue if days > 30
    return :warning if days > 14
    :ok
  end

  def pending_actions
    actions.where(status: :pending).order(:due_date)
  end

  def overdue_actions
    actions.where(status: :pending).where("due_date < ?", Date.current)
  end

  # JA全顧客マスタとの紐付け
  def ja_customer
    JaCustomer.find_by(customer_number: customer_number)
  end

  def sync_from_ja_customer!
    ja = ja_customer
    return false unless ja

    update!(
      name: ja.name,
      name_kana: ja.name_kana,
      postal_code: ja.postal_code,
      address: ja.address,
      phone: ja.phone
    )
    true
  end

  private

  def update_last_visit_date
    update_last_visit_date!
  end
end
