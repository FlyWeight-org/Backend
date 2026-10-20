# frozen_string_literal: true

require "rails_helper"

RSpec.describe "MCP authorization" do
  let(:pilot) { create(:pilot) }

  it "connects an assistant, rotates its token, and revokes the connection" do
    tokens = authorize_mcp(pilot)
    expect(tokens).to include("access_token", "refresh_token")
    mcp_request(tokens.fetch("access_token"), "tools/list")
    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.dig("result", "tools").pluck("name")).to include("get_flight", "upsert_load")

    refreshed = refresh_mcp_token(tokens)
    expect(refreshed.fetch("refresh_token")).not_to eq(tokens.fetch("refresh_token"))

    headers = {"Authorization" => "Bearer #{jwt_for(pilot)}"}
    post "/oauth/authorize", params: authorization_params(tokens.fetch("client_id")).merge(decision: "allow"), headers: headers, as: :json
    lapsed = authorize_mcp(pilot)
    OauthGrant.find_by!(oauth_application: OauthApplication.find_by!(client_id: lapsed.fetch("client_id"))).update!(expires_in: 31.days.ago)
    get "/account/connections", headers: headers
    connection = response.parsed_body.fetch("connections").sole
    expect(connection).to include("name" => "Test assistant", "scopes" => Mcp::Settings::SCOPES, "callback_host" => "assistant.example")
    delete "/account/connections/#{connection.fetch("id")}", headers: headers
    expect(response).to have_http_status(:no_content)
    expect(OauthGrant.unrevoked.where(oauth_application_id: connection.fetch("id"))).to be_none
    mcp_request(refreshed.fetch("access_token"), "tools/list")
    expect(response).to have_http_status(:unauthorized)
  end

  it "advertises discovery and challenges browser JWTs at the MCP resource" do
    host! "app.test.host"
    get "/.well-known/oauth-authorization-server"
    expect(response.parsed_body).to include("code_challenge_methods_supported" => %w[S256])
    get "/.well-known/oauth-protected-resource/mcp"
    expect(response.parsed_body).to include("resource" => Mcp::Settings.resource)
    mcp_request(jwt_for(pilot), "tools/list")
    expect(response).to have_http_status(:unauthorized)
    expect(response.headers.fetch("WWW-Authenticate")).to include("resource_metadata=")
  end

  it "preserves the authorization request through browser login and allows denial without a grant" do
    params = authorization_params(register_mcp_client)
    get "/oauth/authorize", params: params
    expect(response).to redirect_to(%r{\Ahttp://test.host/connect\?})
    pilot.webauthn_keys.create!(webauthn_id: "registered-passkey", public_key: "test-public-key")
    post "/login", params: {login: pilot.email, password: pilot.password}, as: :json
    expect(response).to have_http_status(:ok)
    headers = {"Authorization" => response.headers.fetch("Authorization"), "Accept" => "application/json", "Content-Type" => "application/json"}
    get "/oauth/authorize", params: params, headers: headers
    expect(response.parsed_body).to include("client_name" => "Test assistant", "scopes" => %w[flights:read flights:write])
    post "/oauth/authorize", params: params.merge(decision: "deny"), headers: headers, as: :json
    query = URI.decode_www_form(URI(response.parsed_body.fetch("redirect_uri")).query).to_h
    expect(query).to include("error" => "access_denied", "state" => "test-state")
    expect(OauthGrant.count).to eq(0)
  end

  it "rejects tampered callbacks, resources and PKCE without granting access" do
    params = authorization_params(register_mcp_client)
    headers = {"Authorization" => "Bearer #{jwt_for(pilot)}"}
    [{redirect_uri: "https://attacker.example/callback"}, {resource: "https://other.example/mcp"},
     {code_challenge_method: "plain"}].each do |changes|
      post "/oauth/authorize", params: params.merge(decision: "allow").merge(changes), headers: headers, as: :json
      expect(response).to have_http_status(:bad_request)
    end
    expect(OauthGrant.count).to eq(0)
  end

  it "rejects expired tokens and closed accounts" do
    tokens = authorize_mcp(pilot)
    grant = OauthGrant.sole
    grant.update!(expires_in: 1.minute.ago)
    mcp_request(tokens.fetch("access_token"), "tools/list")
    expect(response).to have_http_status(:unauthorized)
    grant.update!(expires_in: 10.minutes.from_now)
    pilot.update!(status_id: 3)
    mcp_request(tokens.fetch("access_token"), "tools/list")
    expect(response).to have_http_status(:unauthorized)
    refresh_mcp_token(tokens)
    expect(response).to have_http_status(:bad_request)
  end

  it "hides the integration when disabled" do
    allow(Rails.application.config.x).to receive(:mcp_enabled).and_return(false)
    get "/.well-known/oauth-authorization-server"
    expect(response).to have_http_status(:not_found)
    post "/mcp", params: {}, as: :json
    expect(response).to have_http_status(:not_found)
  end

  it "tolerates a concurrent refresh but revokes the grant when a consumed refresh token is replayed later" do
    tokens = authorize_mcp(pilot)
    replacement = refresh_mcp_token(tokens).merge("client_id" => tokens.fetch("client_id"))
    refresh_mcp_token(tokens)
    expect(response).to have_http_status(:bad_request)
    mcp_request(replacement.fetch("access_token"), "tools/list")
    expect(response).to have_http_status(:ok)

    OauthGrant.sole.update!(expires_in: 10.minutes.from_now)
    refresh_mcp_token(tokens)
    expect(response).to have_http_status(:bad_request)
    mcp_request(replacement.fetch("access_token"), "tools/list")
    expect(response).to have_http_status(:unauthorized)
    refresh_mcp_token(replacement)
    expect(response).to have_http_status(:bad_request)
  end

  it "uses canonical discovery URLs regardless of the incoming request host" do
    host! "test.host"
    get "/.well-known/oauth-authorization-server"
    expect(response.parsed_body).to include(
      "authorization_endpoint" => "http://app.test.host/oauth/authorize",
      "token_endpoint"         => "http://app.test.host/oauth/token",
      "registration_endpoint"  => "http://app.test.host/oauth/register",
      "revocation_endpoint"    => "http://app.test.host/oauth/revoke"
    )
  end

  it "ignores internal registration aliases and refuses unsafe callbacks already stored" do
    client_id = register_mcp_client
    post "/oauth/register", params: {
        client_name: "Safe name", redirect_uris: ["https://assistant.example/callback"],
      redirect_uri: "javascript://example.com/%0aalert(document.domain)//", name: "Alias name",
      scopes: "unrestricted", token_endpoint_auth_method: "none"
    }, as: :json
    expect(response).to have_http_status(:created)
    registered = OauthApplication.find_by!(client_id: response.parsed_body.fetch("client_id"))
    expect(registered).to have_attributes(name: "Safe name", redirect_uri: "https://assistant.example/callback")
    expect(registered.scopes.split).to match_array(Mcp::Settings::SCOPES)

    unsafe = "javascript://example.com/%0aalert(document.domain)//"
    OauthApplication.find_by!(client_id: client_id).update!(redirect_uri: unsafe)
    post "/oauth/authorize", params: authorization_params(client_id).merge(redirect_uri: unsafe, decision: "allow"),
                             headers: {"Authorization" => "Bearer #{jwt_for(pilot)}"}, as: :json
    expect(response).to have_http_status(:bad_request)
    expect(OauthGrant.count).to eq(0)
  end

  it "revokes through the form endpoint without a browser session and tolerates unknown tokens" do
    tokens = authorize_mcp(pilot)
    other_client = register_mcp_client
    post "/oauth/revoke", params: {client_id: other_client, token: tokens.fetch("access_token")}
    expect(response).to have_http_status(:ok)
    mcp_request(tokens.fetch("access_token"), "tools/list")
    expect(response).to have_http_status(:ok)
    post "/oauth/revoke", params: {client_id: tokens.fetch("client_id"), token: tokens.fetch("access_token")}
    expect(response).to have_http_status(:ok)
    mcp_request(tokens.fetch("access_token"), "tools/list")
    expect(response).to have_http_status(:unauthorized)
    post "/oauth/revoke", params: {client_id: tokens.fetch("client_id"), token: "unknown"}
    expect(response).to have_http_status(:ok)
  end
end
