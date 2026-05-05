# frozen_string_literal: true

class FlightListItemSerializer < ApplicationSerializer
  attributes :uuid
  destroyed_aware_attributes :date, :description, :passenger_count
end
