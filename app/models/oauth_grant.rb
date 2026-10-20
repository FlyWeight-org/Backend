# frozen_string_literal: true

# A pilot's revocable authorization for one assistant client.
class OauthGrant < ApplicationRecord
  self.inheritance_column = nil

  belongs_to :account, class_name: "Pilot"
  belongs_to :oauth_application

  scope :unrevoked, -> { where(revoked_at: nil) }

  # Resolves a hashed bearer token for the MCP resource and an open account.
  # @param token [String] The bearer token presented by the client.
  # @return [OauthGrant, nil] An active grant, or nil when authorization fails.
  def self.authenticate(token)
    return if token.blank?

    digest = Base64.urlsafe_encode64(Digest::SHA256.digest(token))
    unrevoked.joins(:account).where(pilots: {status_id: 2}, token: digest, resource: Mcp::Settings.resource).
        where(expires_in: Time.current..).first
  end

  # @return [Array<String>] The permissions approved by the pilot.
  def permissions = scopes.split
end
