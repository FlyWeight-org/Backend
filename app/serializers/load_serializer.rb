# frozen_string_literal: true

class LoadSerializer < ApplicationSerializer
  attributes :slug
  destroyed_aware_attributes :name
  attribute(:weight, if: proc { |load| !load.destroyed? }) { |load| load.weight.to_f }
  attribute(:bags_weight, if: proc { |load| !load.destroyed? }) { |load| load.bags_weight.to_f }
end
