# frozen_string_literal: true

# Action Cable channel for transmitting changes to {Flight}s.

class FlightsChannel < ApplicationCable::Channel

  # @private
  def subscribed = stream_for current_pilot, coder: nil

  # @private
  module Coder
    extend self

    # @private
    def encode(flight)
      ApplicationController.render partial: "pilot/flights/flight_list_item",
                                   locals:  {flight:}
    end
  end
end
