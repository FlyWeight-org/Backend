# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/pilot/flights/:flight_id/loads" do
  let(:pilot) { create :pilot }

  let(:flight) { create :flight, pilot: }
  let(:other_flight) { create :flight, pilot: }
  let(:other_pilot_flight) { create :flight }

  let(:load) { create :load, :passenger, flight: }
  let(:load_params) { attributes_for :load, :passenger }

  let(:collection_path) { "/pilot/flights/#{flight.to_param}/loads.json" }
  let(:record_path) { "/pilot/flights/#{flight.to_param}/loads/#{load.to_param}.json" }

  describe "POST /pilot/flights/:flight_id/loads" do
    it "requires a logged-in pilot" do
      delete record_path
      expect(response).to have_http_status(:unauthorized)
    end

    context "[authenticated]" do
      before(:each) { sign_in pilot }

      it "returns 404 when given an unknown flight" do
        post "/pilot/flights/not-found/loads.json",
             params: {load: load_params}
        expect(response).to have_http_status(:not_found)
      end

      it "creates the load" do
        post collection_path,
             params: {load: load_params}
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
                                       slug:        String,
                                       name:        String,
                                       weight:      Integer,
                                       bags_weight: Integer
                                   }]
                                 )

        expect(flight.loads.count).to eq(1)
      end

      it "overwrites an existing load of the same name" do
        create :load, flight:, name: "Existing load", weight: 100

        post collection_path,
             params: {load: {name: "existing load", weight: 200}}
        expect(response).to be_successful

        expect(flight.loads.count).to eq(1)
        expect(flight.loads.first.name).to eq("existing load")
        expect(flight.loads.first.weight).to eq(200)
      end
    end
  end

  describe "DELETE /flights/:flight_id/loads/:id" do
    it "requires a logged-in pilot" do
      delete record_path
      expect(response).to have_http_status(:unauthorized)
    end

    context "[authenticated]" do
      before(:each) { sign_in pilot }

      it "returns 404 when given an unknown flight" do
        delete "/pilot/flights/not-found/loads/#{load.to_param}.json"
        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 when given an unknown load" do
        delete "/pilot/flights/#{flight.to_param}/loads/not-found.json"
        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 when given another pilot's flight" do
        delete "/pilot/flights/#{create(:flight).to_param}/loads/#{load.to_param}.json"
        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 when given another load's flight" do
        delete "/pilot/flights/#{create(:flight, pilot:).to_param}/loads/#{load.to_param}.json"
        expect(response).to have_http_status(:not_found)
      end

      it "deletes the load" do
        delete record_path
        expect(response).to be_successful
        expect(response.body).to match_json_expression(
                                   uuid:        String,
                                   date:        String,
                                   description: String,
                                   can_edit:    true,
                                   pilot:       {
                                       name: String
                                   },
                                   loads:       []
                                 )

        expect { load.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
