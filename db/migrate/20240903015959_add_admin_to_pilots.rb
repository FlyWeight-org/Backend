# frozen_string_literal: true

class AddAdminToPilots < ActiveRecord::Migration[7.2]
  def change
    add_column :pilots, :admin, :boolean, default: false, null: false
  end
end
