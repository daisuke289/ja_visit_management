# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "user#{n}@example.com" }
    password { "password123" }
    sequence(:name) { |n| "テストユーザー#{n}" }
    role { :branch_manager }
    association :branch

    trait :admin do
      role { :admin }
      branch { nil }
    end

    trait :system_admin do
      role { :system_admin }
      branch { nil }
    end

    trait :branch_manager do
      role { :branch_manager }
    end
  end
end
