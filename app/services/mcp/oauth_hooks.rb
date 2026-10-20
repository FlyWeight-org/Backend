# frozen_string_literal: true

module Mcp
  # Adapts the provider's consent step to FlyWeight's authenticated Vue frontend.
  module OauthHooks
    # GET consent requests carry their parameters in the query string.
    # @return [Boolean] Whether to apply Rodauth's JSON-only POST processing.
    def json_request?
      (request.get? && request.path == authorize_path) ? false : super
    end

    REGISTRATION_FIELDS = %w[client_name redirect_uris token_endpoint_auth_method grant_types response_types scope].freeze
    # Seconds after a rotation during which replaying the consumed refresh token fails without revoking the grant.
    REFRESH_REUSE_GRACE = 30
    private_constant :REGISTRATION_FIELDS, :REFRESH_REUSE_GRACE

    private

    def validate_client_registration_params(params, *)
      callbacks = params["redirect_uris"]
      unless callbacks.kind_of?(Array) && callbacks.any? && callbacks.all? { |callback| safe_callback?(callback) }
        register_throw_json_response_error("invalid_redirect_uri", "A valid HTTPS or loopback callback is required")
      end
      super(params.slice(*REGISTRATION_FIELDS), *)
    end

    def safe_callback?(value)
      uri = URI.parse(value.to_s)
      uri.host.present? && !uri.userinfo && !uri.fragment &&
          (uri.scheme == "https" || (uri.scheme == "http" && %w[localhost 127.0.0.1 [::1]].include?(uri.host)))
    rescue URI::InvalidURIError
      false
    end

    def require_authorizable_account
      if request.get? && !logged_in?
        redirect "#{Rails.application.config.urls.frontend}/connect?#{request.query_string}"
      end
      require_login
      require_account_session
      authorization_required unless open_account?
    end

    def validate_authorize_params
      redirect_authorize_error("client_id") unless oauth_application
      callback = param("redirect_uri")
      unless safe_callback?(callback) && oauth_application[:redirect_uri].split.include?(callback)
        redirect_authorize_error("redirect_uri")
      end
      super
      redirect_response_error("invalid_target") unless resource_indicators == [Settings.resource]
      redirect_response_error("invalid_scope") unless scopes&.include?(Settings::READ_SCOPE)
    end

    def validate_token_params
      super
      redirect_response_error("invalid_target") unless resource_indicators == [Settings.resource]
    end

    def authorize_view
      json_response_success({
                                client_name: oauth_application[:name], client_id: oauth_application[:client_id],
          redirect_uri: redirect_uri, scopes: authorize_scopes,
          pilot: {name: account[:name], email: account[:email]}
                            })
    end

    def do_authorize(*)
      case param_or_nil("decision")
        when "allow" then super
        when "deny" then [{"error" => "access_denied", "state" => param("state")}, "query"]
        else redirect_response_error("invalid_request")
      end
    end

    def authorize_response(params, _mode)
      callback = URI(redirect_uri)
      callback.query = URI.encode_www_form(URI.decode_www_form(callback.query.to_s) + params.merge("iss" => Settings.issuer).to_a)
      json_response_success({redirect_uri: callback.to_s})
    end

    def oauth_server_metadata_body(*)
      super.merge(
        issuer: Settings.issuer, authorization_response_iss_parameter_supported: true,
        authorization_endpoint: "#{Settings.issuer}/oauth/authorize", token_endpoint: "#{Settings.issuer}/oauth/token",
        registration_endpoint: "#{Settings.issuer}/oauth/register", revocation_endpoint: "#{Settings.issuer}/oauth/revoke"
      )
    end

    def revoke_oauth_grant
      digest = generate_token_hash(param("token"))
      db[:oauth_grants].where(oauth_application_id: oauth_application[:id]).
          where(Sequel.|({token: digest}, {refresh_token: digest})).update(revoked_at: Sequel::CURRENT_TIMESTAMP)
    end

    def create_token(grant_type)
      return super unless grant_type == "refresh_token"

      digest = generate_token_hash(param("refresh_token"))
      uses = db[:oauth_refresh_token_uses]
      grant_id = db[:oauth_grants].where(refresh_token: digest).get(:id) || uses.where(token_hash: digest).get(:oauth_grant_id)
      grants = db[:oauth_grants].where(id: grant_id, oauth_application_id: oauth_application[:id])
      grant = grants.for_update.first
      return super unless grant

      if grant[:refresh_token] != digest
        grants.update(revoked_at: Sequel::CURRENT_TIMESTAMP) unless concurrent_refresh?(grant, digest)
        redirect_response_error("invalid_grant")
      end
      super.tap { uses.insert(oauth_grant_id: grant[:id], token_hash: digest) } # rubocop:disable Rails/SkipsModelValidations -- Sequel dataset shares the OAuth transaction.
    end

    # Whether the digest is the token consumed by the grant's latest rotation, within the grace period.
    def concurrent_refresh?(grant, digest)
      latest_consumed = db[:oauth_refresh_token_uses].where(oauth_grant_id: grant[:id]).reverse(:id).get(:token_hash)
      grace_ends = Sequel.date_add(:expires_in, seconds: REFRESH_REUSE_GRACE - oauth_access_token_expires_in)
      latest_consumed == digest && db[:oauth_grants].where(id: grant[:id]).where(grace_ends > Sequel::CURRENT_TIMESTAMP).any?
    end

    def create_token_from_authorization_code(grant_params, *, oauth_grant: nil)
      oauth_grant ||= valid_locked_oauth_grant(grant_params)
      require_open_grant_account(oauth_grant)
      super
    end

    def create_token_from_token(grant, update_params)
      require_open_grant_account(grant)
      super
    end

    def require_open_grant_account(grant)
      redirect_response_error("invalid_grant") unless _account_from_id(grant[:account_id], account_open_status_value)
    end
  end
end
