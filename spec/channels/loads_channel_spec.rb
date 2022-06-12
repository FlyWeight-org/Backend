# frozen_string_literal: true

require "rails_helper"

RSpec.describe LoadsChannel do
  let(:pilot) { create :pilot }
  let(:flight) { create :flight, pilot: }
  let(:flight_id) { flight.uuid }

  before :each do
    @load = create :load, :passenger, flight:
  end

  before :each do
    stub_connection current_pilot: pilot
    subscribe id: flight_id
  end

  context "[flight belonging to other pilot]" do
    let(:flight) { create :flight }

    it "rejects the subscription" do
      expect(subscription).to be_rejected
    end
  end

  context "[unknown UUID]" do
    let(:flight_id) { SecureRandom.uuid }

    it "rejects the subscription" do
      expect(subscription).to be_rejected
    end
  end

  it "confirms the subscription" do
    expect(subscription).to be_confirmed
  end

  it "streams load creates" do
    expect { create :load, :cargo, flight: }.
        to(have_broadcasted_to(flight).with do |payload|
             expect(payload).to match_json_expression(
                                  slug:                String,
                                  name:                String,
                                  weight:              0,
                                  bags_weight:         Integer,
                                  covid19_vaccination: false
                                )
           end)
  end

  it "streams load updates" do
    expect { @load.update! name: "new name" }.
        to(have_broadcasted_to(flight).with do |payload|
             expect(payload).to match_json_expression(
                                  slug:                "new-name",
                                  name:                "new name",
                                  weight:              Integer,
                                  bags_weight:         Integer,
                                  covid19_vaccination: Boolean
                                )
           end)
  end

  it "streams load deletes" do
    expect { @load.destroy }.
        to(have_broadcasted_to(flight).with do |payload|
             expect(payload).to match_json_expression(
                                  slug:       String,
                                  destroyed?: true
                                )
           end)
  end
end
