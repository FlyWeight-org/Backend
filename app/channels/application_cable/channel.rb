# frozen_string_literal: true

module ApplicationCable

  # The main Action Cable channel for FlyWeight.

  class Channel < ActionCable::Channel::Base

    # Broadcasts like `broadcast_to`, but reports pub/sub failures to Sentry
    # instead of raising, so a lost live update never fails the committed
    # write that triggered it.
    #
    # @param [ActiveRecord::Base] model The model whose stream to broadcast to.
    # @param [String] message The encoded message.

    def self.broadcast_safely_to(model, message)
      broadcast_to model, message
    rescue Redis::BaseError => e
      Sentry.capture_exception e
    end
  end
end
