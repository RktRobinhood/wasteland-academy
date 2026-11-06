# Telemetry collector

A Cloudflare Worker and a D1 database that take anonymous event batches from the
Godot game and store them for the weekly outlier report. The design is the `plan`
document on FAL-379. This is FAL-406 ("Telemetry B"). The game's recorder is FAL-405
and the report is FAL-407.

It isn't deployed. Deploying waits for Matt's Cloudflare account (see "Deploying").

## Files

| File | What it is |
|---|---|
| `schema.json` | The allowlist: every event name and field the collector keeps. The game's recorder (FAL-405) tests its own field list against this file. |
| `src/index.ts` | The Worker: `POST /v1/events` and the daily retention job |
| `src/schema.ts` | Checks an event against `schema.json` |
| `src/rate-limit.ts` | The per-session rate limit |
| `migrations/0001_events.sql` | The D1 `events` table and its indexes |
| `wrangler.toml` | Worker config: D1 binding, allowed origin, rate limit, cron |
| `test/collector.test.ts` | Tests, run inside Cloudflare's runtime (Miniflare) with vitest |

## Tests

```
cd services/telemetry
npm ci
npm test            # vitest in workerd, with a local D1
npm run typecheck
```

The tests check that the collector accepts a valid batch; drops unknown fields; rejects
unknown events, more than 50 events or more than 32 KB (413), and other origins (403);
rate-limits a session (429); stores no IP and logs nothing; and that the retention job
deletes rows older than 12 months. GitHub Actions runs them in the `telemetry` job.

`npm run dev` starts the Worker locally with `wrangler dev` and a local D1. Apply the
table first with `npx wrangler d1 migrations apply wasteland-telemetry --local`.

## The API

`POST /v1/events`, with a JSON body (sent as `application/json` or `text/plain`, so
`navigator.sendBeacon` works):

```json
{
  "schema": 1,
  "events": [
    {
      "event": "answer_checked",
      "session_id": "3f9c0d1e2a4b5c6d7e8f90a1b2c3d4e5",
      "game_version": "0.4.1",
      "seq": 12,
      "arms": { "hint-wording": "new" },
      "view_id": "fn-quadratic-features/vertex-from-general/equation/complete-square/value",
      "seed": 3,
      "correct": false,
      "attempt": 1,
      "seconds": 41.5,
      "misconception": "sign-of-h"
    }
  ]
}
```

- `schema` must equal `version` in `schema.json`.
- Every event carries the envelope fields: `event`, `session_id` (32 lowercase hex
  characters, random per launch, kept in memory only), `game_version`, and optionally
  `seq` (the event's order in its session) and `arms` (experiment name to arm).
- All events in one batch share one `session_id`.
- The `Origin` header must be `https://rktrobinhood.github.io`. Browsers set it. A
  desktop or mobile build has to send that header itself.

| Status | Meaning | The game should |
|---|---|---|
| 202 | Stored. The body is `{accepted, rejected: [{index, reason}]}`; rejected events had an unknown name or a missing or invalid required field. | drop the batch |
| 400 | Nothing stored: bad JSON, wrong `schema`, mixed sessions, or every event rejected | drop the batch |
| 403 | Wrong or missing `Origin` | drop the batch |
| 413 | Over 50 events or 32 KB | split it and resend |
| 429 | Over 30 requests a minute for this session (`Retry-After: 60`) | retry later |
| 503 | D1 unavailable (`Retry-After: 60`) | retry later |

The rate limit is counted in each Worker instance's memory, keyed by session ID. It
stops a runaway client, not a determined one. Cloudflare's own rate limiting would key
on the IP, which this collector never reads.

## What is stored

One row per accepted event in `events`: `received_at` (UTC, to the second),
`session_id`, `seq`, `event`, `view_id`, `seed`, `fields` (JSON: the event's other
allowlisted fields), `game_version`, `arms` (JSON). Digits in error messages become `#`.

Never stored: the IP or any forwarding header, Cloudflare's location data, names,
accounts, emails, class codes, typed answers, or any ID that outlives a session.
The Worker writes no logs, and `wrangler.toml` turns Workers Logs off, because they
record request headers.

Raw rows are deleted 12 months after `received_at` by a cron trigger daily at 03:15 UTC.

## Changing the allowlist

Edit `schema.json`, then update the game's recorder to match (its test fails until you
do). For a change the old game can't follow, such as renaming a field, bump `version`:
the collector then answers 400 to the old version, so ship both together. Adding an
optional field or a new event doesn't need a bump.

## Deploying

Not done yet. It needs:

1. A free Cloudflare account (Matt).
2. An API token with Workers Scripts edit and D1 edit rights, saved as the Paperclip
   secret `CLOUDFLARE_API_TOKEN`, and the account ID saved as `CLOUDFLARE_ACCOUNT_ID`.

Then, from `services/telemetry` with both set in the environment:

```
npm ci

# 1. Make the database in the EU jurisdiction. The jurisdiction is fixed at creation
#    and can't be set in wrangler.toml, so this step has to come first.
npx wrangler d1 create wasteland-telemetry --jurisdiction eu

# 2. Paste the database_id it prints into wrangler.toml, replacing the placeholder.
#    Deploying with the placeholder fails, because no database has that ID, so a
#    deploy can't quietly make a database outside the EU. Commit that change.

# 3. Make the table
npx wrangler d1 migrations apply wasteland-telemetry --remote

# 4. Deploy the Worker and its cron trigger
npx wrangler deploy
```

`wrangler deploy` prints the Worker's URL, such as
`https://wasteland-telemetry.<account>.workers.dev`. The game's endpoint setting
(`falcon/telemetry/endpoint`, FAL-405) is that URL plus `/v1/events`.

Check it:

```
curl -i -X POST https://wasteland-telemetry.<account>.workers.dev/v1/events \
  -H 'Origin: https://rktrobinhood.github.io' -H 'Content-Type: application/json' \
  -d '{"schema":1,"events":[{"event":"session_end","session_id":"00000000000000000000000000000000","game_version":"deploy-check","answered":0}]}'
# expect 202 and {"accepted":1,"rejected":[]}

npx wrangler d1 execute wasteland-telemetry --remote \
  --command "DELETE FROM events WHERE game_version = 'deploy-check'"
```

To export events for the report (FAL-407):

```
npx wrangler d1 execute wasteland-telemetry --remote --json \
  --command "SELECT * FROM events WHERE received_at >= '2026-10-22'" > events.json
```
