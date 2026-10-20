# frozen_string_literal: true

# A pilot's revocable authorization for one assistant client.
class OauthGrant < ApplicationRecord
  self.inheritance_column = nil

  belongs_to :account, class_name: "Pilot"
  belongs_to :oauth_application

  scope :unrevoked, -> { where(revoked_at: nil) }

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
