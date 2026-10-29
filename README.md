# Wasteland Academy

IB Math AA SL gamified review tool. Post-apocalyptic roguelite. Static GitHub Pages PWA.

## Docs

- [`SPEC.md`](SPEC.md) — Full design specification
- [`ROADMAP.md`](ROADMAP.md) — Order of work and target dates
- [`TONE.md`](TONE.md) — Who the game is for, and the undertone under the writing and art
- [`ART_REQUIREMENTS.md`](ART_REQUIREMENTS.md) — Asset generation briefs
- [`CONTENT_SCHEMA.md`](CONTENT_SCHEMA.md) — Question format and subtopic map

## Structure

```
/
├── index.html          ← Entry point
├── manifest.json       ← PWA config
├── service-worker.js   ← Offline caching
├── css/                ← Design system and screen styles
├── js/                 ← Game engine modules (js/platform.js is the only file that touches browser storage, links and files)
├── content/            ← Question packs (one file per topic)
├── vendor/             ← KaTeX and the two fonts, copied in (see vendor/LICENSES.md)
├── game/               ← Godot 4.7.2 version, published at /next/ (see game/README.md)
└── assets/             ← Art assets (avatars, enemies, UI, maps)
```

## Offline and app builds

Every file the game loads is in this repo, all linked by relative path, so a
phone never contacts another host and the game plays fully offline after one
visit. A test fails if a remote or root-absolute URL creeps into `index.html`,
`manifest.json`, `service-worker.js`, `js/` or `css/`. The one exception is the
GitHub link for student reports, in `js/platform.js`.

A store app (e.g. Capacitor) can ship the same files. It only needs its own
`js/platform.js`, with the same calls for storage, opening a link, and saving
or loading a file.

## Saves

The save lives in browser storage under `wa_save`, with a format `version`.
When the format changes, add a step to `WA.MIGRATIONS` in `js/engine.js` and bump
`WA.VERSION`; old saves are brought up to date, never wiped. A save that can't be
read is kept aside under `wa_save_unreadable_<time>` instead of being overwritten.
Players can export and import their save from the Stats screen.

## Tests

The HTML game has no build step: Pages publishes its files as they are. `package.json` holds test tooling only.

```
npm ci
npx playwright install chromium
npm test
```

- `tests/content/`: content validator (`node --test`). Known content defects are listed in `tests/content/known-defects.mjs` and show as TODO.
- `tests/unit/`: unit checks (`node --test`): question generator, spaced repetition, save migrations, and the offline rules above (no remote URLs, everything precached, vendored KaTeX matches `katex@0.16.9`).
- `tests/e2e/`: Playwright. A full island fight on a phone screen, a small-phone layout check, service-worker checks (a full fight with the network off, and updates), save export/import, and the install button and iOS tip.

GitHub Actions runs `npm test` on every PR and on pushes to `main`.
`tests/unit/service-worker.test.mjs` checks the service worker leaves `next/` and
`classic/` alone, and `tests/unit/takeover.test.mjs` checks the takeover switch (see
"Switching to Godot").

## Godot version (`game/`)

The Godot 4.7.2 rebuild lives in `game/` and is published at `/next/`, beside this
HTML game. See [`game/README.md`](game/README.md) for how to run, test, export,
screenshot it and use the Godot MCP. In short: `./test.sh`, `./export.sh`, `./run.sh`.
`.github/workflows/pages.yml` publishes the site and the export on every push to `main`.

## Switching to Godot

One switch decides which game is at the main address: the repository variable
`GODOT_AT_ROOT`, which `.github/workflows/pages.yml` reads. Unset counts as off.

| Switch | `/` | `/classic/` | `/next/` |
|---|---|---|---|
| `off` | the HTML game | not published | Godot |
| `on` | Godot | the HTML game | sends people to `/`, keeping the `?…` and `#…` |

**Turn it on:**

```
gh variable set GODOT_AT_ROOT --body on -R RktRobinhood/wasteland-academy
gh workflow run pages.yml --ref main -R RktRobinhood/wasteland-academy
```

Or set it in Settings > Secrets and variables > Actions > Variables, then run the
`pages` workflow from the Actions tab. The deploy takes a few minutes.

**Check it** (`tools/takeover-dry-run` checks the same on a local copy, after
`./export.sh`, and CI runs it on every PR):

- `https://rktrobinhood.github.io/wasteland-academy/` shows the Godot title screen,
  with a small "Classic game" link in the bottom right corner.
- `/classic/` shows the HTML game, with "NEW VERSION ▸" on the world screen.
- `/next/#functions/quadratics` opens the Quadratics region, at `/#functions/quadratics`.
- In a browser that played the old game, `/` shows Godot. The page reloads once.

**Turn it off:** set the variable to `off` (or delete it) and run `pages` again. The
site goes back to the HTML game at `/` and Godot at `/next/`. Links to `/classic/` stop
working, and Godot links such as `/#functions/quadratics` open the HTML game.

What the switch changes, in `scripts/assemble-site.sh`:

- The HTML game's files move into `classic/` as they are. Every path in it is relative,
  so its routes work there unchanged, and its service worker registers with scope
  `classic/`.
- The root `service-worker.js` becomes `_takeover/service-worker.js`. A browser that
  ran the old game at `/` fetches it as that worker's update. It deletes the old game's
  cached files (keeping `classic/`'s), unregisters, and reloads the page.
- `next/index.html` becomes `_takeover/next.html`, the redirect.
- Godot's `index.html` gets `<meta name="wa-classic" content="classic/">`, which shows
  its "Classic game" link. The HTML game shows "NEW VERSION ▸" when it runs from
  `classic/`.

Jekyll skips `_takeover/`, so with the switch off none of it is published.

**Saves.** Both games are on one origin, and neither reads or deletes the other's:

- HTML game: `localStorage` keys `wa_save`, `wa_save_unreadable_<time>` and
  `wa_ios_install_tip_seen`, and the Cache Storage cache `wasteland-academy-v3`.
- Godot: `user://save.json` and `user://settings.cfg`, in the IndexedDB database
  `/userfs`. It doesn't use `localStorage`.

Storage belongs to the origin, not the path, so a Godot save made at `/next/` is there
at `/`, and an HTML game save made at `/` is there at `/classic/`.

## Status

Pre-production. Spec complete. Awaiting: art assets, engine build, content authoring.
