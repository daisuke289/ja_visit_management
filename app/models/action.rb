# app/models/action.rb
class Action < ApplicationRecord
  # リレーション
  belongs_to :visit_record
  belongs_to :customer
  belongs_to :user
  belongs_to :next_visit_record, class_name: "VisitRecord", optional: true

  # ステータス
  enum :status, {
    pending: 0,     # 未完了
    completed: 1,   # 完了
    cancelled: 2    # 中止
  }

  # バリデーション
  validates :title, presence: true
  validates :due_date, presence: true
  validates :status, presence: true

  # スコープ
  scope :by_branch, ->(branch_id) {
    joins(:customer).where(customers: { branch_id: branch_id })
  }
  scope :overdue, -> {
    where(status: :pending).where("due_date < ?", Date.current)
  }
  scope :due_soon, ->(days: 7) {
    where(status: :pending)
      .where("due_date <= ?", days.days.from_now)
      .where("due_date >= ?", Date.current)
  }
  scope :by_user, ->(user_id) { where(user_id: user_id) }
  scope :ordered_by_due_date, -> { order(:due_date) }

  # メソッド
  def overdue?
    pending? && due_date < Date.current
  end

  def days_until_due
    (due_date - Date.current).to_i
  end

  def due_status
    return :completed if completed?
    return :cancelled if cancelled?
    return :overdue if overdue?
    return :due_soon if days_until_due <= 7
    :ok
  end

  def due_status_label
    case due_status
    when :overdue then "期限切れ"
    when :due_soon then "期限間近"
    when :completed then "完了"
    when :cancelled then "中止"
    else "予定"
    end
  end

  # 完了処理（次の訪問記録を作成）
  def complete!(visit_record: nil)
    transaction do
      update!(
        status: :completed,
        completed_at: Time.current,
        next_visit_record: visit_record
      )
    end
  end

  def cancel!(reason: nil)
    update!(
      status: :cancelled,
      title: reason.present? ? "#{title}【中止：#{reason}】" : title
    )
  end

  # アラート対象かどうか
  def alert?
    pending? && (overdue? || days_until_due <= 3)
  end
end
