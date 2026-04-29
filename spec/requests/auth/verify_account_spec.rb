# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/verify-account" do
  let(:email) { "verify@example.com" }
  let(:password) { "hunter22!" }

  def signup
    post "/signup",
         params: {login: email, password:, name: "Verify Me"},
         as:     :json
  end

  def verification_keys
    ActiveRecord::Base.connection.select_all("SELECT * FROM account_verification_keys")
  end

  def token_from_last_email
    body = ActionMailer::Base.deliveries.last.body.decoded
    body.match(/key=([^\s]+)/)[1]
  end

  describe "POST /signup" do
    it "creates an unverified pilot and a verification key, with no JWT in the response" do
      expect { signup }.to change(Pilot, :count).by(1).
          and change { verification_keys.count }.by(1)

      expect(response).to have_http_status(:success)
      pilot = Pilot.find_by!(email: email)
      expect(pilot.status_id).to eq(1)

      expect(response.headers["Authorization"]).to be_blank
      expect(response.headers["Refresh-Token"]).to be_blank
      body = response.parsed_body
      expect(body["access_token"]).to be_blank
      expect(body["refresh_token"]).to be_blank

      mail = ActionMailer::Base.deliveries.last
      expect(mail).to be_present
      expect(mail.subject).to eq("Verify your FlyWeight account")
      expect(mail.body.decoded).to include("/verify-account?key=")
    end
  end

  describe "POST /login (unverified)" do
    it "rejects the login with the Rodauth unverified-account error" do
      signup
      pilot = Pilot.find_by!(email: email)
      expect(pilot.status_id).to eq(1)

      post "/login",
           params: {login: email, password:},
           as:     :json
      expect(response).to have_http_status(:forbidden)
      body = response.parsed_body
      expect(body["error"]).to be_present
      expect(response.headers["Authorization"]).to be_blank
    end
  end

  describe "POST /verify-account" do
    let(:pilot) { Pilot.find_by!(email: email) }

    before { signup }

    it "verifies the account and removes the verification key" do
      post "/verify-account", params: {key: token_from_last_email}, as: :json

      expect(response).to have_http_status(:success)
      expect(pilot.reload.status_id).to eq(2)
      expect(verification_keys.count).to eq(0)
    end

    it "rejects an invalid key" do
      post "/verify-account", params: {key: "bogus"}, as: :json
      expect(response).to have_http_status(:unauthorized)
      expect(pilot.reload.status_id).to eq(1)
    end

    it "allows login after verification with a JWT" do
      post "/verify-account", params: {key: token_from_last_email}, as: :json
      expect(response).to have_http_status(:success)

      post "/login", params: {login: email, password:}, as: :json
      expect(response).to have_http_status(:success)
      body = response.parsed_body
      expect(body["access_token"]).to be_present
      expect(body["refresh_token"]).to be_present
      expect(response.headers["Authorization"]).to be_present
    end
  end
end
