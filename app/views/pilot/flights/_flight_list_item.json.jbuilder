# frozen_string_literal: true

if flight.destroyed?
  json.call flight, :uuid, :destroyed?
else
  json.call flight, :uuid, :date, :description, :passenger_count
end
