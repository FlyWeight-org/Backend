# frozen_string_literal: true

class CreateLoads < ActiveRecord::Migration[7.0]
  def change
    create_table :loads do |t|
      t.belongs_to :flight, null: false, foreign_key: {on_delete: :cascade}
      t.string :name, :slug, null: false

      t.integer :weight, null: false, default: 0
      t.integer :bags_weight, null: false, default: 0

      t.boolean :covid19_vaccination, null: false, default: false

      t.timestamps
    end

    add_index :loads, %i[flight_id slug], unique: true
  end
end
