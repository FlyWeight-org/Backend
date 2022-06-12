# frozen_string_literal: true

if authorized_flight?
  json.partial! "pilot/flights/flight", flight: @flight
else
  json.partial! "flight", flight: @flight
end
