# frozen_string_literal: true

# RESTful controller for viewing and managing the current Pilot's account.

class AccountsController < ApplicationController
  before_action :authenticate_pilot!

  # GET /account
  def show
    render json: account_json(current_pilot)
  end

  # PUT/PATCH /account
  def update
    if current_pilot.update(account_params)
      render json: account_json(current_pilot)
    else
      render json: {errors: current_pilot.errors}, status: :unprocessable_content
    end
  end

  # DELETE /account
  def destroy
    current_pilot.destroy
    head :no_content
  end

  private

  def account_params
    params.expect(pilot: %i[name email])
  end

  def account_json(pilot)
    {
        name:     pilot.name,
        email:    pilot.email,
        passkeys: pilot.webauthn_keys.order(:last_use).map do |k|
          {id: k.webauthn_id, label: k.label, last_used_at: k.last_use}
        end
    }
  end
end
