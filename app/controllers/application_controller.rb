# frozen_string_literal: true

require "application_responder"

# @abstract
#
# Abstract superclass for all FlyWeight controllers.
#
# Standard Responses
# ------------------
#
# * When a record is not found, the response will be a 404 with the JSON body of
#   the form `{"error": "A description of the error"}`
# * When an internal error occurs, the response will be a 500 with the JSON body
#   of the form `{"error": "An internal error occurred"}` (in production) or
#   detailed error information (in development).

class ApplicationController < ActionController::API
  include ActionController::MimeResponds

  self.responder = ApplicationResponder
  respond_to :json

  rescue_from StandardError, with: :other_error
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  # @private
  def configure_permitted_parameters
    devise_parameter_sanitizer.permit(:sign_up, keys: %i[name])
    devise_parameter_sanitizer.permit(:account_update, keys: %i[name])
  end

  private

  def not_found(error)
    respond_to do |format|
      format.json { render json: {error: error.to_s}, status: :not_found }
      format.any { head :not_found }
    end
  end

  def other_error(error)
    raise error if Rails.env.test?

    respond_to do |format|
      format.json { render json: error_json(error), status: :internal_server_error }
      format.any { head :internal_server_error }
    end
  end

  def error_json(error)
    if Rails.env.development?
      {error: error.class.to_s, message: error.to_s, backtrace: error.backtrace}
    else
      {error: I18n.t("application_controller.errors.internal_server_error")}
    end
  end
end
