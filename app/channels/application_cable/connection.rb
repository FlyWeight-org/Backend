# frozen_string_literal: true

# Container module for Action Cable classes.

module ApplicationCable

  # The base Action Cable connection class. Handles authenticating WebSocket
  # connections.
  #
  # Connections are identified by a {Pilot}'s JSON web token (JWT). When
  # making a request to `/cable`, pass the JWT as a query parameter
  # (`/cable?jwt=abc123`).

  class Connection < ActionCable::Connection::Base

    # @return [String] The pilot's JSON web token.
    attr_reader :jwt

    identified_by :current_pilot

    # @private
    def connect
      (@jwt = token_decoder.call(request.params[:jwt])) or reject_unauthorized_connection
      self.current_pilot = find_verified_pilot
    rescue ActiveRecord::RecordNotFound, JWT::DecodeError
      reject_unauthorized_connection
    end

    private

    def find_verified_pilot = Pilot.find_by!(email: jwt["e"])

    def token_decoder
      @token_decoder ||= Warden::JWTAuth::TokenDecoder.new
    end
  end
end
