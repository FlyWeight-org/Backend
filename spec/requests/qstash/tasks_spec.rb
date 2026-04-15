# frozen_string_literal: true

require "rails_helper"
require "jwt"
require "base64"
require "openssl"

RSpec.describe "/qstash/tasks" do
  let(:current_key) { "test-current-signing-key" }
  let(:next_key)    { "test-next-signing-key" }

  around :each do |example|
    prev_current                      = ENV.fetch("QSTASH_CURRENT_SIGNING_KEY", nil)
    prev_next                         = ENV.fetch("QSTASH_NEXT_SIGNING_KEY", nil)
    ENV["QSTASH_CURRENT_SIGNING_KEY"] = current_key
    ENV["QSTASH_NEXT_SIGNING_KEY"]    = next_key
    example.run
  ensure
    ENV["QSTASH_CURRENT_SIGNING_KEY"] = prev_current
    ENV["QSTASH_NEXT_SIGNING_KEY"]    = prev_next
  end

  def sign(body, key, padded: true)
    body_hash = Base64.urlsafe_encode64(
      OpenSSL::Digest::SHA256.digest(body), padding: padded
    )
    JWT.encode(
      {iss: "Upstash", iat: Time.now.to_i, exp: Time.now.to_i + 60, body: body_hash},
      key, "HS256"
    )
  end

  describe "POST /qstash/purge_stale_flights" do
    let(:path) { "/qstash/purge_stale_flights" }
    let(:body) { "{}" }

    it "returns 401 when Upstash-Signature is missing" do
      post path, params: body, headers: {"Content-Type" => "application/json"}
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 when the body has been tampered with" do
      signature = sign("{}", current_key)
      post path,
           params:  '{"tampered":true}',
           headers: {"Content-Type" => "application/json", "Upstash-Signature" => signature}
      expect(response).to have_http_status(:unauthorized)
    end

    it "returns 401 when signed with an unknown key" do
      signature = sign(body, "wrong-key")
      post path,
           params:  body,
           headers: {"Content-Type" => "application/json", "Upstash-Signature" => signature}
      expect(response).to have_http_status(:unauthorized)
    end

    it "accepts a request signed with the next (rotation) key" do
      signature = sign(body, next_key)
      post path,
           params:  body,
           headers: {"Content-Type" => "application/json", "Upstash-Signature" => signature}
      expect(response).to have_http_status(:no_content)
    end

    it "accepts a body hash encoded without base64 padding" do
      signature = sign(body, current_key, padded: false)
      post path,
           params:  body,
           headers: {"Content-Type" => "application/json", "Upstash-Signature" => signature}
      expect(response).to have_http_status(:no_content)
    end

    it "deletes only flights whose date is more than one week in the past" do
      stale  = create :flight, date: 8.days.ago
      recent = create :flight, date: 6.days.ago
      future = create :flight, date: 3.days.from_now

      signature = sign(body, current_key)
      post path,
           params:  body,
           headers: {"Content-Type" => "application/json", "Upstash-Signature" => signature}

      expect(response).to have_http_status(:no_content)
      expect { stale.reload  }.to raise_error(ActiveRecord::RecordNotFound)
      expect { recent.reload }.not_to raise_error
      expect { future.reload }.not_to raise_error
    end
  end
end
