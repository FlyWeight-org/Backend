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

  # Fly scrapes /metrics every 15s. Querying on every scrape would keep the
  # Neon compute permanently awake — it suspends only after 5 minutes idle —
  # so both counts come from one cache entry refreshed once a day. The key is
  # date-stamped because flights_active is relative to today; a flat TTL would
  # serve a count computed against a stale Date.current.
  collect do
    counts = Rails.cache.fetch("yabeda/flyweight/counts/#{Date.current}", expires_in: 1.day) do
      {pilots: Pilot.count, flights_active: Flight.where(date: Date.current..).count}
    end

    flyweight.pilots_total.set({}, counts[:pilots])
    flyweight.flights_active.set({}, counts[:flights_active])
  rescue ActiveRecord::ConnectionNotEstablished, PG::Error
    # Leave the gauges unset rather than 500 the scrape; a database outage is
    # already reported by the requests that actually need it.
    nil
  end
end

Yabeda.configure!
