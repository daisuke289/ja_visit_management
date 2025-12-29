# frozen_string_literal: true

class CalendarController < ApplicationController
  def show
    @start_date = params[:start_date]&.to_date || Date.current.beginning_of_month

    # 訪問計画を取得
    @visit_plans = policy_scope(VisitPlan)
                     .includes(:customer, :user, :visit_type)
                     .where(planned_date: @start_date.beginning_of_month..@start_date.end_of_month)
                     .where(status: [ :scheduled, :completed ])

    # 訪問記録を取得（計画外の訪問も表示）
    @visit_records = policy_scope(VisitRecord)
                       .includes(:customer, :user, :visit_type)
                       .where(visited_at: @start_date.beginning_of_month..@start_date.end_of_month)
  end

  def ical
    @visit_plans = policy_scope(VisitPlan)
                     .includes(:customer, :user, :visit_type)
                     .where(status: :scheduled)
                     .where("planned_date >= ?", Date.current)

    calendar = Icalendar::Calendar.new
    calendar.prodid = "-//JA Visit Management//JP"

    @visit_plans.each do |plan|
      calendar.event do |e|
        e.dtstart = Icalendar::Values::Date.new(plan.planned_date)
        e.dtend = Icalendar::Values::Date.new(plan.planned_date + 1.day)
        e.summary = "訪問: #{plan.customer.name}"
        e.description = "種別: #{plan.visit_type.name}\n目的: #{plan.purpose}"
        e.location = plan.customer.address
        e.uid = "visit-plan-#{plan.id}@ja-visit-management"
      end
    end

    send_data calendar.to_ical,
              filename: "visit_plans.ics",
              type: "text/calendar",
              disposition: "attachment"
  end
end
