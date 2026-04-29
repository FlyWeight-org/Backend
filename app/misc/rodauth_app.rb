# frozen_string_literal: true

require "sequel/core"

class RodauthApp < Rodauth::Rails::App
  configure do
    # ── Database ──────────────────────────────────────────────────────────

    db Sequel.postgres(extensions: :activerecord_connection, keep_reference: false)

    # ── Features ──────────────────────────────────────────────────────────

    enable :login, :logout, :create_account, :close_account,
           :verify_account,
           :reset_password, :change_password, :change_login,
           :jwt, :jwt_refresh,
           :webauthn, :webauthn_login, :webauthn_autofill

    # ── Account table ─────────────────────────────────────────────────────

    accounts_table :pilots
    account_password_hash_column :password_hash
    account_status_column :status_id
    account_open_status_value 2
    account_unverified_status_value 1
    account_closed_status_value 3
    login_column :email

    # ── Routes ────────────────────────────────────────────────────────────

    login_route "login"
    logout_route "logout"
    create_account_route "signup"
    verify_account_route "verify-account"
    reset_password_request_route "password-resets"
    reset_password_route "reset-password"
    # jwt_refresh_route uses default "jwt-refresh"
    close_account_route nil
    change_password_route nil
    change_login_route nil
    # WebAuthn routes (built-in):
    #   POST /webauthn-setup   — register a passkey (authenticated)
    #   POST /webauthn-login   — passwordless login with passkey
    #   POST /webauthn-remove  — handled by our passkeys controller
    webauthn_auth_route nil     # 2FA challenge flow, not used
    webauthn_remove_route nil   # handled by PasskeysController

    # ── JWT ───────────────────────────────────────────────────────────────

    jwt_secret Rails.application.credentials.jwt_secret
    jwt_access_token_period 900 # 15 minutes
    jwt_refresh_token_deadline_interval days: 30

    # Include email in JWT payload for Action Cable.
    jwt_session_hash do
      h = super()
      h["e"] = account[:email] if account
      h
    end

    # Suppress the empty JWT that Rodauth would otherwise emit when the
    # session contains no account_id (e.g. after an unverified signup or
    # a failed login attempt).
    set_jwt_token do |token|
      super(token) if session[session_key]
    end

    # ── JWT refresh keys table ────────────────────────────────────────────

    jwt_refresh_token_table :account_jwt_refresh_keys
    jwt_refresh_token_id_column :id
    jwt_refresh_token_account_id_column :pilot_id
    jwt_refresh_token_key_column :key
    jwt_refresh_token_deadline_column :deadline

    # ── Password ──────────────────────────────────────────────────────────

    password_minimum_length 6
    password_maximum_length 128
    require_password_confirmation? false
    require_login_confirmation? false

    # ── JSON API mode ─────────────────────────────────────────────────────

    only_json? true

    # ── Email ─────────────────────────────────────────────────────────────

    email_from "donotreply@flyweight.org"

    reset_password_email_body do
      frontend = Rails.application.config.urls.frontend
      token_key = convert_email_token_key(reset_password_key_value)
      token = "#{account_id}#{token_separator}#{token_key}"
      "Reset your password: #{frontend}/reset-password?key=#{token}"
    end

    verify_account_email_subject "Verify your FlyWeight account"
    verify_account_email_body do
      frontend = Rails.application.config.urls.frontend
      token_key = convert_email_token_key(verify_account_key_value)
      token = "#{account_id}#{token_separator}#{token_key}"
      "Verify your FlyWeight account: #{frontend}/verify-account?key=#{token}"
    end

    # ── WebAuthn ──────────────────────────────────────────────────────────

    webauthn_origin { Rails.application.config.urls.frontend }
    webauthn_rp_id { URI.parse(Rails.application.config.urls.frontend).host }
    webauthn_rp_name "FlyWeight"

    webauthn_keys_account_id_column :account_id
    webauthn_keys_webauthn_id_column :webauthn_id
    webauthn_keys_public_key_column :public_key
    webauthn_keys_sign_count_column :sign_count
    webauthn_keys_last_use_column :last_use

    # ── Turnstile (Cloudflare CAPTCHA) ────────────────────────────────────

    require_turnstile = -> do
      next if Rails.env.test?

      token = param_or_nil("turnstile_token")
      unless TurnstileVerifier.verify(token, request.ip).success?
        response.status = 400
        response["Content-Type"] = "application/json"
        response.write({"error" => "captcha verification failed"}.to_json)
        request.halt
      end
    end

    # ── Account creation ──────────────────────────────────────────────────

    before_create_account do
      instance_exec(&require_turnstile)
      account[:name] = param("name")
      account[:created_at] = Time.current
      account[:updated_at] = Time.current
    end

    before_login do
      instance_exec(&require_turnstile)
    end

    # :verify_account suppresses autologin until the account is verified.
    create_account_autologin? false
    # Password is captured at signup, not at verification time.
    verify_account_set_password? false

    # ── Account closure ───────────────────────────────────────────────────

    delete_account_on_close? true

    # ── Response customization ────────────────────────────────────────────
    # Add pilot profile data to the login response.

    after_login do
      pilot = Pilot.find(account_id)
      json_response["name"] = pilot.name
      json_response["email"] = pilot.email
      json_response["passkeys"] = pilot.webauthn_keys.order(:last_use).map do |k|
        {"id" => k.webauthn_id, "label" => k.label, "last_used_at" => k.last_use}
      end
    end

    # Apply an optional label to a newly registered passkey.
    after_webauthn_setup do
      label = param_or_nil("label")
      if label.present?
        AccountWebauthnKey.where(account_id: account_id).
            order(:last_use).
            last&.update(label: label)
      end
    end

    # Prevent email enumeration on password reset requests.
    # Always return 204 regardless of whether the email exists.
    before_reset_password_request_route do
      if request.post?
        instance_exec(&require_turnstile)
        if (login = param_or_nil(login_param)) && account_from_login(login) && open_account? && !reset_password_email_recently_sent?
          generate_reset_password_key_value
          transaction do
            create_reset_password_key
            send_reset_password_email
          end
        end
        response.status = 204
        response.write("")
        request.halt
      end
    end
  end

  route(&:rodauth)
end
