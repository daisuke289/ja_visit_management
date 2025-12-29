# frozen_string_literal: true

FactoryBot.define do
  factory :visit_record do
    association :customer
    association :user
    association :visit_type
    visit_plan { nil }
    visited_at { Time.current }
    interviewee { "世帯主本人" }
    content { "本日は定期訪問として伺いました。お変わりなくお過ごしとのことです。特に相談事項はありませんでした。" }
    customer_situation { "良好" }
  end
end
