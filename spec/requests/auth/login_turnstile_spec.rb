# frozen_string_literal: true

require "rails_helper"

RSpec.describe "POST /login with Turnstile" do
  let(:password) { FFaker::Internet.password }
  let(:pilot) { create :pilot, password: }

  context "when Turnstile verification succeeds" do
    before do
      allow(TurnstileVerifier).to receive(:verify).
        and_return(TurnstileVerifier::Result.new(success?: true, error_codes: []))
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("cypress"))
    end

    it "logs the user in" do
      post "/login", params: {login: pilot.email, password:, turnstile_token: "tok"}, as: :json
      expect(response).to have_http_status(:success)
      expect(response.parsed_body["access_token"]).to be_present
      expect(TurnstileVerifier).to have_received(:verify).with("tok", anything)
    end
  end

  context "when Turnstile verification fails" do
    before do
      allow(TurnstileVerifier).to receive(:verify).
        and_return(TurnstileVerifier::Result.new(success?: false, error_codes: ["invalid-input-response"]))
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("cypress"))
    end

    it "returns 400 and does not issue a token" do
      post "/login", params: {login: pilot.email, password:, turnstile_token: "bad"}, as: :json
      expect(response).to have_http_status(:bad_request)
      expect(response.parsed_body["access_token"]).to be_blank
    end
  end
end
