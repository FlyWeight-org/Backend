# frozen_string_literal: true

FactoryBot.define do
  factory :flight do
    pilot

    date { rand(1..30).days.ago }
    description { FFaker::Lorem.sentence }
  end
end
