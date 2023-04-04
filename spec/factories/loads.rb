# frozen_string_literal: true

FactoryBot.define do
  factory :load do
    flight

    trait :passenger do
      sequence(:name) { |i| "passenger-#{i}" }
      weight { rand(100..300) }
      bags_weight { FFaker::Boolean.maybe ? rand(5..50) : 0 }
    end

    trait :cargo do
      sequence(:name) { |i| "cargo-#{i}" }
      weight { 0 }
      bags_weight { rand(20..50) }
    end
  end
end
