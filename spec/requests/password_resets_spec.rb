# frozen_string_literal: true

require "rails_helper"

RSpec.describe "/password_resets" do
  let(:pilot) { create :pilot }

  let(:collection_path) { "/password_resets.json" }

  describe "POST /" do
    it "generates a password-reset link" do
      post collection_path,
           params: {pilot: {email: pilot.email}}
      expect(response).to have_http_status(:no_content)
    end

    it "does nothing if the email does not exist" do
      post collection_path,
           params: {pilot: {email: "nonexistent@example.com"}}
      expect(response).to have_http_status(:no_content)
    end
  end

  describe "PUT /" do
    before(:each) do
      post collection_path,
           params: {pilot: {email: pilot.email}}
      body   = ActionMailer::Base.deliveries.first.body.decoded
      @token = body.match(%r{"http://test\.host/reset-password\?reset_password_token=(.+?)"})[1]
    end

    it "resets the password" do
      put collection_path,
          params: {
              pilot: {
                  reset_password_token:  @token,
                  password:              "newpass",
                  password_confirmation: "newpass"
              }
          }
      expect(response).to have_http_status(:no_content)
      expect { pilot.reload }.to change(pilot, :encrypted_password)
    end

    it "does not reset the password given an invalid token" do
      put collection_path,
          params: {
              pilot: {
                  reset_password_token:  @token,
                  password:              "newpass",
                  password_confirmation: "different"
              }
          }
      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to match_json_expression(errors: {
                                                         password_confirmation: [String]
                                                     })
      expect { pilot.reload }.not_to change(pilot, :encrypted_password)
    end
  end
end
