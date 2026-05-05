# frozen_string_literal: true

class LoadSerializer < ApplicationSerializer
  attributes :slug
  destroyed_aware_attributes :name, :weight, :bags_weight
end
