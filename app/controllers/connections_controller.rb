# frozen_string_literal: true

# Lists and revokes the signed-in pilot's assistant connections.
class ConnectionsController < ApplicationController
  before_action :authenticate_pilot!

  # Returns live connections grouped by registered OAuth client.
  def index
    return render json: {enabled: false, connections: []} unless Mcp::Settings.enabled?

    connections = grants.live.includes(:oauth_application).order(:created_at).group_by(&:oauth_application).
        map { |application, rows| connection(application, rows) }
    render json: {enabled: true, connections: connections}
  end

  # Revokes every grant for this pilot and the selected client, including pending codes.
  def destroy
    selected = grants.where(oauth_application_id: params.expect(:id))
    raise ActiveRecord::RecordNotFound if selected.none?

    selected.update_all(revoked_at: Time.current)
    head :no_content
  end

  private

  def grants = OauthGrant.unrevoked.where(account_id: current_pilot.id)

  def connection(application, rows)
    {id: application.id, name: application.name, scopes: Mcp::Settings::SCOPES & rows.flat_map(&:permissions),
     created_at: rows.first.created_at, callback_host: callback_host(application)}
  end

  # Distinguishes registrations that share a client name, such as two local installs of one assistant.
  def callback_host(application)
    uri = URI(application.redirect_uri.split.first)
    loopback?(uri.hostname) ? "#{uri.host}:#{uri.port}" : uri.host.to_s
  end

  def loopback?(hostname)
    hostname == "localhost" || IPAddr.new(hostname).loopback?
  rescue IPAddr::InvalidAddressError
    false
  end
end
