# frozen_string_literal: true

Rails.application.routes.draw do
  devise_for :pilots, skip: :all
  devise_scope :pilot do
    post "login" => "sessions#create"
    delete "logout" => "sessions#destroy"

    post "signup" => "registrations#create"
    get "account" => "registrations#show"
    put "account" => "registrations#update"
    patch "account" => "registrations#update"
    delete "account" => "registrations#destroy"

    resource :password_resets, only: %i[create update]
  end

  namespace :pilot do
    resources :flights, only: %i[index create update destroy] do
      resources :loads, only: %i[create destroy]
    end
  end

  resources :flights, only: :show do
    resources :loads, only: :create
  end

  if Rails.env.cypress?
    get "__cypress__/reset" => Cypress::Reset.new
    get "__cypress__/last_email" => Cypress::LastEmail.new
  end

  if Rails.env.production?
    authenticate :pilot, -> { it.admin? } do
      mount GoodJob::Engine => "good_job"
    end
  else
    mount GoodJob::Engine => "good_job"
  end

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Prometheus metrics for Fly.io (production/development only)
  get "metrics" => "metrics#show" unless Rails.env.test? || Rails.env.cypress?

  # Render dynamic PWA files from app/views/pwa/*
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  root to: redirect(Rails.application.config.urls.frontend)

  direct :edit_password do |_pilot, query|
    URI.join(Rails.application.config.urls.frontend, "/reset-password?#{query.to_query}").to_s
  end
end
