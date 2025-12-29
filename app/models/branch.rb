# app/models/branch.rb
class Branch < ApplicationRecord
  # リレーション
  has_many :users, dependent: :restrict_with_error
  has_many :customers, dependent: :restrict_with_error
  has_many :ja_customers, dependent: :restrict_with_error

  # バリデーション
  validates :code, presence: true, uniqueness: true
  validates :name, presence: true

  # スコープ
  scope :ordered, -> { order(:code) }

  # メソッド
  def display_name
    "#{code}: #{name}"
  end

  # 訪問率計算
  def visit_rate(days: 30)
    total = customers.count
    return 0 if total.zero?

    visited = customers.where("last_visit_date >= ?", days.days.ago).count
    (visited.to_f / total * 100).round(1)
  end

  # 期限切れアクション数
  def overdue_actions_count
    Action.joins(:customer)
          .where(customers: { branch_id: id })
          .where(status: :pending)
          .where("due_date < ?", Date.current)
          .count
  end
end
