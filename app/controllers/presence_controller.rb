# frozen_string_literal: true

# Lightweight warm-up endpoint. The Frontend pings GET /presence on auth-page
# mount so the Fly machine and the Postgres pool are already warm by the time
# the user clicks submit. The work happens in the middleware stack:
# VerifyDatabaseConnection skips /up but not /presence, so a hit here exercises
# the pooled connection — letting AR detect dead sockets and reconnect
# transparently.
#
# Distinct from /up (rails/health#show), which Fly's health checker hits and
# which is intentionally exempted from VerifyDatabaseConnection to avoid
# adding DB work to every health probe.

class PresenceController < ApplicationController

  def show
    head :ok
  end

end
