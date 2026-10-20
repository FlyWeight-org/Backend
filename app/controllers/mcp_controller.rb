# frozen_string_literal: true

# Serves the stateless, pilot-scoped MCP endpoint and resource discovery.
class McpController < ApplicationController
  before_action :require_enabled
  before_action :disable_caching, :require_grant, :require_scopes, only: :handle

  # Advertises the canonical resource and its OAuth authorization server.
  def metadata
    render json: {resource: Mcp::Settings.resource, authorization_servers: [Mcp::Settings.issuer],
                  scopes_supported: Mcp::Settings::SCOPES, bearer_methods_supported: %w[header]}
  end

  # Dispatches an authorized request through the SDK transport.
  def handle
    respond_with_rack mcp_transport(mcp_server).handle_request(request)
  end

  private

  def require_enabled
    head :not_found unless Mcp::Settings.enabled?
  end

  def disable_caching
    response.set_header("Cache-Control", "no-store")
  end

  def require_grant
    challenge(:invalid_token_response, "invalid_token") unless authenticated_grant
  end

  # Answers a token lacking a called tool's scope with a step-up challenge.
  def require_scopes
    challenge(:insufficient_scope_response, "insufficient_scope") unless (required_scopes - authenticated_grant.permissions).empty?
  end

  def authenticated_grant
    @authenticated_grant ||= OauthGrant.authenticate(rodauth)
  end

  def required_scopes
    called = called_tool_names
    tools.select { called.include?(it.name_value) }.map { Mcp::Tools.required_scope(it) } | [Mcp::Settings::READ_SCOPE]
  end

  def called_tool_names
    jsonrpc_messages.filter_map do |message|
      case message
        in {method: "tools/call", params: {name: String => name}} then name
        else nil
      end
    end
  end

  def jsonrpc_messages
    Array.wrap(JSON.parse(request.raw_post, symbolize_names: true)).grep(Hash)
  rescue JSON::ParserError
    []
  end

  def tools = @tools ||= Mcp::Tools.build

  def mcp_server
    MCP::Server.new(name: "flyweight", version: "1.0.0", tools: tools,
                    server_context: {pilot: authenticated_grant.account, scopes: authenticated_grant.permissions})
  end

  def mcp_transport(server)
    MCP::Server::Transports::StreamableHTTPTransport.new(
      server, stateless: true, enable_json_response: true,
      allowed_hosts: [URI(Mcp::Settings.issuer).host],
      allowed_origins: [Rails.application.config.urls.frontend], serve_subscriptions_listen: false
    )
  end

  def challenge(builder, error)
    Rails.logger.info({event: "mcp.authorization", outcome: error}.to_json)
    respond_with_rack MCP::Server::OAuth::Challenge.public_send(
      builder, scope: Mcp::Settings::SCOPES.join(" "), resource_metadata: Mcp::Settings.resource_metadata_url
    )
  end

  def respond_with_rack((status, headers, body))
    response.status = status
    headers.each { |key, value| response.set_header(key, value) }
    self.response_body = body
  end
end
