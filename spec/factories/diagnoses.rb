# frozen_string_literal: true

FactoryBot.define do
  factory :diagnosis do
    association :customer
    association :user
    diagnosed_on { Date.current }
    sequence(:title) { |n| "#{Date.current.year}年度財産診断#{n}" }
    notes { "テスト備考" }
  end
end
