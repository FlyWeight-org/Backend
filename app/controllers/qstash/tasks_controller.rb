# frozen_string_literal: true

module Qstash
  # Endpoints invoked by QStash schedules. Each action is idempotent so that
  # QStash retries on 5xx are safe. Authentication is handled entirely by the
  # Upstash-Signature JWT — no session or CSRF token is involved.

  class TasksController < ActionController::API
    include VerifyQstashSignature

    # Deletes flights whose date is more than one week in the past.
    def purge_stale_flights
      Flight.where(date: ...1.week.ago.to_date).destroy_all
      head :no_content
    end
  end
end
