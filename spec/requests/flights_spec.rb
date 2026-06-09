# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/flights" do
  let(:pilot) { create :pilot }

  let(:flight) do
    create(:flight, pilot:).
        tap { |flight| create_list :load, 3, :passenger, flight: }
  end
  let(:other_flight) { create :flight }

  let(:flight_params) { attributes_for :flight }

  let(:collection_path) { "/flights.json" }
  let(:record_path) { "/flights/#{flight.to_param}.json" }

  describe "GET /:id" do
    context "[unauthenticated]" do
      it "returns 404 if the flight is not found" do
        get "/flights/not-found.json"
        expect(response).to have_http_status(:not_found)
      end

      it "returns a flight with limited data" do
        get record_path

        expect(response).to be_successful
        expect(response.body).to match_json(
                                   uuid:        String,
                                   date:        String,
                                   description: String,
                                   can_edit:    false,
                                   pilot:       {
                                       name:        String,
                                       weight_unit: String,
                                       locale:      nil
                                   }
                                 )
      end
    end

    context "[unauthorized]" do
      before(:each) { sign_in create(:pilot) }

      it "returns a flight with limited data" do
        get record_path

        expect(response).to be_successful
        expect(response.body).to match_json(
                                   uuid:        String,
                                   date:        String,
                                   description: String,
                                   can_edit:    false,
                                   pilot:       {
                                       name:        String,
                                       weight_unit: String,
                                       locale:      nil
                                   }
                                 )
      end
    end

    context "[authenticated]" do
      before(:each) { sign_in pilot }

      it "returns a flight with full data" do
        get record_path

        expect(response).to be_successful
        expect(response.body).to match_json(
                                   uuid:        String,
                                   date:        String,
                                   description: String,
                                   can_edit:    true,
                                   pilot:       {
                                       name:        String,
                                       weight_unit: String,
                                       locale:      nil
                                   },
                                   loads:       [{
                                       slug:        String,
                                       name:        String,
                                       weight:      Numeric,
                                       bags_weight: Numeric
                                   }] * 3
                                 )
      end

      it "serializes decimal load weights as JSON numbers" do
        load = flight.loads.first
        load.update! weight: 154.32, bags_weight: 12.5

        get record_path

        expect(response).to be_successful
        body = response.parsed_body
        serialized = body["loads"].find { |l| l["slug"] == load.slug }
        expect(serialized["weight"]).to eq(154.32)
        expect(serialized["weight"]).to be_a(Numeric)
        expect(serialized["bags_weight"]).to eq(12.5)
      end
    end
  end
end
