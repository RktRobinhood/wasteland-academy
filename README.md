# Wasteland Academy

IB Math AA SL gamified review tool. Post-apocalyptic roguelite. Static GitHub Pages PWA.

## Docs

- [`SPEC.md`](SPEC.md) — Full design specification
- [`ART_REQUIREMENTS.md`](ART_REQUIREMENTS.md) — Asset generation briefs
- [`CONTENT_SCHEMA.md`](CONTENT_SCHEMA.md) — Question format and subtopic map

## Structure

```
/
├── index.html          ← Entry point
├── manifest.json       ← PWA config
├── service-worker.js   ← Offline caching
├── css/                ← Design system and screen styles
├── js/                 ← Game engine modules
├── content/            ← Question packs (one file per topic)
└── assets/             ← Art assets (avatars, enemies, UI, maps)
```

## Tests

The site has no build step: Pages serves the files as they are. `package.json` holds test tooling only.

```
npm ci
npx playwright install chromium
npm test
```

- `tests/content/`: content validator (`node --test`). Known content defects are listed in `tests/content/known-defects.mjs` and show as TODO.
- `tests/e2e/`: Playwright. A full island fight on a phone screen, a small-phone layout check, and service-worker offline and update checks.

GitHub Actions runs `npm test` on every PR and on pushes to `main`.

## Status

Pre-production. Spec complete. Awaiting: art assets, engine build, content authoring.
