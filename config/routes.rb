# frozen_string_literal: true

Rails.application.routes.draw do
  # ── Rodauth handles: ────────────────────────────────────────────────
  # POST /login          — authenticate with email/password
  # POST /logout         — revoke session/refresh token
  # POST /signup         — create account
  # POST /password-resets — request password reset email
  # POST /reset-password — reset password with token
  # POST /jwt-refresh    — refresh access token

  # ── Account management ──────────────────────────────────────────────

  get "account" => "accounts#show"
  put "account" => "accounts#update"
  patch "account" => "accounts#update"
  delete "account" => "accounts#destroy"

  # ── Passkey management ──────────────────────────────────────────────
  # Rodauth handles registration (POST /webauthn-setup) and login
  # (POST /webauthn-login). Listing, renaming, and removing passkeys
  # happens through PasskeysController.

  resources :passkeys, path: "account/passkeys", only: %i[index update destroy],
                        param: :webauthn_id

  # ── Pilot resources ─────────────────────────────────────────────────

  namespace :pilot do
    resources :flights, only: %i[index create update destroy] do
      resources :loads, only: %i[create destroy]
    end
  end

  resources :flights, only: :show do
    resources :loads, only: :create
  end

  # ── Background tasks ────────────────────────────────────────────────

  namespace :qstash do
    post :purge_stale_flights, to: "tasks#purge_stale_flights"
  end

  # ── Cypress test helpers ────────────────────────────────────────────

  if Rails.env.cypress?
    get "__cypress__/reset" => Cypress::Reset.new
    get "__cypress__/last_email" => Cypress::LastEmail.new
  end

  # ── Health & metrics ────────────────────────────────────────────────

  get "up" => "rails/health#show", as: :rails_health_check

  # Frontend warm-up ping; goes through the verify-* middlewares so a hit
  # here wakes Postgres and Redis pools alongside the Fly machine itself.
  get "presence" => "presence#show"

  get "metrics" => "metrics#show" unless Rails.env.test? || Rails.env.cypress?

  root to: redirect(Rails.application.config.urls.frontend)
end
