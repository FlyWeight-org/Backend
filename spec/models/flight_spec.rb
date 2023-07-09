# frozen_string_literal: true

require "rails_helper"

RSpec.describe Flight do
  context "[hooks]" do
    let(:flight) { build :flight }

    it "assigns the UUID" do
      flight.validate
      expect(flight.uuid).to be_present
    end

    it "schedules a purge" do
      flight.save

      expect(PurgeFlightJob).to have_been_enqueued.with(flight).at(flight.date.to_time + 1.week)
    end
  end

  context "[scopes]" do
    describe "with_passenger_count" do
      before :each do
        create :flight, description: "no-pax"
        flight = create(:flight, description: "pax")
        create_list(:load, 3, :passenger, flight:)
        create_list :load, 3, :cargo, flight:
      end

      it "includes the passenger count" do
        flights = described_class.with_passenger_count.to_a
        with_pax = flights.detect { _1.description == "pax" }
        no_pax = flights.detect { _1.description == "no-pax" }

        expect(with_pax.passenger_count).to eq(3)
        expect(no_pax.passenger_count).to eq(0)
      end
    end
  end
end
