# frozen_string_literal: true

# Skip metrics in test/cypress environments
return if Rails.env.test? || Rails.env.cypress?

require "yabeda/prometheus"

Yabeda.configure do
  group :flyweight do
    gauge :pilots_total,
          comment: "Total number of registered pilots",
          tags:    []

    gauge :flights_active,
          comment: "Number of flights with date >= today",
          tags:    []
  end

  collect do
    flyweight.pilots_total.set({}, Pilot.count)
    flyweight.flights_active.set({}, Flight.where(date: Date.current..).count)
  end
end

Yabeda.configure!
