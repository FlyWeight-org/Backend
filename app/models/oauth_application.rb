# frozen_string_literal: true

# An OAuth client registered by an assistant host.
class OauthApplication < ApplicationRecord
  has_many :oauth_grants, dependent: :delete_all
end
