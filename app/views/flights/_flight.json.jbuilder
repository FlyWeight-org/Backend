# frozen_string_literal: true

json.call flight, :uuid, :date, :description
json.can_edit false

json.pilot do
  json.partial! "pilots/pilot", pilot: flight.pilot
end
