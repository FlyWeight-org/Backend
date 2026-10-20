# frozen_string_literal: true

# Gives Loads whose names have no ASCII transliteration their digest slug.
class ReslugUnparameterizableLoads < ActiveRecord::Migration[8.1]
  def up
    Load.where(slug: "").find_each(&:save!)
  end

  def down; end
end
