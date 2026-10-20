# frozen_string_literal: true

# Retains consumed token digests to revoke grants when a rotated token is replayed.
class CreateOauthRefreshTokenUses < ActiveRecord::Migration[8.1]
  def change
    create_table :oauth_refresh_token_uses do |t|
      t.references :oauth_grant, null: false, foreign_key: {on_delete: :cascade}
      t.string :token_hash, null: false
      t.index :token_hash, unique: true
    end
  end
end
