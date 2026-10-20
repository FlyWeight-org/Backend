# frozen_string_literal: true

module Mcp
  # Canonical addresses and permissions for the hosted assistant integration.
  module Settings
    SCOPES = %w[flights:read flights:write].freeze

    # @return [Boolean] Whether hosted assistant connections are available.
    def self.enabled? = Rails.application.config.x.mcp_enabled

    # @return [String] The OAuth issuer URL.
    def self.issuer = Rails.application.config.urls.backend

    # @return [String] The sole resource accepted by assistant access tokens.
    def self.resource = "#{issuer}/mcp"
  end
end
