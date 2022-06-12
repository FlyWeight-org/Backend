# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Account" do
  let(:current_password) { FFaker::Internet.password }
  let(:pilot) { create :pilot, password: current_password }
  let(:pilot_params) { attributes_for(:pilot).merge(current_password:) }

  describe "POST /signup" do
    let(:collection_path) { "/signup.json" }

    it "creates a pilot" do
      post collection_path,
           params: {pilot: pilot_params}
      expect(response).to have_http_status(:created)
      expect(response.body).to match_json_expression(
                                 name:  String,
                                 email: String
                               )
    end

    it "handles validation errors" do
      post collection_path,
           params: {pilot: pilot_params.merge(name: " ")}
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to match_json_expression(errors: {
                                                         name: [String]
                                                     })
    end
  end

  describe "GET /account" do
    let(:collection_path) { "/account.json" }

    it "requires an authenticated user" do
      get collection_path
      expect(response).to have_http_status(:unauthorized)
    end

    context "[authenticated]" do
      before(:each) { sign_in pilot }

      it "responds with pilot information" do
        get collection_path

        expect(response).to have_http_status(:success)
        expect(response.body).to match_json_expression({
                                                           name:  String,
                                                           email: String
                                                       })
      end
    end
  end

  describe "PUT /account" do
    let(:collection_path) { "/account.json" }

    it "requires an authenticated user" do
      put collection_path,
          params: {pilot: pilot_params}
      expect(response).to have_http_status(:unauthorized)
    end

    context "[authenticated]" do
      before(:each) { sign_in pilot }

      it "updates a pilot" do
        put collection_path,
            params: {pilot: pilot_params}
        expect(response).to have_http_status(:success)
        expect(response.body).to match_json_expression({
                                                           name:  String,
                                                           email: String
                                                       })
        expect(pilot.reload.email).to eq(pilot_params[:email])
      end

      it "handles validation errors" do
        put collection_path,
            params: {pilot: pilot_params.merge(email: " ")}
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to match_json_expression(errors: {
                                                           email: [String]
                                                       })
      end
    end
  end

  describe "DELETE /account" do
    let(:collection_path) { "/account.json" }

    it "requires an authenticated user" do
      delete collection_path
      expect(response).to have_http_status(:unauthorized)
    end

    context "[authenticated]" do
      before(:each) { sign_in pilot }

      it "deletes a pilot" do
        delete collection_path
        expect(response).to have_http_status(:no_content)
        expect { pilot.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
