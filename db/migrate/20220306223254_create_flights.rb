# frozen_string_literal: true

class CreateFlights < ActiveRecord::Migration[7.0]
  def change
    create_table :flights do |t|
      t.belongs_to :pilot, null: false, foreign_key: {on_delete: :cascade}
      t.string :uuid, null: false
      t.date :date, null: false
      t.string :description
      t.timestamps
    end

    add_index :flights, :uuid, unique: true
  end
end
