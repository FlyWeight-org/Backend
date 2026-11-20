# frozen_string_literal: true

require "rails_helper"

RSpec.describe ApplicationCable::Connection, type: :channel do
  let(:pilot) { create :pilot }

  it "rejects invalid JWTs" do
    expect { connect params: {jwt: "invalid"} }.to have_rejected_connection
  end

  it "accepts valid JWTs" do
    connect params: {jwt: jwt_for(pilot)}
    expect(connection.current_pilot).to eq(pilot)
  end

  it "rejects a JWT that names a pilot but no logged-in account" do
    token = JWT.encode({"e" => pilot.email, "exp" => 1.hour.from_now.to_i}, Rails.application.credentials.jwt_secret, "HS256")
    expect { connect params: {jwt: token} }.to have_rejected_connection
  end

  it "rejects valid JWTs for deleted pilots" do
    jwt = jwt_for(pilot)
    pilot.destroy!
    expect { connect params: {jwt:} }.to have_rejected_connection
  end
end
