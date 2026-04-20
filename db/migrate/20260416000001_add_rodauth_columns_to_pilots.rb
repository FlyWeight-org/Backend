# frozen_string_literal: true

class AddRodauthColumnsToPilots < ActiveRecord::Migration[8.1]
  def up
    change_table :pilots, bulk: true do |t|
      t.string :password_hash
      t.integer :status_id, default: 2, null: false
    end

    # Copy existing Devise bcrypt hashes to Rodauth column.
    # Both use the same BCrypt format ($2a$12$...) and no pepper is configured.
    execute "UPDATE pilots SET password_hash = encrypted_password WHERE encrypted_password != ''"
  end

  def down
    change_table :pilots, bulk: true do |t|
      t.remove :password_hash
      t.remove :status_id
    end
  end
end
