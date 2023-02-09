# frozen_string_literal: true

json.partial!("flights/flight", flight:)
json.can_edit true

json.loads do
  json.array! flight.loads, partial: "loads/load", as: :load
end
