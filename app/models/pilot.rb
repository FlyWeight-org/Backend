# frozen_string_literal: true

# A Pilot is the primary user account for FlyWeight. Pilots create {Flight}s and
# share them with passengers (who are unauthenticated).
#
# Associations
# ------------
#
# |                  |                                      |
# |:-----------------|:-------------------------------------|
# | `flights`        | The {Flight}s created by this pilot. |
# | `webauthn_keys`  | Registered passkey credentials.      |
#
# Properties
# ----------
#
# |         |                                                                                     |
# |:--------|:------------------------------------------------------------------------------------|
# | `name`  | The pilot's name, used to help passengers identify the flight.                      |
# | `email` | The pilot's email, used to uniquely identify the pilot and for forgotten passwords. |

class Pilot < ApplicationRecord
  include Rodauth::Rails.model

  has_many :flights, dependent: :delete_all
  has_many :webauthn_keys, class_name:  "AccountWebauthnKey",
                           foreign_key: :account_id,
                           dependent:   :delete_all,
                           inverse_of:  :pilot

  validates :name,
            presence: true,
            length:   {maximum: 200}
  validates :email,
            presence:   true,
            uniqueness: {case_sensitive: false},
            format:     {with: /\A[^@\s]+@[^@\s]+\z/}

  # @private
  def to_param = email
end
