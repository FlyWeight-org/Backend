# frozen_string_literal: true

# RESTful controller for working with {Load}s. This controller is used by pilots
# (authenticated sessions); passengers create loads using {LoadsController}.

class Pilot::LoadsController < ApplicationController
  before_action :authenticate_pilot!
  before_action :find_flight
  before_action :find_load, only: :destroy

  # Creates a Load with the given parameters. If the given name matches an
  # existing Load by the derived slug, that Load will be updated instead.
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

  # Deletes a Load.
  #
  # Routes
  # ------
  #
  # * `DELETE /flights/:flight_id/loads/:id.json`
  #
  # Path Parameters
  # ---------------
  #
  # |             |                       |
  # |:------------|:----------------------|
  # | `flight_id` | The UUID of a Flight. |
  # | `id`        | The name of a Load.   |

  def destroy
    @load.destroy
    respond_with @flight, @load
  end

  private

  def find_flight
    @flight = current_pilot.flights.find_by!(uuid: params[:flight_id])
  end

  def find_load
    @load = @flight.loads.find_by!(slug: params[:id])
  end

  def load_params
    params.require(:load).permit :name, :weight, :bags_weight,
                                 :covid19_vaccination
  end
end
