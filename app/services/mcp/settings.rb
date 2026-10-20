# frozen_string_literal: true

module Mcp
  # Canonical addresses and permissions for the hosted assistant integration.
  module Settings
    READ_SCOPE = "flights:read"
    WRITE_SCOPE = "flights:write"
    SCOPES = [READ_SCOPE, WRITE_SCOPE].freeze

    # @return [Boolean] Whether hosted assistant connections are available.
    def self.enabled? = Rails.application.config.x.mcp_enabled

    # @return [String] The OAuth issuer URL.
    def self.issuer = Rails.application.config.urls.backend

    # @return [String] The sole resource accepted by assistant access tokens.
    def self.resource = "#{issuer}/mcp"

    # @return [String] The resource's RFC 9728 protected resource metadata document.
    def self.resource_metadata_url = "#{issuer}/.well-known/oauth-protected-resource/mcp"
  end
end
