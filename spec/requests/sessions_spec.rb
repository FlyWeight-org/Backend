# frozen_string_literal: true

require "rails_helper"

RSpec.describe "sessions" do
  let(:password) { FFaker::Internet.password }
  let(:pilot) { create :pilot, password: }
  let(:email) { pilot.email }

  describe "POST /login" do
    it "returns pilot data and tokens on success" do
      post "/login",
           params: {login: email, password:},
           as:     :json
      expect(response).to have_http_status(:success)
      body = response.parsed_body
      expect(body["name"]).to eq(pilot.name)
      expect(body["email"]).to eq(pilot.email)
      expect(body["passkeys"]).to eq([])
      expect(body["access_token"]).to be_present
      expect(body["refresh_token"]).to be_present
      expect(response.headers["Authorization"]).to be_present
    end

    it "returns an error if the email does not exist" do
      post "/login",
           params: {login: "wrong@example.com", password:},
           as:     :json
      expect(response).to have_http_status(:unauthorized)
      body = response.parsed_body
      expect(body["error"]).to be_present
    end

    it "returns an error if the password is incorrect" do
      post "/login",
           params: {login: email, password: "wrong"},
           as:     :json
      expect(response).to have_http_status(:unauthorized)
      body = response.parsed_body
      expect(body["error"]).to be_present
    end
  end

  describe "POST /logout" do
    it "returns success when authenticated" do
      post "/logout",
           headers: {"Authorization" => "Bearer #{jwt_for(pilot)}"},
           as:      :json
      expect(response).to have_http_status(:success)
    end
  end
end
