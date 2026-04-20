# frozen_string_literal: true

# Provides authentication helpers backed by Rodauth.
# Include in ApplicationController to make `authenticate_pilot!`,
# `current_pilot`, and `pilot_signed_in?` available in all controllers.

module RodauthAuthentication
  extend ActiveSupport::Concern

  included do
    helper_method :current_pilot, :pilot_signed_in?
  end

  private

  def authenticate_pilot!
    return if rodauth.logged_in?

    render json:   {error: "You need to sign in or sign up before continuing."},
           status: :unauthorized
  end

  def current_pilot
    return @current_pilot if defined?(@current_pilot)

    @current_pilot = Pilot.find_by(id: rodauth.session_value) if rodauth.logged_in?
  end

  def pilot_signed_in?
    rodauth.logged_in?
  end
end
