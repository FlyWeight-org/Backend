# frozen_string_literal: true

class RemoveDeviseColumns < ActiveRecord::Migration[8.1]
  def change
    remove_index :pilots, :reset_password_token

    change_table :pilots, bulk: true do |t|
      t.remove :encrypted_password, type: :string, default: "", null: false
      t.remove :remember_created_at, type: :datetime
      t.remove :reset_password_token, type: :string
      t.remove :reset_password_sent_at, type: :datetime
    end

    drop_table :jwt_denylist do |t|
      t.string :jti, null: false
      t.datetime :exp, null: false
      t.index :jti, name: "index_jwt_denylist_on_jti"
    end
  end
end
