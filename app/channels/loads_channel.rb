# frozen_string_literal: true

# Action Cable channel for transmitting changes to {Load}s for a Flight.
#
# Parameters
# ----------
#
# |      |                       |
# |:-----|:----------------------|
# | `id` | The UUID of a Flight. |

class LoadsChannel < ApplicationCable::Channel

  # @private
  def subscribed
    (flight = current_pilot.flights.find_by(uuid: params[:id])) or reject
    stream_for flight
  end

  # @private
  module Coder
    extend self

    # @private
    def encode(load)
      ApplicationController.render partial: "loads/load", locals: {load:}
    end
  end
end
