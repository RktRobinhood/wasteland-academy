# Wasteland Academy

IB Math AA SL gamified review tool. Post-apocalyptic roguelite. Static GitHub Pages PWA.

## Docs

- [`SPEC.md`](SPEC.md) — Full design specification
- [`ROADMAP.md`](ROADMAP.md) — Order of work and target dates
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

The site has no build step: Pages serves the files as they are. `package.json` holds test tooling only.

```
npm ci
npx playwright install chromium
npm test
```

- `tests/content/`: content validator (`node --test`). Known content defects are listed in `tests/content/known-defects.mjs` and show as TODO.
- `tests/unit/`: unit checks (`node --test`): question generator, spaced repetition, save migrations, and the offline rules above (no remote URLs, everything precached, vendored KaTeX matches `katex@0.16.9`).
- `tests/e2e/`: Playwright. A full island fight on a phone screen, a small-phone layout check, service-worker checks (a full fight with the network off, and updates), save export/import, and the install button and iOS tip.

GitHub Actions runs `npm test` on every PR and on pushes to `main`.

## Status

Pre-production. Spec complete. Awaiting: art assets, engine build, content authoring.
