# frozen_string_literal: true

module Authentication
  def authenticate!(request, pilot)
    auth_headers = Devise::JWT::TestHelpers.auth_headers({}, pilot)
    request.headers.merge!(auth_headers)
  end

  def jwt_for(pilot)
    headers = Devise::JWT::TestHelpers.auth_headers({}, pilot)
    headers["Authorization"].sub(/^Bearer /, "")
  end
end
