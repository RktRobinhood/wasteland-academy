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

## Status

Pre-production. Spec complete. Awaiting: art assets, engine build, content authoring.
