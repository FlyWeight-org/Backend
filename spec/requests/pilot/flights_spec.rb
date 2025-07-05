# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/pilot/flights" do
  let(:pilot) { create :pilot }

  let(:flight) do
    create(:flight, pilot:).
        tap { |flight| create_list :load, 3, :passenger, flight: }
  end
  let(:other_flight) { create :flight }

  let(:flight_params) { attributes_for :flight }

  let(:collection_path) { "/pilot/flights.json" }
  let(:record_path) { "/pilot/flights/#{flight.to_param}.json" }

  describe "GET /" do
    before :each do
      @flights = create_list :flight, 10, pilot:
    end

    it "requires a logged-in pilot" do
      get collection_path
      expect(response).to have_http_status(:unauthorized)
    end

    context "[authenticated]" do
      before(:each) { sign_in pilot }

      it "returns a list of flights" do
        get collection_path

        expect(response).to be_successful
        expect(response.body).
            to match_json_expression([{
                uuid:            String,
                date:            String,
                description:     String,
                passenger_count: Integer
            }] * 10)
      end
    end
  end

  describe "POST /" do
    it "requires a logged-in pilot" do
      post collection_path,
           params: {flight: flight_params}
      expect(response).to have_http_status(:unauthorized)
    end

    context "[authenticated]" do
      before(:each) { sign_in pilot }

      it "creates a flight" do
        post collection_path,
             params: {flight: flight_params}

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

        expect(pilot.flights.count).to eq(1)
      end

      it "handles validation errors" do
        post collection_path,
             params: {flight: flight_params.merge(date: " ")}

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to match_json_expression(errors: {date: [String]})
      end
    end
  end

  describe "PUT /:id" do
    it "requires a logged-in pilot" do
      put record_path,
          params: {flight: flight_params}
      expect(response).to have_http_status(:unauthorized)
    end

    context "[authenticated]" do
      before(:each) { sign_in pilot }

      it "returns 404 if the flight is not found" do
        put "/pilot/flights/not-found.json",
            params: {flight: flight_params}
        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 if the flight belongs to a different pilot" do
        put "/pilot/flights/#{other_flight.to_param}.json",
            params: {flight: flight_params}
        expect(response).to have_http_status(:not_found)
      end

      it "updates the flight" do
        put record_path,
            params: {flight: flight_params}

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
                                   }] * 3
                                 )

        expect(flight.reload.description).to eql(flight_params[:description])
      end

      it "handles validation errors" do
        post collection_path,
             params: {flight: flight_params.merge(date: " ")}

        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to match_json_expression(errors: {date: [String]})
      end
    end
  end

  describe "DELETE /:id" do
    it "requires a logged-in pilot" do
      delete record_path
      expect(response).to have_http_status(:unauthorized)
    end

    context "[authenticated]" do
      before(:each) { sign_in pilot }

      it "returns 404 if the flight is not found" do
        delete "/pilot/flights/not-found.json"
        expect(response).to have_http_status(:not_found)
      end

      it "returns 404 if the flight belongs to a different pilot" do
        delete "/pilot/flights/#{other_flight.to_param}.json"
        expect(response).to have_http_status(:not_found)
      end

      it "deletes a flight" do
        delete record_path

        expect(response).to be_successful
        expect { flight.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
