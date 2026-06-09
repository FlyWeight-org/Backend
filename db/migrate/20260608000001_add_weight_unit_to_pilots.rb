# frozen_string_literal: true

class AddWeightUnitToPilots < ActiveRecord::Migration[8.1]
  def up
    create_enum :weight_unit, %w[lb kg]
    add_column :pilots, :weight_unit, :enum, enum_type: :weight_unit, null: false, default: "lb"
  end

  def down
    remove_column :pilots, :weight_unit
    drop_enum :weight_unit
  end
end
