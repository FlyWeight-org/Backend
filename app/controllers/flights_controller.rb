# frozen_string_literal: true

# RESTful controller for working with {Flight}s. This controller is used by
# passengers (unauthenticated sessions). Pilots can create and edit flights
# using {Pilot::FlightsController}.

class FlightsController < ApplicationController
  before_action :find_flight
  helper_method :authorized_flight?

  # Displays JSON information about a flight.
  #
  # Routes
  # ------
  #
  # * `GET /flights/:id.json`
  #
  # Path Parameters
  # ---------------
  #
  # |      |                       |
  # |:-----|:----------------------|
  # | `id` | The UUID of a Flight. |

  def show
    respond_with @flight
  end

  private

  def find_flight
    @flight = Flight.with_passenger_count.find_by!(uuid: params[:id])
  end

  def authorized_flight?
    pilot_signed_in? && @flight.pilot == current_pilot
  end
end
