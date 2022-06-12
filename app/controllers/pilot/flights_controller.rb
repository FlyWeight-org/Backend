# frozen_string_literal: true

# RESTful controller for working with {Flight}s. This controller is used by
# pilots (authenticated sessions). Passengers view flights using
# {FlightsController}.

class Pilot::FlightsController < ApplicationController
  before_action :authenticate_pilot!
  before_action :find_flight, only: %i[update destroy]

  # Displays a list of a pilot's Flights.
  #
  # Routes
  # ------
  #
  # * `GET /pilot/flights.json`

  def index
    @flights = current_pilot.flights.with_passenger_count.order(date: :desc)
    respond_with @flights
  end

  # Creates a new Flight for a pilot from the given parameters.
  #
  # Routes
  # ------
  #
  # * `POST /pilot/flights.json`
  #
  # Body Parameters
  # ---------------
  #
  # |           |                                          |
  # |:----------|:-----------------------------------------|
  # | `:flight` | Parameterized hash of Flight attributes. |

  def create
    @flight = current_pilot.flights.create(flight_params)
    respond_with @flight
  end

  # Updates a Flight using the given parameters.
  #
  # Routes
  # ------
  #
  # * `POST /pilot/flights/:id.json`
  #
  # Path Parameters
  # ---------------
  #
  # |      |                       |
  # |:-----|:----------------------|
  # | `id` | The UUID of a Flight. |
  #
  # Body Parameters
  # ---------------
  #
  # |           |                                          |
  # |:----------|:-----------------------------------------|
  # | `:flight` | Parameterized hash of Flight attributes. |

  def update
    @flight.update flight_params
    respond_with @flight
  end

  # Removes a Flight.
  #
  # Routes
  # ------
  #
  # * `DELETE /pilot/flights/:id.json`
  #
  # Path Parameters
  # ---------------
  #
  # |      |                       |
  # |:-----|:----------------------|
  # | `id` | The UUID of a Flight. |

  def destroy
    @flight.destroy
    respond_with @flight
  end

  private

  def find_flight
    @flight = current_pilot.flights.with_passenger_count.find_by!(uuid: params[:id])
  end

  def flight_params = params.require(:flight).permit :date, :description
end
