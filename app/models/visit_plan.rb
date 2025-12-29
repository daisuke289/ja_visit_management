# app/models/visit_plan.rb
class VisitPlan < ApplicationRecord
  # リレーション
  belongs_to :customer
  belongs_to :user
  belongs_to :visit_type
  has_one :visit_record

  # ステータス
  enum :status, {
    scheduled: 0,   # 予定
    completed: 1,   # 完了
    cancelled: 2    # 中止
  }

  # バリデーション
  validates :planned_date, presence: true
  validates :status, presence: true

  # スコープ
  scope :by_branch, ->(branch_id) {
    joins(:customer).where(customers: { branch_id: branch_id })
  }
  scope :upcoming, -> {
    where(status: :scheduled)
      .where('planned_date >= ?', Date.current)
      .order(:planned_date)
  }
  scope :this_week, -> {
    where(planned_date: Date.current.beginning_of_week..Date.current.end_of_week)
  }
  scope :this_month, -> {
    where(planned_date: Date.current.beginning_of_month..Date.current.end_of_month)
  }
  scope :overdue, -> {
    where(status: :scheduled).where('planned_date < ?', Date.current)
  }

  # メソッド
  def display_date
    if planned_time.present?
      "#{planned_date.strftime('%Y/%m/%d')} #{planned_time.strftime('%H:%M')}"
    else
      planned_date.strftime('%Y/%m/%d')
    end
  end

  def overdue?
    scheduled? && planned_date < Date.current
  end

  def days_until
    return nil unless scheduled?
    (planned_date - Date.current).to_i
  end

  def complete_with_record!(visit_record)
    transaction do
      visit_record.update!(visit_plan: self)
      update!(status: :completed)
    end
  end

  def cancel!(reason: nil)
    update!(status: :cancelled, purpose: "#{purpose}\n【中止理由】#{reason}".strip)
  end

  # iCal出力用
  def to_ical
    require 'icalendar'

    cal = Icalendar::Calendar.new
    cal.event do |e|
      e.dtstart = planned_time.present? ?
        Icalendar::Values::DateTime.new(DateTime.new(planned_date.year, planned_date.month, planned_date.day, planned_time.hour, planned_time.min)) :
        Icalendar::Values::Date.new(planned_date)
      e.summary = "【訪問】#{customer.name} - #{visit_type.name}"
      e.description = purpose
      e.location = customer.address
    end
    cal.to_ical
  end
end
