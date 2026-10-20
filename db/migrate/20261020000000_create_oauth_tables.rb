# frozen_string_literal: true

# Stores assistant registrations and pilot authorization grants.
class CreateOauthTables < ActiveRecord::Migration[8.1]
  def change
    create_table :oauth_applications do |t|
      t.string :client_id, null: false
      t.string :client_secret
      t.string :name, null: false
      t.text :redirect_uri, null: false
      t.string :scopes, null: false
      t.string :token_endpoint_auth_method, null: false
      t.string :grant_types, null: false
      t.string :response_types, null: false
      t.string :registration_access_token
      t.index :client_id, unique: true
    end

    create_table :oauth_grants do |t|
      t.references :account, null: false, foreign_key: {to_table: :pilots, on_delete: :cascade}
      t.references :oauth_application, null: false, foreign_key: {on_delete: :cascade}
      t.string :type, null: false
      t.text :redirect_uri, null: false
      t.string :code
      t.string :scopes, null: false
      t.datetime :expires_in, null: false
      t.datetime :revoked_at
      t.string :token
      t.string :refresh_token
      t.string :code_challenge
      t.string :code_challenge_method
      t.string :resource, null: false
      t.datetime :created_at, null: false, default: -> { "CURRENT_TIMESTAMP" }
      t.index :code, unique: true
      t.index :token, unique: true
      t.index :refresh_token, unique: true
    end
  end
end
