# frozen_string_literal: true

# Responds to requests by resetting the Cypress test environment. The reset test
# environment consists of:
#
# * a Pilot (`cypress@example.com`),
# * a Flight,
# * and two Loads (one passenger and one cargo).
#
# The response to the request will be the UUID of the Flight.
#
# This middleware must be mounted at a specific route, not added to the
# middleware chain.

class Cypress::Reset
  def call(_env)
    reset_cypress
    pilot = create_pilot
    flight = create_flight(pilot)
    return response(flight)
  end

  private

  def reset_cypress
    models.each { |model| truncate model }
    ActionMailer::Base.deliveries.clear
  end

  def response(flight)
    [200, {"Content-Type" => "text/plain"}, [flight.uuid]]
  end

  def models
    [Flight, Load, Pilot]
  end

  def truncate(model)
    model.connection.execute "TRUNCATE #{model.quoted_table_name} CASCADE"
  end

  def create_pilot
    Pilot.create! email:    "cypress@example.com",
                  password: "supersecret",
                  name:     "Cypress User"
  end

  def create_flight(pilot)
    flight = pilot.flights.create!(date: 2.days.from_now, description: "Example Flight")

    flight.loads.create! name:                "Example Passenger",
                         weight:              150,
                         bags_weight:         10,
                         covid19_vaccination: true

    flight.loads.create! name:        "Example Cargo",
                         bags_weight: 25

    return flight
  end
end
