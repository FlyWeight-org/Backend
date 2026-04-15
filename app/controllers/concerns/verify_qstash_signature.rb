# frozen_string_literal: true

require "jwt"
require "base64"
require "openssl"

# Verifies the `Upstash-Signature` JWT on incoming QStash webhook requests.
# Supports both signing keys so Upstash can rotate without downtime.

module VerifyQstashSignature
  extend ActiveSupport::Concern

  SIGNATURE_HEADER = "Upstash-Signature"

  included do
    before_action :verify_qstash_signature!
    skip_before_action :verify_authenticity_token, raise: false
  end

  private

  def verify_qstash_signature!
    signature = request.headers[SIGNATURE_HEADER]
    return head(:unauthorized) if signature.blank?

    body        = request.raw_post
    current_key = ENV.fetch("QSTASH_CURRENT_SIGNING_KEY")
    next_key    = ENV.fetch("QSTASH_NEXT_SIGNING_KEY")

    return if valid_qstash_jwt?(signature, body, current_key)
    return if valid_qstash_jwt?(signature, body, next_key)

    head :unauthorized
  end

  def valid_qstash_jwt?(token, body, secret)
    payload, _header = JWT.decode(
      token, secret, true,
      {algorithm: "HS256", verify_iat: true, verify_expiration: true}
    )

    digest = OpenSSL::Digest::SHA256.digest(body)
    # QStash sends the body hash base64url-encoded; tolerate either padded or
    # unpadded form.
    received = payload["body"].to_s.sub(/=+\z/, "")
    expected = Base64.urlsafe_encode64(digest, padding: false)

    received == expected && payload["iss"] == "Upstash"
  rescue JWT::DecodeError, KeyError
    false
  end
end
