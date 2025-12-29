# frozen_string_literal: true

FactoryBot.define do
  factory :branch do
    sequence(:code) { |n| format("%03d", n) }
    sequence(:name) { |n| "テスト支店#{n}" }
  end
end
