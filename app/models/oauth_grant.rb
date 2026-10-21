# frozen_string_literal: true

# A pilot's revocable authorization for one assistant client.
class OauthGrant < ApplicationRecord
  self.inheritance_column = nil

  belongs_to :account, class_name: "Pilot"
  belongs_to :oauth_application

  scope :unrevoked, -> { where(revoked_at: nil) }

  # Exchanged grants whose refresh token can still be used.
  scope :live, -> { unrevoked.where.not(token: nil).where(expires_in: refresh_cutoff..) }

  # Grants no client can use again: revoked, past their refresh window, or codes never exchanged in time.
  scope :stale, -> {
    where.not(revoked_at: nil).or(where(expires_in: ...refresh_cutoff)).or(where(token: nil, expires_in: ...Time.current))
  }

  # A grant's `expires_in` tracks its access token, and its refresh token outlives that by the difference in lifetimes.
  # @return [ActiveSupport::TimeWithZone] The oldest access-token expiry whose refresh token is still valid.
  def self.refresh_cutoff = (Mcp::OauthConfiguration::REFRESH_TOKEN_LIFETIME - Mcp::OauthConfiguration::ACCESS_TOKEN_LIFETIME).ago

  # Resolves the request's bearer token to a grant for the MCP resource and an open account.
  # @param rodauth [Rodauth::Auth] The request's authentication, which verifies the token.
  # @return [OauthGrant, nil] An active grant, or nil when authorization fails.
  def self.authenticate(rodauth)
    token = rodauth.authorization_token
    return unless token && token[:resource] == Mcp::Settings.resource

    joins(:account).find_by(id: token[:id], pilots: {rodauth.account_status_column => rodauth.account_open_status_value})
  end

  # @return [Array<String>] The permissions approved by the pilot.
  def permissions = scopes.split
end
