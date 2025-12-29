# frozen_string_literal: true

FactoryBot.define do
  factory :family_member do
    association :customer
    sequence(:name) { |n| "家族#{n}" }
    sequence(:name_kana) { |n| "カゾク#{n}" }
    birth_date { 30.years.ago }
    relationship { "配偶者" }
    relationship_type { :spouse }
    generation { 0 }
    is_living { true }
    is_cohabitant { true }

    trait :householder do
      relationship { "世帯主" }
      relationship_type { :householder }
      generation { 0 }
    end

    trait :spouse do
      relationship { "配偶者" }
      relationship_type { :spouse }
      generation { 0 }
    end

    trait :child do
      relationship { "長男" }
      relationship_type { :child }
      generation { -1 }
    end

    trait :parent do
      relationship { "父" }
      relationship_type { :parent }
      generation { 1 }
    end

    trait :deceased do
      is_living { false }
    end

    trait :with_ja_customer do
      after(:build) do |family_member|
        ja_customer = create(:ja_customer, branch: family_member.customer.branch)
        family_member.ja_customer_number = ja_customer.customer_number
      end
    end
  end
end
