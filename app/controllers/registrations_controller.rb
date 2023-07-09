# frozen_string_literal: true

# RESTful-like controller for creating Pilot accounts. See the Devise
# documentation for more information.

class RegistrationsController < Devise::RegistrationsController
  prepend_before_action :authenticate_scope!, only: %i[show update destroy] # rubocop:disable Rails/LexicallyScopedActionFilter

  # @private
  def show; end

  def create = super { response.status = :created }

  private

  def sign_up(resource_name, resource)
    sign_in(resource_name, resource, store: false)
  end

  # do nothing, no sessions
  def bypass_sign_in(_resource, scope: nil); end
end
