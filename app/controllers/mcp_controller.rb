# frozen_string_literal: true

# Serves the stateless, pilot-scoped MCP endpoint and resource discovery.
class McpController < ApplicationController
  before_action :require_enabled

  # Advertises the canonical resource and its OAuth authorization server.
  def metadata
    render json: {resource: Mcp::Settings.resource, authorization_servers: [Mcp::Settings.issuer],
                  scopes_supported: Mcp::Settings::SCOPES, bearer_methods_supported: %w[header]}
  end

  # Authenticates each request before dispatching it through the SDK transport.
  def handle
    response.set_header("Cache-Control", "no-store")
    grant = OauthGrant.authenticate(request.authorization.to_s[/\ABearer (\S+)\z/i, 1])
    return challenge(:unauthorized, "invalid_token") unless grant
    return challenge(:forbidden, "insufficient_scope") unless grant.permissions.include?("flights:read")

    server = MCP::Server.new(name: "flyweight", version: "1.0.0", tools: Mcp::Tools.build,
                             server_context: {pilot: grant.account, scopes: grant.permissions})
    transport = MCP::Server::Transports::StreamableHTTPTransport.new(
      server, stateless: true, enable_json_response: true,
      allowed_hosts: [URI(Mcp::Settings.issuer).host],
      allowed_origins: [Rails.application.config.urls.frontend], serve_subscriptions_listen: false
    )
    status, headers, body = transport.handle_request(request)
    response.status = status
    headers.each { |key, value| response.set_header(key, value) }
    self.response_body = body
  end

  private

  def require_enabled
    head :not_found unless Mcp::Settings.enabled?
  end

  def challenge(status, error)
    Rails.logger.info({event: "mcp.authorization", outcome: error}.to_json)
    response.set_header("WWW-Authenticate", %(Bearer error="#{error}", resource_metadata="#{Mcp::Settings.issuer}/.well-known/oauth-protected-resource/mcp", scope="flights:read"))
    render json: {error: error}, status: status
  end
end
