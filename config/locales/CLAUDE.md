# Localization — strings database

Rails I18n. Supported locales: `en` (base locale and fallback), `en-GB`,
`en-CA`, `en-AU`, `de-DE`, `fr-FR` (declared in `config/application.rb` via
`config.i18n.available_locales`, with `config.i18n.fallbacks = true`).

Whenever you add or change a user-facing string, localize it — never ship
hard-coded English. `en.yml` (and `responders.en.yml`) is the base locale;
mirror new keys into `de-DE.yml` and `fr-FR.yml`.

- The English variants (`en-GB`, `en-CA`, `en-AU`) can fall back to `en` if
  there are no locale-specific spelling or terminology differences.
- Request locale is negotiated in `ApplicationController#locale_from_request`:
  the frontend's `X-Locale` header first, then `Accept-Language`. Emails instead
  use the recipient pilot's stored locale (the `pilots.locale` column), applied
  via `I18n.with_locale` in `RodauthMailer`.
- Mailer bodies are ERB (`app/views/rodauth_mailer/`) that call `t(...)` — keep
  them translated, never hard-coded.
- Library-internal strings (e.g. Rodauth's built-in auth messages) are out of
  scope; we only localize strings we author.

## Translation quality

- Keep aviation/technical jargon in English unless there is a widely-used
  native equivalent — don't over-reach. When unsure, research real-world usage in
  the target locale before deciding.
- French weight term is split by audience: passenger-facing strings (e.g. the
  load weight attribute, shown when a passenger submits the public form) use
  **« poids »**; pilot-facing/technical strings use **« masse »**.
