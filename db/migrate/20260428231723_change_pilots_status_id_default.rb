# frozen_string_literal: true

class ChangePilotsStatusIdDefault < ActiveRecord::Migration[8.1]
  def change
    change_column_default :pilots, :status_id, from: 2, to: 1
  end
end
