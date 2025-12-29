# frozen_string_literal: true

FactoryBot.define do
  factory :ja_customer do
    sequence(:customer_number) { |n| format("JA%08d", n) }
    sequence(:name) { |n| "JA顧客#{n}" }
    sequence(:name_kana) { |n| "ジェイエーコキャク#{n}" }
    birth_date { 40.years.ago }
    postal_code { "100-0001" }
    address { "東京都千代田区" }
    phone { "03-1234-5678" }
    association :branch
    has_banking { true }
    has_mutual_aid { false }
    has_agriculture { false }
    has_funeral { false }
    has_gas { false }
    has_real_estate { false }
  end
end
