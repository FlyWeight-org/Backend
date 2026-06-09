# frozen_string_literal: true

class AddLocaleToPilots < ActiveRecord::Migration[8.1]
  def change
    add_column :pilots, :locale, :string
  end
end
