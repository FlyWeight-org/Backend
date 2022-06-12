# frozen_string_literal: true

require "rails_helper"

RSpec.describe PurgeFlightJob do
  let(:flight) { create :flight }

  it "deletes a flight by ID" do
    described_class.new.perform flight.id
    expect { flight.reload }.to raise_error(ActiveRecord::RecordNotFound)
  end

  it "does nothing if given a nonexistent ID" do
    expect { described_class.new.perform(-123) }.not_to raise_error
  end
end
