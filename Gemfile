# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby "3.2.1"

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
  gem "better_errors"
  gem "binding_of_caller"

  # DEPLOYMENT
  gem "bcrypt_pbkdf", require: false
  gem "bugsnag-capistrano", require: false
  gem "capistrano", require: false
  gem "capistrano-bundler", require: false
  gem "capistrano-git-with-submodules", require: false
  gem "capistrano-nvm", require: false
  gem "capistrano-rails", require: false
  gem "capistrano-rvm", require: false
  gem "capistrano-sidekiq", require: false
  gem "ed25519", require: false
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
  gem "timecop"
  gem "webmock"
end
