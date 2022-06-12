# frozen_string_literal: true

json.array! @flights, partial: "flight_list_item", as: :flight
