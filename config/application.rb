# frozen_string_literal: true

require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
# require "action_view/railtie"
require "action_cable/engine"
# require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Flyweight
  class Application < Rails::Application
    # Use the responders controller from the responders gem
    config.app_generators.scaffold_controller :responders_controller

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.

    config.time_zone                      = "UTC"
    config.active_record.default_timezone = :utc
    # config.eager_load_paths << Rails.root.join("extras")

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    # Use a real queuing backend for Active Job (and separate queues per environment).
    config.active_job.queue_adapter     = :sidekiq
    config.active_job.queue_name_prefix = "flyweight_#{Rails.env}"

    config.generators do |g|
      g.test_framework :rspec, fixture: true, views: false
      g.integration_tool :rspec
      g.fixture_replacement :factory_bot, dir: "spec/factories"
    end

    config.urls = config_for(:urls)

    config.action_cable.url                     = config.urls.cable
    config.action_cable.allowed_request_origins = [config.urls.frontend]

    backend                                      = URI.parse(Rails.application.config.urls.backend)
    Rails.application.routes.default_url_options = {
        host:     backend.host,
        port:     backend.port,
        protocol: backend.scheme
    }
  end
end
