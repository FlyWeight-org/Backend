# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Account" do
  let(:current_password) { FFaker::Internet.password }
  let(:pilot) { create :pilot, password: current_password }

  describe "POST /signup" do
    it "creates a pilot and returns tokens" do
      post "/signup",
           params: {login: "new@example.com", password: "securepass", name: "New Pilot"},
           as:     :json
      expect(response).to have_http_status(:success)
      body = response.parsed_body
      expect(body["name"]).to eq("New Pilot")
      expect(body["email"]).to eq("new@example.com")
      expect(body["passkeys"]).to eq([])
      expect(body["access_token"]).to be_present
      expect(body["refresh_token"]).to be_present
    end

    it "handles validation errors" do
      post "/signup",
           params: {login: "invalid", password: "securepass", name: "Test"},
           as:     :json
      expect(response).to have_http_status(:unprocessable_content)
      body = response.parsed_body
      expect(body["error"]).to be_present
    end
  end

  describe "GET /account" do
    it "requires an authenticated user" do
      get "/account", as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    context "[authenticated]" do
      before(:each) { sign_in pilot }

      it "responds with pilot information" do
        get "/account", as: :json

        expect(response).to have_http_status(:success)
        body = response.parsed_body
        expect(body["name"]).to eq(pilot.name)
        expect(body["email"]).to eq(pilot.email)
        expect(body["passkeys"]).to eq([])
      end
    end
  end

  describe "PUT /account" do
    it "requires an authenticated user" do
      put "/account",
          params: {pilot: {name: "Updated"}},
          as:     :json
      expect(response).to have_http_status(:unauthorized)
    end

    context "[authenticated]" do
      before(:each) { sign_in pilot }

      it "updates a pilot" do
        new_email = "updated@example.com"
        put "/account",
            params: {pilot: {name: "Updated Name", email: new_email}},
            as:     :json
        expect(response).to have_http_status(:success)
        body = response.parsed_body
        expect(body["name"]).to eq("Updated Name")
        expect(body["email"]).to eq(new_email)
        expect(pilot.reload.email).to eq(new_email)
      end

      it "handles validation errors" do
        put "/account",
            params: {pilot: {email: " "}},
            as:     :json
        expect(response).to have_http_status(:unprocessable_content)
        body = response.parsed_body
        expect(body["errors"]["email"]).to be_present
      end
    end
  end

  describe "DELETE /account" do
    it "requires an authenticated user" do
      delete "/account", as: :json
      expect(response).to have_http_status(:unauthorized)
    end

    context "[authenticated]" do
      before(:each) { sign_in pilot }

      it "deletes a pilot" do
        delete "/account", as: :json
        expect(response).to have_http_status(:no_content)
        expect { pilot.reload }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
