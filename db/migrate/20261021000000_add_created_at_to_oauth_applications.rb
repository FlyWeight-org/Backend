# frozen_string_literal: true

# Records when each OAuth client registered, so unused registrations can be aged out.
class AddCreatedAtToOauthApplications < ActiveRecord::Migration[8.1]
  def change
    add_column :oauth_applications, :created_at, :datetime, null: false, default: -> { "CURRENT_TIMESTAMP" }
  end
end
