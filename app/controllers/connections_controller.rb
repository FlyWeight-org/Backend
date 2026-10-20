# frozen_string_literal: true

# Lists and revokes the signed-in pilot's assistant connections.
class ConnectionsController < ApplicationController
  before_action :authenticate_pilot!

  # Returns connections grouped by registered OAuth client.
  def index
    return render json: {enabled: false, connections: []} unless Mcp::Settings.enabled?

    connections = grants.includes(:oauth_application).order(:created_at).group_by(&:oauth_application_id).map do |id, rows|
      {id: id, name: rows.first.oauth_application.name, scopes: rows.flat_map(&:permissions).uniq,
       created_at: rows.first.created_at}
    end
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
end
