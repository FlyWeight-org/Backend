# frozen_string_literal: true

class RodauthMailer < ApplicationMailer
  def verify_account(email, link)
    @link = link
    mail(to: email, subject: I18n.t("rodauth_mailer.verify_account.subject"))
  end

  def reset_password(email, link)
    @link = link
    mail(to: email, subject: I18n.t("rodauth_mailer.reset_password.subject"))
  end
end
