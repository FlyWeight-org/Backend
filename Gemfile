# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.3.3"
gem "net-pop", github: "ruby/net-pop" # 3.3.3 hack fix

# CORE
gem "puma"
gem "rails"
gem "responders"

# FRAMEWORK
gem "devise"
gem "devise-jwt"
gem "rack-cors"
gem "redis"
gem "sidekiq"

# MODELS
gem "pg"

# VIEWS
gem "jbuilder"

# ERRORS
gem "bugsnag"

group :development do
  # ERRORS
  gem "binding_of_caller"

  # FLY.IO
  gem "dockerfile-rails"
end

group :doc do
  gem "redcarpet", require: nil
  gem "yard", require: nil
end

group :test do
  # SPECS
  gem "json_expressions", require: "json_expressions/rspec"
  gem "rails-controller-testing"
  gem "rspec-rails"

  # FACTORIES
  gem "factory_bot_rails"
  gem "ffaker"

  # ISOLATION
  gem "database_cleaner"
  gem "webmock"
end
