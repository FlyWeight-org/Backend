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

  root to: redirect(Rails.application.config.urls.frontend)

  direct :edit_password do |_pilot, query|
    URI.join(Rails.application.config.urls.frontend, "/reset-password?#{query.to_query}").to_s
  end
end
