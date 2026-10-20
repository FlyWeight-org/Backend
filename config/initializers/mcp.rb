# frozen_string_literal: true

# Reports MCP handler failures to Sentry without the request body or breadcrumbs, which carry tool arguments.
MCP.configure do |config|
  config.exception_reporter = ->(exception, _context) do
    Sentry.capture_exception(exception) do |scope|
      scope.set_rack_env(nil)
      scope.clear_breadcrumbs
    end
  end
end
