# frozen_string_literal: true

# RESTful-like controller for resetting user passwords. See the Devise
# documentation for more information.

class PasswordResetsController < Devise::PasswordsController

  # @private
  def create
    self.resource = resource_class.send_reset_password_instructions(resource_params)
    head :no_content
  end

  # @private
  def update
    self.resource = resource_class.reset_password_by_token(resource_params)
    if resource.errors.empty?
      head :no_content
    else
      respond_with resource, location: nil
    end
  end
end
