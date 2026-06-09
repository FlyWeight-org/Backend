# frozen_string_literal: true

class ChangeLoadsWeightToDecimal < ActiveRecord::Migration[8.1]
  def up
    change_table :loads, bulk: true do |t|
      t.change :weight, :decimal, precision: 8, scale: 2, null: false, default: 0
      t.change :bags_weight, :decimal, precision: 8, scale: 2, null: false, default: 0
    end
  end

  def down
    change_table :loads, bulk: true do |t|
      t.change :weight, :integer, null: false, default: 0
      t.change :bags_weight, :integer, null: false, default: 0
    end
  end
end
