# frozen_string_literal: true

if load.destroyed?
  json.call load, :slug, :destroyed?
else
  json.call load, :slug, :name, :weight, :bags_weight
end
