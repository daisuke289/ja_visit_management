# frozen_string_literal: true

FactoryBot.define do
  factory :action do
    association :visit_record
    association :customer
    association :user
    title { "フォローアップ連絡" }
    due_date { 1.week.from_now }
    status { :pending }
  end
end
