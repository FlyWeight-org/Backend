# frozen_string_literal: true

Rack::Attack.cache.store =
    if ENV["REDIS_URL"].present?
      ActiveSupport::Cache::RedisCacheStore.new(url: ENV.fetch("REDIS_URL"))
    else
      ActiveSupport::Cache::MemoryStore.new
    end

Rack::Attack.throttle("signup/ip/hour", limit: 3, period: 1.hour) do |req|
  req.ip if req.path == "/signup" && req.post?
end

Rack::Attack.throttle("signup/ip/day", limit: 10, period: 1.day) do |req|
  req.ip if req.path == "/signup" && req.post?
end

Rack::Attack.throttle("login/ip", limit: 10, period: 5.minutes) do |req|
  req.ip if req.path == "/login" && req.post?
end

Rack::Attack.throttle("password-resets/ip", limit: 3, period: 1.hour) do |req|
  req.ip if req.path == "/password-resets" && req.post?
end

Rack::Attack.throttle("verify-account/ip", limit: 10, period: 1.hour) do |req|
  req.ip if req.path == "/verify-account" && req.post?
end

Rack::Attack.throttle("oauth-registration/ip", limit: 60, period: 1.hour) do |req|
  req.ip if req.path == "/oauth/register" && req.post?
end

# Identifies OAuth and MCP callers by credential, so one noisy shared address
# doesn't throttle every assistant host behind it.
class Rack::Attack::Request
  # @return [Boolean] Whether this request exchanges or refreshes an OAuth token.
  def oauth_token? = path == "/oauth/token" && post?

  # @return [Boolean] Whether this request calls the MCP endpoint.
  def mcp? = path == "/mcp" && post?

  # @return [String, nil] The client ID from the form body or HTTP Basic credentials.
  def oauth_client_id
    basic = Rack::Auth::Basic::Request.new(env)
    (basic.provided? && basic.basic? && basic.username.presence) || params["client_id"].presence
  end

  # @return [String, nil] A digest of the bearer token, so tokens never reach the cache store.
  def bearer_digest
    token = get_header("HTTP_AUTHORIZATION").to_s[/\ABearer (\S+)\z/, 1]
    Digest::SHA256.hexdigest(token) if token
  end
end

Rack::Attack.throttle("oauth-token/client", limit: 300, period: 1.minute) do |req|
  req.oauth_client_id if req.oauth_token?
end

Rack::Attack.throttle("oauth-token/ip", limit: 300, period: 1.minute) do |req|
  req.ip if req.oauth_token? && !req.oauth_client_id
end

Rack::Attack.throttle("mcp/token", limit: 600, period: 1.minute) do |req|
  req.bearer_digest if req.mcp?
end

Rack::Attack.throttle("mcp/ip", limit: 600, period: 1.minute) do |req|
  req.ip if req.mcp? && !req.bearer_digest
end

Rack::Attack.throttle("oauth-token/ip/backstop", limit: 600, period: 1.minute) do |req|
  req.ip if req.oauth_token?
end

Rack::Attack.throttle("mcp/ip/backstop", limit: 1200, period: 1.minute) do |req|
  req.ip if req.mcp?
end

Rack::Attack.throttled_responder = ->(request) do
  retry_after = (request.env["rack.attack.match_data"] || {})[:period].to_i
  [429, {"Content-Type" => "application/json", "Retry-After" => retry_after.to_s}, [{error: "Too many requests"}.to_json]]
end
