# frozen_string_literal: true

# An OAuth client registered by an assistant host.
class OauthApplication < ApplicationRecord
  has_many :oauth_grants, dependent: :delete_all

  # Registrations with no grants, older than a client needs to finish authorizing.
  scope :abandoned, -> { where.missing(:oauth_grants).where(created_at: ...1.day.ago) }
end
