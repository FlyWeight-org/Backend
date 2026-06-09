# frozen_string_literal: true

class RodauthMailer < ApplicationMailer
  def verify_account(email, link, locale=nil)
    @link = link
    I18n.with_locale(locale.presence || I18n.default_locale) do
      mail(to: email, subject: I18n.t("rodauth_mailer.verify_account.subject"))
    end
  end

  def reset_password(email, link, locale=nil)
    @link = link
    I18n.with_locale(locale.presence || I18n.default_locale) do
      mail(to: email, subject: I18n.t("rodauth_mailer.reset_password.subject"))
    end
  end
end
