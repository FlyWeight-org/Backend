# frozen_string_literal: true

FactoryBot.define do
  factory :pilot do
    name { FFaker::Name.name }
    sequence(:email) { |i| "email-#{i}@example.com" }
    password { FFaker::Internet.password }
    status_id { 2 }

    trait :unverified do
      status_id { 1 }
    end
  end
end
