# Connect an assistant to FlyWeight

FlyWeight's hosted MCP endpoint lets a pilot authorize an assistant to manage
that pilot's flights and passenger/cargo loads. It uses the same records,
validations, and realtime broadcasts as the website.

## Enable the integration

1. Install the backend dependencies and run `bin/rails db:migrate`.
2. Deploy the companion frontend, which includes `/connect` and account connection
   management.
3. Set `MCP_ENABLED=1` on the backend and restart it. The default is disabled.
4. Verify the public HTTPS endpoint and the OAuth flow before announcing it.

The production endpoint is `https://app.flyweight.org/mcp`. Discovery is served at
`/.well-known/oauth-authorization-server` and
`/.well-known/oauth-protected-resource/mcp`. Addresses come from `config/urls.yml`.
Keep the configured frontend and backend URLs consistent with their public hosts.
No additional application secret is required; assistant tokens are random,
separate from browser JWTs, and stored as hashes.

Setting `MCP_ENABLED` back to an unset value or `0` disables MCP, authorization,
and registration. Existing grants remain stored and can still be revoked through
the account API; disabling the flag does not erase them.

## Connect ChatGPT or Claude

Add the MCP URL as a custom remote connection in the assistant's settings and
choose OAuth with dynamic client registration. In Claude, choose **Register
automatically**. FlyWeight supports public clients and confidential clients using
`client_secret_basic` or `client_secret_post`; registration returns the applicable
credentials. Client ID Metadata Documents are not advertised.

The assistant opens FlyWeight. Sign in with the existing password or passkey flow,
review the client name, callback address, account, and permissions, then allow or
deny access. The assistant receives OAuth credentials, never the pilot's password
or browser login token. Custom-connection availability depends on the host's
account and workspace settings.

A connection requests `flights:read`, plus `flights:write` for changes. Write
permission includes deleting flights and loads. Revocation is available under
**My Account → Connected assistants** and immediately invalidates that pilot's
grants for the selected client. Revocation and flight purging cannot remove data
already returned to an assistant.

## Tools and data

| Tool | Arguments | Result |
| --- | --- | --- |
| `list_flights` | Optional `page` (default 1), `limit` (default 25, maximum 100) | Summaries and `next_page` |
| `get_flight` | `flight_id` | Flight, loads, totals, unit, invitation URL |
| `create_flight` | `date`, optional `description` | Created flight |
| `update_flight` | `flight_id`, optional `date` and `description` | Updated flight |
| `delete_flight` | `flight_id` | Deletion acknowledgment |
| `upsert_load` | `flight_id`, `name`, `weight`, `bags_weight`, `unit` | Updated flight |
| `delete_load` | `flight_id`, `slug` | Deletion acknowledgment |

Dates use `YYYY-MM-DD`. Flight identifiers are UUIDs. Load slugs come from
`get_flight`; upserting uses the same name-derived matching as the website and
replaces both weights. Cargo uses `weight: 0` and a positive `bags_weight`.

Weight writes require `unit: "lb"` or `unit: "kg"`. Storage remains pounds rounded
to two decimal places. Responses use the pilot's preferred unit, label it
explicitly, and include passenger, baggage/cargo, and combined weight totals.
These totals do not calculate aircraft balance or determine flight safety.

Invitations are returned as links; tools do not send messages. The integration
does not expose account management, administrator access, passenger login,
vaccination data, or deleted flights. Existing scheduled purging remains in effect.
Tool annotations describe read-only and destructive behavior; actual access is
enforced by the server regardless of client confirmation settings.

## Authorization and operations

Authorization requires S256 PKCE, exact registered callback matching, and a
`resource` parameter equal to the MCP URL during authorization and token exchange.
Callbacks require HTTPS, except for HTTP loopback addresses.
Access tokens expire after 15 minutes. Refresh tokens rotate and expire after
30 days without refresh. Reusing a consumed refresh token revokes its grant. Grants are tied to an open pilot account and checked on
every MCP request. The transport is stateless and uses JSON responses, so it does
not require sticky sessions or a separate deployment.

Registration is limited to 60 requests per IP per hour; token requests to 300 per
IP per minute; MCP calls to 600 per IP per minute. Throttling returns HTTP 429 with
`Retry-After`. Review these limits if assistant hosts' shared egress addresses
cause throttling. Production uses the existing shared Redis rate-limit store.

Logs record `mcp.tool` events (tool, outcome, duration) and `mcp.authorization`
failures without tool arguments, passenger weights, or bearer tokens. Monitor
these events and the existing service health/error reporting.

## Verification and troubleshooting

Run the Rails suite with `bundle exec rspec spec`, `rubocop`,
`bin/brakeman --no-pager`, and `RAILS_ENV=test bin/rails zeitwerk:check`.
The frontend uses `pnpm lint`, `pnpm build`, `CI=true pnpm test:unit`, and
`pnpm test:e2e e2e/connections.spec.ts`. The browser test expects the existing
Cypress backend at port 5000 with `MCP_ENABLED=1` and an isolated test database.

Use MCP Inspector's HTTP transport to initialize, list tools, and exercise a
throwaway flight. Complete a hosted-client acceptance check in both ChatGPT and
Claude before production rollout: connect, read, create a flight, add and replace
a load, delete the disposable flight, refresh, and revoke access. Local automated
tests do not establish that a deployed host connection works.

- **404:** Check `MCP_ENABLED` and deployment order.
- **401:** Reconnect if the grant expired, was revoked, or its account closed.
- **Insufficient scope:** Reconnect with permission to manage flights.
- **Consent error:** Restart connection from the assistant; check callback,
  resource, and PKCE parameters.
- **403 from transport:** Check the public Host and any browser Origin against
  the configured URLs. Server-to-server MCP calls do not need an Origin header.
