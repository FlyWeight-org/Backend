# frozen_string_literal: true

require "rails_helper"
require "webauthn/fake_client"

RSpec.describe "Passkeys" do
  describe "passkey ceremonies" do
    let(:password) { Faker::Internet.password }
    let(:pilot) { create(:pilot, password:) }
    let(:client) { WebAuthn::FakeClient.new(Rails.application.config.urls.frontend) }

    def bearer(jwt) = {"Authorization" => "Bearer #{jwt}"}

    def jwt_payload(jwt)
      JWT.decode(jwt, Rails.application.credentials.jwt_secret, true, algorithm: "HS256").first
    end

    # Requests a ceremony's options, returning them with the JWT that binds
    # their challenge to the requesting session.
    def ceremony_options(path, headers: {})
      post(path, headers:, as: :json)
      [response.parsed_body, response.headers["Authorization"]]
    end

    def base64url(bytes) = Base64.urlsafe_encode64(bytes, padding: false)

    # Adds the fields a browser's PublicKeyCredential#toJSON reports alongside
    # the attestation, which carry a real registration past Rodauth's
    # parameter size cap.
    def browser_json(credential)
      auth_data = CBOR.decode(Base64.urlsafe_decode64(credential.dig("response", "attestationObject")))["authData"]
      public_key = WebAuthn::AuthenticatorData.deserialize(auth_data).credential.public_key_object
      browser_fields = {
          "authenticatorData"  => base64url(auth_data),
          "publicKey"          => base64url(public_key.public_to_der),
          "publicKeyAlgorithm" => COSE::Algorithm.by_name("ES256").id
      }
      credential.deep_merge("response" => browser_fields)
    end

    def log_in_with_password
      post "/login", params: {login: pilot.email, password:}, as: :json
      response.headers["Authorization"]
    end

    def register_passkey
      options, jwt = ceremony_options("/webauthn-setup", headers: bearer(log_in_with_password))
      challenge = options["webauthn_setup_challenge"]
      post "/webauthn-setup",
           headers: bearer(jwt),
           params:  {
               webauthn_setup:                browser_json(client.create(challenge:)),
               webauthn_setup_challenge:      challenge,
               webauthn_setup_challenge_hmac: options["webauthn_setup_challenge_hmac"],
               password:
           },
           as:      :json
      expect(response).to have_http_status(:success)
    end

    it "logs in with a passkey through the challenge's pre-login JWT" do
      register_passkey

      options, jwt = ceremony_options("/webauthn-login")
      expect(jwt_payload(jwt)).not_to include("account_id", "e")

      challenge = options["webauthn_auth_challenge"]
      post "/webauthn-login",
           headers: bearer(jwt),
           params:  {
               webauthn_auth:                client.get(challenge:),
               webauthn_auth_challenge:      challenge,
               webauthn_auth_challenge_hmac: options["webauthn_auth_challenge_hmac"]
           },
           as:      :json
      expect(response).to have_http_status(:success)
      expect(response.parsed_body["email"]).to eq(pilot.email)
      expect(jwt_payload(response.headers["Authorization"])).to include("account_id" => pilot.id, "e" => pilot.email)
    end

    it "refuses a passkey login naming a login, whether or not the account exists" do
      register_passkey

      refusals = [pilot.email, "nobody@example.com"].map do |login|
        post "/webauthn-login", params: {login:}, as: :json
        expect(response.headers["Authorization"]).to be_blank
        [response.status, response.parsed_body]
      end

      expect(refusals.uniq.size).to eq(1)
      expect(refusals.first.last).not_to include("webauthn_auth", "webauthn_auth_challenge_hmac")
    end
  end
end
