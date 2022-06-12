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
        expect(response.body).to match_json_expression(
                                   uuid:        String,
                                   date:        String,
                                   description: String,
                                   can_edit:    false,
                                   pilot:       {
                                       name: String
                                   }
                                 )
      end
    end

    context "[unauthorized]" do
      before(:each) { sign_in create(:pilot) }

      it "returns a flight with limited data" do
        get record_path

        expect(response).to be_successful
        expect(response.body).to match_json_expression(
                                   uuid:        String,
                                   date:        String,
                                   description: String,
                                   can_edit:    false,
                                   pilot:       {
                                       name: String
                                   }
                                 )
      end
    end

    context "[authenticated]" do
      before(:each) { sign_in pilot }

      it "returns a flight with full data" do
        get record_path

        expect(response).to be_successful
        expect(response.body).to match_json_expression(
                                   uuid:        String,
                                   date:        String,
                                   description: String,
                                   can_edit:    true,
                                   pilot:       {
                                       name: String
                                   },
                                   loads:       [{
                                       slug:                String,
                                       name:                String,
                                       weight:              Integer,
                                       bags_weight:         Integer,
                                       covid19_vaccination: false
                                   }] * 3
                                 )
      end
    end
  end
end
