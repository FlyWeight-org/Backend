# frozen_string_literal: true

module Mcp
  # Configures Rodauth's OAuth provider alongside browser JWT authentication.
  module OauthConfiguration
    # @param configuration [Rodauth::Configuration] The application's authentication configuration.
    def self.apply(configuration)
      configuration.instance_eval do
        enable :oauth_authorization_code_grant, :oauth_pkce, :oauth_resource_indicators,
               :oauth_dynamic_client_registration, :oauth_token_revocation
        authorize_route "oauth/authorize"
        token_route "oauth/token"
        register_route "oauth/register"
        revoke_route "oauth/revoke"
        oauth_valid_uri_schemes %w[https http]
        oauth_application_scopes Settings::SCOPES
        oauth_token_endpoint_auth_methods_supported %w[none client_secret_basic client_secret_post]
        oauth_access_token_expires_in 15.minutes.to_i
        oauth_refresh_token_expires_in 30.days.to_i
        oauth_refresh_token_protection_policy "rotation"
        oauth_require_pkce true
        oauth_pkce_allow_plain_method false
        oauth_response_mode "query"
        oauth_response_modes_supported %w[query]
        authorization_server_url { Settings.issuer }
        before_register { nil }
        after_revoke { json_response_success({}) }
        auth_class_eval { prepend OauthHooks }
      end
    end
  end
end
