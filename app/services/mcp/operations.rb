# frozen_string_literal: true

module Mcp
  # Applies assistant actions within one pilot's flight collection.
  class Operations
    POUNDS_PER_KILOGRAM = BigDecimal("2.2046226218")

    # @param pilot [Pilot] The authenticated resource owner.
    def initialize(pilot)
      @pilot = pilot
    end

    # @return [Hash] One page of flight summaries and a next-page number.
    def list_flights(page: 1, limit: 25)
      rows = @pilot.flights.with_passenger_count.order(date: :desc, id: :desc).offset((page - 1) * limit).limit(limit + 1).to_a
      {flights: rows.first(limit).map { |flight| summary(flight) }, next_page: (rows.length > limit) ? page + 1 : nil}
    end

    # @return [Hash] Flight details with loads and totals in the pilot's preferred unit.
    def get_flight(flight_id:)
      details(find_flight(flight_id))
    end

    # @return [Hash] The created flight and passenger invitation URL.
    def create_flight(date:, description: nil)
      details(@pilot.flights.create!(date: parse_date(date), description: description))
    end

    # @return [Hash] The updated flight.
    def update_flight(flight_id:, **attributes)
      flight = find_flight(flight_id)
      attributes[:date] = parse_date(attributes[:date]) if attributes.key?(:date)
      flight.update!(attributes.slice(:date, :description))
      details(flight)
    end

    # @return [Hash] The UUID of the deleted flight.
    def delete_flight(flight_id:)
      find_flight(flight_id).destroy!
      {deleted: true, flight_id: flight_id}
    end

    # Adds or replaces the load with the slug derived from the supplied name.
    # @return [Hash] The updated flight, including its loads.
    def upsert_load(flight_id:, name:, weight:, bags_weight:, unit:)
      flight = find_flight(flight_id)
      flight.with_lock do
        load = flight.loads.with_name(name)
        load.update!(name: name, weight: pounds(weight, unit), bags_weight: pounds(bags_weight, unit))
      end
      details(flight)
    end

    # @return [Hash] The identifiers of the deleted load.
    def delete_load(flight_id:, slug:)
      find_flight(flight_id).loads.find_by!(slug: slug).destroy!
      {deleted: true, flight_id: flight_id, slug: slug}
    end

    private

    def find_flight(uuid) = @pilot.flights.find_by!(uuid: uuid)

    def parse_date(value)
      raise ArgumentError, "Use a date in YYYY-MM-DD format." unless value.match?(/\A\d{4}-\d{2}-\d{2}\z/)

      Date.iso8601(value)
    rescue Date::Error
      raise ArgumentError, "Use a valid calendar date."
    end

    def pounds(value, unit)
      raise ArgumentError, "Weight unit must be lb or kg." unless %w[lb kg].include?(unit)

      amount = BigDecimal(value.to_s)
      raise ArgumentError, "Weights must be finite and nonnegative." unless amount.finite? && amount >= 0

      amount *= POUNDS_PER_KILOGRAM if unit == "kg"
      raise ArgumentError, "Weight exceeds the supported range." if amount.round(2) > BigDecimal("999999.99")

      amount.round(2)
    end

    def display_weight(pounds)
      amount = (@pilot.weight_unit == "kg") ? pounds / POUNDS_PER_KILOGRAM : pounds
      amount.round(2).to_f
    end

    def summary(flight)
      {uuid: flight.uuid, date: flight.date.iso8601, description: flight.description,
       passenger_count: flight.passenger_count,
       invitation_url: "#{Rails.application.config.urls.frontend}/flights/#{flight.uuid}"}
    end

    def details(flight)
      loads = flight.loads.order(:slug).to_a
      summary(flight).merge(
        unit:   @pilot.weight_unit,
        loads:  loads.map { |load| {slug: load.slug, name: load.name, weight: display_weight(load.weight), bags_weight: display_weight(load.bags_weight)} },
        totals: {weight: display_weight(loads.sum(&:weight)), bags_weight: display_weight(loads.sum(&:bags_weight)),
                 combined_weight: display_weight(loads.sum { |load| load.weight + load.bags_weight })}
      )
    end
  end
end
