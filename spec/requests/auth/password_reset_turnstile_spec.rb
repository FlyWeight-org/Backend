# frozen_string_literal: true

require "rails_helper"

RSpec.describe "POST /password-resets with Turnstile" do
  let(:pilot) { create :pilot }

  context "when Turnstile verification succeeds" do
    before do
      allow(TurnstileVerifier).to receive(:verify).
        and_return(TurnstileVerifier::Result.new(success?: true, error_codes: []))
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("cypress"))
    end

    it "sends a password-reset email" do
      post "/password-resets", params: {login: pilot.email, turnstile_token: "tok"}, as: :json
      expect(response).to have_http_status(:no_content)
      expect(ActionMailer::Base.deliveries.last).to be_present
      expect(TurnstileVerifier).to have_received(:verify).with("tok", anything)
    end
  end

  context "when Turnstile verification fails" do
    before do
      allow(TurnstileVerifier).to receive(:verify).
        and_return(TurnstileVerifier::Result.new(success?: false, error_codes: ["invalid-input-response"]))
      allow(Rails).to receive(:env).and_return(ActiveSupport::StringInquirer.new("cypress"))
    end

    it "returns 400 and does not send an email" do
      ActionMailer::Base.deliveries.clear
      post "/password-resets", params: {login: pilot.email, turnstile_token: "bad"}, as: :json
      expect(response).to have_http_status(:bad_request)
      expect(ActionMailer::Base.deliveries).to be_empty
    end
  end
end
