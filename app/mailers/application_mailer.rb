# frozen_string_literal: true

# @abstract
#
# The abstract superclass for all FlyWeight mailers.

class ApplicationMailer < ActionMailer::Base
  default from: "donotreply@flyweight.org"
  layout "mailer"
end
