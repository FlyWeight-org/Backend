# frozen_string_literal: true

# This job removes {Flight}s after they are more than a week old. The job itself
# does not check the age of the Flight; it merely deletes the Flight once
# executed.

class PurgeFlightJob < ApplicationJob
  queue_as :default

  # Removes a Flight.
  #
  # @param [Integer] id The ID of the Flight.

  def perform(id)
    flight = Flight.find_by(id:) or return
    flight.destroy
  end
end
