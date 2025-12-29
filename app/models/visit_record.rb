# app/models/visit_record.rb
class VisitRecord < ApplicationRecord
  # リレーション
  belongs_to :customer
  belongs_to :user
  belongs_to :visit_type
  belongs_to :visit_plan, optional: true

  has_many :actions, dependent: :destroy
  has_many_attached :attachments

  # バリデーション
  validates :visited_at, presence: true
  validates :content, presence: true, length: { minimum: 50, message: 'は50文字以上で入力してください' }

  # スコープ
  scope :by_branch, ->(branch_id) {
    joins(:customer).where(customers: { branch_id: branch_id })
  }
  scope :recent, -> { order(visited_at: :desc) }
  scope :in_period, ->(start_date, end_date) {
    where(visited_at: start_date.beginning_of_day..end_date.end_of_day)
  }
  scope :by_visit_type, ->(visit_type_id) { where(visit_type_id: visit_type_id) }

  # コールバック
  after_create :update_customer_last_visit_date
  after_create :complete_visit_plan, if: :visit_plan_id?

  # メソッド
  def duration_display
    visited_at.strftime('%Y/%m/%d %H:%M')
  end

  def content_preview(length: 50)
    content.truncate(length)
  end

  # 次アクション作成
  def create_next_action!(title:, due_date:, user: self.user)
    actions.create!(
      customer: customer,
      user: user,
      title: title,
      due_date: due_date,
      status: :pending
    )
  end

  private

  def update_customer_last_visit_date
    customer.update_last_visit_date!
  end

  def complete_visit_plan
    visit_plan.update!(status: :completed, visit_record_id: id) if visit_plan.scheduled?
  end
end
