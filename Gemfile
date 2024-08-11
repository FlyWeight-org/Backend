# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.3.4"

# CORE
gem "puma"
gem "rails"
gem "responders"

# FRAMEWORK
gem "devise"
gem "devise-jwt"
gem "kredis"
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
  # LINT
  gem "brakeman", require: false

  # ERRORS
  gem "binding_of_caller"

  # FLY.IO
  gem "dockerfile-rails"
end

group :doc do
  gem "redcarpet", require: false
  gem "yard", require: false
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
