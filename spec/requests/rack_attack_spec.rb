# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Rack::Attack throttling" do
  def attack_request(path, **) = Rack::Attack::Request.new(Rack::MockRequest.env_for(path, method: "POST", **))

  before(:each) do
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
    Rack::Attack.cache.store.clear
  end

  it "throttles POST /signup after 3 requests per hour from the same IP" do
    4.times do |i|
      post "/signup",
           params:  {login: "rate#{i}@example.com", password: "securepass", name: "Rate #{i}"},
           headers: {"REMOTE_ADDR" => "1.2.3.4"},
           as:      :json
    end

    expect(response).to have_http_status(:too_many_requests)
    expect(response.headers["Retry-After"]).to be_present
    expect(response.parsed_body).to eq("error" => "Too many requests")
  end

  it "keys OAuth token and MCP requests by credential, falling back to IP" do
    expect(attack_request("/oauth/token", params: {client_id: "form-client"}).oauth_client_id).to eq("form-client")
    basic = "Basic #{Base64.strict_encode64("basic-client:secret")}"
    expect(attack_request("/oauth/token", "HTTP_AUTHORIZATION" => basic).oauth_client_id).to eq("basic-client")
    expect(attack_request("/oauth/token").oauth_client_id).to be_nil

    bearer = attack_request("/mcp", "HTTP_AUTHORIZATION" => "Bearer secret-token").bearer_digest
    expect(bearer).to eq(Digest::SHA256.hexdigest("secret-token"))
    expect(attack_request("/mcp", "HTTP_AUTHORIZATION" => basic).bearer_digest).to be_nil
  end
end
