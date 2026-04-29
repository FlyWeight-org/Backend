# frozen_string_literal: true

require "rails_helper"

RSpec.describe "POST /signup with Turnstile" do
  let(:params) { {login: "tsig@example.com", password: "securepass", name: "Tee", turnstile_token: "tok"} }

  context "when Turnstile verification succeeds" do
    before do
      allow(TurnstileVerifier).to receive(:verify).
        and_return(TurnstileVerifier::Result.new(success?: true, error_codes: []))
      # Force the rodauth hook out of test-bypass mode for this example.
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("cypress"))
    end

    it "creates the account" do
      post "/signup", params: params, as: :json
      expect(response).to have_http_status(:success)
      expect(TurnstileVerifier).to have_received(:verify).with("tok", anything)
    end
  end

  context "when Turnstile verification fails" do
    before do
      allow(TurnstileVerifier).to receive(:verify).
        and_return(TurnstileVerifier::Result.new(success?: false, error_codes: ["invalid-input-response"]))
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("cypress"))
    end

    it "returns 400 and does not create the account" do
      expect {
        post "/signup", params: params, as: :json
      }.not_to change(Pilot, :count)
      expect(response).to have_http_status(:bad_request)
      body = response.parsed_body
      expect(body["error"] || body["field-error"]).to be_present
    end
  end
end
