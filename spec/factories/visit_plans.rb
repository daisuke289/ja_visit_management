# frozen_string_literal: true

FactoryBot.define do
  factory :visit_plan do
    association :customer
    association :user
    association :visit_type
    planned_date { 1.week.from_now }
    purpose { "定期訪問" }
    status { :scheduled }
  end
end
