# frozen_string_literal: true

# Used to blacklist JWTs of users that have been logged out. See the Devise JWT
# documentation for more information.

class Denylist < ApplicationRecord
  include Devise::JWT::RevocationStrategies::Denylist

  self.table_name = "jwt_denylist"
end
