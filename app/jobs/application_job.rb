# frozen_string_literal: true

# @abstract
#
# The abstract superclass for all FlyWeight jobs.

class ApplicationJob < ActiveJob::Base
  retry_on ActiveRecord::Deadlocked
  discard_on ActiveJob::DeserializationError
end
