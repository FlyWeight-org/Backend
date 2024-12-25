# frozen_string_literal: true

# RESTful controller for working with {Load}s. This controller is used by
# passengers (unauthenticated sessions). Pilots can create and edit loads using
# {Pilot::LoadsController}.

class LoadsController < ApplicationController
  before_action :find_flight

  # Creates a passenger or cargo load from the given parameters. If the given
  # name matches an existing Load for the {Flight} by the derived slug, the
  # existing load will be overwritten.
  #
  # Routes
  # ------
  #
  # * `POST /flights/:flight_id/loads.json`
  #
  # Path Parameters
  # ---------------
  #
  # |             |                       |
  # |:------------|:----------------------|
  # | `flight_id` | The UUID of a Flight. |
  #
  # Body Parameters
  # ---------------
  #
  # |        |                                        |
  # |:-------|:---------------------------------------|
  # | `load` | Parameterized hash of Load attributes. |

  def create
    @load = @flight.loads.with_name(load_params[:name])
    @load.update load_params
    respond_with @flight, @load, location: flight_url(@flight)
  end

  private

  def find_flight
    @flight = Flight.find_by!(uuid: params[:flight_id])
  end

  def load_params
    params.expect load: %i[name weight bags_weight
                           covid19_vaccination]
  end
end
