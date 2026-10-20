# frozen_string_literal: true

require "rails_helper"

RSpec.describe "MCP flight tools" do
  let(:pilot) { create(:pilot, weight_unit: "kg") }
  let(:tokens) { authorize_mcp(pilot) }
  let(:token) { tokens.fetch("access_token") }

  def call_tool(name, **arguments)
    mcp_request(token, "tools/call", {name: name, arguments: arguments})
    response.parsed_body.fetch("result")
  end

  it "manages a flight and converts replacement loads without creating duplicates" do
    created = call_tool("create_flight", date: "2026-10-25", description: "Coast trip").fetch("structuredContent")
    uuid = created.fetch("uuid")
    expect(created.fetch("invitation_url")).to end_with("/flights/#{uuid}")

    call_tool("upsert_load", flight_id: uuid, name: "Alex", weight: 80, bags_weight: 5, unit: "kg")
    updated = call_tool("upsert_load", flight_id: uuid, name: "Alex", weight: 75, bags_weight: 4, unit: "kg").fetch("structuredContent")
    flight = pilot.flights.find_by!(uuid: uuid)
    expect(flight.loads.count).to eq(1)
    expect(flight.loads.sole.weight.to_f).to eq(165.35)
    expect(updated).to include("unit" => "kg", "passenger_count" => 1)
    expect(updated.fetch("totals")).to include("combined_weight" => 79.0)

    call_tool("upsert_load", flight_id: uuid, name: "Equipment", weight: 0, bags_weight: 10, unit: "lb")
    details = call_tool("get_flight", flight_id: uuid).fetch("structuredContent")
    expect(details.fetch("loads").size).to eq(2)
    expect(details.dig("totals", "combined_weight")).to eq(83.54)
    expect(call_tool("update_flight", flight_id: uuid, date: "2026-10-26").dig("structuredContent", "date")).to eq("2026-10-26")
    call_tool("delete_load", flight_id: uuid, slug: "alex")
    expect(flight.loads.pluck(:slug)).to eq(%w[equipment])
    call_tool("delete_flight", flight_id: uuid)
    expect(pilot.flights).to be_empty
    expect(Load.where(flight_id: flight.id)).to be_empty
  end

  it "does not expose or mutate another pilot's flights and loads" do
    foreign_flight = create(:flight)
    %w[get_flight delete_flight].each do |name|
      result = call_tool(name, flight_id: foreign_flight.uuid)
      expect(result).to include("isError" => true)
      expect(result.dig("structuredContent", "error")).to eq("not_found")
    end
    expect(call_tool("list_flights").dig("structuredContent", "flights")).to be_empty
    expect(foreign_flight.reload).to be_persisted
  end

  it "enforces a read-only grant for write calls" do
    read_token = authorize_mcp(pilot, scope: "flights:read").fetch("access_token")
    mcp_request(read_token, "tools/call", {name: "create_flight", arguments: {date: "2026-10-25"}})
    expect(response.parsed_body.dig("result", "structuredContent", "error")).to eq("insufficient_scope")
    expect(pilot.flights).to be_empty
  end

  it "reports invalid dates and zero total weight without modifying records" do
    expect(call_tool("create_flight", date: "2026-02-30").dig("structuredContent", "error")).to eq("invalid_arguments")
    flight = create(:flight, pilot: pilot)
    result = call_tool("upsert_load", flight_id: flight.uuid, name: "Alex", weight: 0, bags_weight: 0, unit: "lb")
    expect(result.dig("structuredContent", "error")).to eq("validation_failed")
    expect(flight.loads).to be_empty
  end

  it "paginates deterministically without including other pilots' flights" do
    older = create(:flight, pilot: pilot, date: "2026-10-24")
    newer = create(:flight, pilot: pilot, date: "2026-10-25")
    create(:flight, date: "2026-10-26")
    first = call_tool("list_flights", limit: 1).fetch("structuredContent")
    expect(first.fetch("flights").pluck("uuid")).to eq([newer.uuid])
    second = call_tool("list_flights", limit: 1, page: first.fetch("next_page")).fetch("structuredContent")
    expect(second.fetch("flights").pluck("uuid")).to eq([older.uuid])
    expect(second.fetch("next_page")).to be_nil
  end
end
