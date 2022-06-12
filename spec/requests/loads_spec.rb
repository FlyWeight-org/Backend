# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/flights/:flight_id/loads" do
  let(:pilot) { create :pilot }

  let(:flight) { create :flight, pilot: }
  let(:other_pilot_flight) { create :flight }

  let(:load_params) { attributes_for :load, :passenger }

  let(:collection_path) { "/flights/#{flight.to_param}/loads.json" }

  describe "POST /flights/:flight_id/loads" do
    it "returns 404 when given an unknown flight" do
      post "/flights/not-found/loads.json",
           params: {load: load_params}
      expect(response).to have_http_status(:not_found)
    end

    it "creates the load" do
      post collection_path,
           params: {load: load_params}
      expect(response).to be_successful
      expect(response.body).to match_json_expression(
                                 slug:                String,
                                 name:                String,
                                 weight:              Integer,
                                 bags_weight:         Integer,
                                 covid19_vaccination: Boolean
                               )

      expect(flight.loads.count).to eq(1)
    end

    it "overwrites an existing load of the same name" do
      create :load, name: "Existing load", weight: 100

      post collection_path,
           params: {load: {name: "existing load", weight: 200}}
      expect(response).to be_successful

      expect(flight.loads.count).to eq(1)
      expect(flight.loads.first.name).to eq("existing load")
      expect(flight.loads.first.weight).to eq(200)
    end
  end
end
