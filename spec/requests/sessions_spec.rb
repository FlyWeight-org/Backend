# frozen_string_literal: true

require "rails_helper"

RSpec.describe "sessions" do
  let(:password) { FFaker::Internet.password }
  let(:pilot) { create :pilot, password: }
  let(:email) { pilot.email }

  describe "POST /login" do
    it "returns a 200 OK if the credentials are correct" do
      post "/login.json",
           params: {pilot: {email:, password:}}
      expect(response).to have_http_status(:success)
    end

    it "returns an error if the email does not exist" do
      post "/login.json",
           params: {pilot: {email: "wrong", password:}}
      expect(response).to have_http_status(:unauthorized)
      expect(response.headers["Authorization"]).not_to be_present
      expect(response.body).to match_json_expression(error: String)
    end

    it "returns an error if the password is incorrect" do
      post "/login.json",
           params: {pilot: {email:, password: "wrong"}}
      expect(response).to have_http_status(:unauthorized)
      expect(response.headers["Authorization"]).not_to be_present
      expect(response.body).to match_json_expression(error: String)
    end
  end

  describe "DELETE /logout" do
    it "returns a 200 OK" do
      delete "/logout.json", headers: Devise::JWT::TestHelpers.auth_headers({}, pilot)
      expect(response).to have_http_status(:no_content)
    end

    it "does nothing if no JWT is present" do
      expect { delete "/logout.json" }.not_to change(Denylist, :count)
      expect(response).to have_http_status(:no_content)
    end
  end
end
