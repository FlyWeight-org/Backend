# frozen_string_literal: true

module McpRequests
  def register_mcp_client
    host! "app.test.host"
    post "/oauth/register", params: {
        client_name: "Test assistant", redirect_uris: ["https://assistant.example/callback"],
        grant_types: %w[authorization_code refresh_token], response_types: %w[code],
        token_endpoint_auth_method: "none"
    }, as: :json
    response.parsed_body.fetch("client_id")
  end

  def authorization_params(client_id)
    {
        client_id: client_id, redirect_uri: "https://assistant.example/callback",
        response_type: "code", scope: "flights:read flights:write", state: "test-state",
        resource: Mcp::Settings.resource, code_challenge_method: "S256",
        code_challenge: Base64.urlsafe_encode64(Digest::SHA256.digest("v" * 43), padding: false)
    }
  end

  # Authorizes with the scope the MCP endpoint challenges for, as a spec-following client does.
  def authorize_mcp(pilot, scope: nil)
    client_id = register_mcp_client
    scope ||= challenged_scope { mcp_request(nil, "tools/list") }
    params = authorization_params(client_id).merge(scope: scope)
    post "/oauth/authorize", params: params.merge(decision: "allow"),
                             headers: {"Authorization" => "Bearer #{jwt_for(pilot)}"}, as: :json
    callback = URI(response.parsed_body.fetch("redirect_uri"))
    code = URI.decode_www_form(callback.query).to_h.fetch("code")
    post "/oauth/token", params: {
        client_id: client_id, grant_type: "authorization_code", code: code,
        redirect_uri: params[:redirect_uri], code_verifier: "v" * 43, resource: params[:resource]
    }
    response.parsed_body.merge("client_id" => client_id)
  end

  # @return [String] The scope advertised by the challenge that the block's request receives.
  def challenged_scope
    yield
    response.headers.fetch("WWW-Authenticate")[/scope="([^"]*)"/, 1]
  end

  def refresh_mcp_token(tokens, refresh_token: tokens.fetch("refresh_token"))
    post "/oauth/token", params: {client_id: tokens.fetch("client_id"), grant_type: "refresh_token",
                                  refresh_token: refresh_token, resource: Mcp::Settings.resource}
    response.parsed_body
  end

  def mcp_request(token, method, params={})
    post "/mcp", params: {jsonrpc: "2.0", id: 1, method: method, params: params},
                 headers: {"Authorization" => "Bearer #{token}", "Accept" => "application/json, text/event-stream"}, as: :json
  end
end

RSpec.configure { |config| config.include McpRequests, type: :request }
