# frozen_string_literal: true

class RodauthMailer < ApplicationMailer
  def verify_account(email, link)
    @link = link
    mail(to: email, subject: "Verify your FlyWeight account")
  end

  def reset_password(email, link)
    @link = link
    mail(to: email, subject: "Reset your FlyWeight password")
  end
end
