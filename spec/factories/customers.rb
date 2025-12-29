# frozen_string_literal: true

FactoryBot.define do
  factory :customer do
    sequence(:customer_number) { |n| format("C%08d", n) }
    sequence(:name) { |n| "顧客#{n}" }
    sequence(:name_kana) { |n| "コキャク#{n}" }
    postal_code { "100-0001" }
    address { "東京都千代田区" }
    phone { "03-1234-5678" }
    association :branch
  end
end
