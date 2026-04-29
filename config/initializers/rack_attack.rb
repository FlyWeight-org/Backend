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

Rack::Attack.throttled_responder = lambda do |request|
  retry_after = (request.env["rack.attack.match_data"] || {})[:period].to_i
  [429, {"Content-Type" => "application/json", "Retry-After" => retry_after.to_s}, [{error: "Too many requests"}.to_json]]
end
