# frozen_string_literal: true

# A Pilot is the primary user account for FlyWeight. Pilots create {Flight}s and
# share them with passengers (who are unauthenticated).
#
# Associations
# ------------
#
# |           |                                      |
# |:----------|:-------------------------------------|
# | `flights` | The {Flight}s created by this pilot. |
#
# Properties
# ----------
#
# |         |                                                                                     |
# |:--------|:------------------------------------------------------------------------------------|
# | `name`  | The pilot's name, used to help passengers identify the flight.                      |
# | `email` | The pilot's email, used to uniquely identify the pilot and for forgotten passwords. |
#
# Other attributes are used by Devise and its plug-ins.

class Pilot < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :validatable,
         :jwt_authenticatable, jwt_revocation_strategy: Denylist

  has_many :flights, dependent: :delete_all

  validates :name,
            presence: true,
            length:   {maximum: 200}

  # @private
  def to_param = email

  # @private
  def jwt_payload = {e: email}
end
