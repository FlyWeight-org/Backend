# frozen_string_literal: true

# RESTful-like controller for signing in and out Pilots. See the Devise
# documentation for more information.

class SessionsController < Devise::SessionsController
  private

  def sign_in(resource_or_scope, *args)
    options = args.extract_options!
    super resource_or_scope, *args, options.merge(store: false)
  end

  def respond_with(_resource, _opts={})
    render "registrations/create"
  end

  def respond_to_on_destroy = head :no_content
end
