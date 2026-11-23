# frozen_string_literal: true

require "rails_helper"

RSpec.describe FlightsChannel do
  let(:pilot) { create :pilot }

  before :each do
    @flight = create(:flight, pilot:)

    stub_connection current_pilot: pilot
    subscribe
  end

  it "confirms the subscription" do
    expect(subscription).to be_confirmed
  end

  it "streams flight creates" do
    expect { create :flight, pilot: }.
        to(have_broadcasted_to(pilot).with do |payload|
             expect(payload).to match_json(
                                  uuid:            String,
                                  date:            String,
                                  description:     String,
                                  passenger_count: Integer
                                )
           end)
  end

  it "streams flight updates" do
    expect { @flight.update! description: "new description" }.
        to(have_broadcasted_to(pilot).with do |payload|
             expect(payload).to match_json(
                                  uuid:            String,
                                  date:            String,
                                  description:     "new description",
                                  passenger_count: Integer
                                )
           end)
  end

  it "streams passenger adds" do
    expect { create :load, :passenger, flight: @flight }.
        to(have_broadcasted_to(pilot).with do |payload|
             expect(payload).to match_json(
                                  uuid:            @flight.uuid,
                                  date:            String,
                                  description:     String,
                                  passenger_count: 1
                                )
           end)
  end

  it "streams flight deletes" do
    expect { @flight.destroy! }.
        to(have_broadcasted_to(pilot).with do |payload|
             expect(payload).to match_json(
                                  uuid:       String,
                                  destroyed?: true
                                )
           end)
  end
end
