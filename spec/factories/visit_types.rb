# frozen_string_literal: true

FactoryBot.define do
  factory :visit_type do
    sequence(:name) { |n| "訪問種別#{n}" }
    sequence(:display_order) { |n| n }
    active { true }
  end
end
