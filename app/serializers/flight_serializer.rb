# frozen_string_literal: true

class FlightSerializer < ApplicationSerializer
  attributes :uuid, :date, :description

  one :pilot, resource: PilotSerializer

  attribute :can_edit do
    params.fetch(:can_edit, false)
  end

  many :loads, resource: ->(_load) { LoadSerializer }, if: proc { params[:include_loads] }
end
