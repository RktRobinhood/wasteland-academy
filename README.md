# Wasteland Academy

A post-apocalyptic roguelite for IB mathematics revision, built in Godot 4.7.2. It covers all of Analysis and Approaches SL, and most of the maths that AA HL, AI SL and AI HL share with it. Students play it in the browser at <https://rktrobinhood.github.io/wasteland-academy/>, on a phone or a laptop.

The product is an app for PC, Android and iOS. PC comes first, after the web build is ready for a class (#199). GitHub Pages stays the testing host.

Wasteland Academy is one presentation of a reusable IB mathematics engine. The same question generation, marking, worked solutions and curriculum selection should also support more academic interfaces. The game is the current product; a separate academic interface is future work.

The [Math-AA question bank](https://github.com/RktRobinhood/Math-AA---Question-Bank) stays in its own repository. Its exam metadata already informs the question-type catalogue; planned higher-level and other-course additions should expand that coverage and improve generated questions and filtering. See the [engine direction](SPEC.md#reusable-mathematics-engine-direction), [bank integration plan](curriculum/README.md#question-bank-integration-direction) and [implementation follow-up #134](https://github.com/RktRobinhood/wasteland-academy/issues/134).

## For teachers

- [`TEACHERS.md`](TEACHERS.md): what each course can play, what the game doesn't train, how typed answers are marked, and where progress is kept.
- [`PRIVACY.md`](PRIVACY.md): what the game stores and sends.

## Docs

- [`SPEC.md`](SPEC.md): the design specification
- [`ROADMAP.md`](ROADMAP.md): the order of work and the milestones
- [`TONE.md`](TONE.md): who the game is for, and the undertone under the writing and art
- [`game/README.md`](game/README.md): the Godot game: layout, running, testing, export, combat, the map, art slots
- [`game/docs/QUESTION-ENGINE.md`](game/docs/QUESTION-ENGINE.md): the question engine reference
- [`game/docs/MATHS-ENGINE.md`](game/docs/MATHS-ENGINE.md): the reusable maths interface
- [`curriculum/README.md`](curriculum/README.md): the curriculum maps and the question-type catalogue; [`curriculum/COVERAGE.md`](curriculum/COVERAGE.md) is what each course can play
- [`writing/glossary.md`](writing/glossary.md): every game term a player reads, and the one wording for it
- [`ART_REQUIREMENTS.md`](ART_REQUIREMENTS.md): asset generation briefs
- [`CONTENT_SCHEMA.md`](CONTENT_SCHEMA.md): legacy, the HTML game's question packs

## Structure

```
/
├── game/               ← the Godot game (see game/README.md)
├── curriculum/         ← curriculum maps, the question-type catalogue, generated reports
├── tools/              ← answer checker, seed sweep, course audit, explainer clips, generators
├── writing/            ← glossary, voice sheets, encounters, explainer scripts
├── assets/             ← source art, audio and their credits
├── scripts/            ← site assembly, CI helpers, screenshots, the Godot MCP
├── _takeover/          ← the root service worker and redirects for the Godot site
├── services/telemetry/ ← an anonymous telemetry collector, not deployed (#133)
├── tests/              ← Node unit tests, and Playwright tests for the site and the HTML game
└── index.html, js/, css/, content/, vendor/, manifest.json, service-worker.js
                        ← the legacy HTML game, published at /classic/ (see below)
```

## Run, test and export

```
./run.sh        # the game in a 540x960 window
./test.sh       # every Godot test, headless
./export.sh     # the web export, into build/next/
```

Godot is found on `PATH`, at `~/.local/bin/godot`, or from `GODOT=/path/to/godot`. The node tests need `npm ci` first. `game/README.md` has the rest, including screenshots and the Godot MCP.

GitHub Actions (`.github/workflows/test.yml`) runs nine jobs on every PR and on pushes to `main`:

- `godot`: `./test.sh`.
- `web`: the export, booted in headless Chromium at phone and PC sizes, with screenshots.
- `answers-shard` and `answers`: the SymPy answer checker in six shards, then merged.
- `stress`: the seed sweep, in twelve shards.
- `feedback`: what a student reads after each wrong option (`tools/feedback-check`).
- `takeover`: the site laid out as Pages publishes it, checked in a browser (`tools/takeover-dry-run`).
- `test`: `npm test`, the Node unit tests, the content validator and the HTML game's Playwright tests, plus the telemetry report's tests.
- `telemetry`: type-check and tests for the collector in `services/telemetry/`.

`.github/workflows/pages.yml` publishes the site on every push to `main`.

## Saves

The Godot game keeps progress in `user://save.json` and its settings in `user://settings.cfg`. On the web that is the browser's IndexedDB database `/userfs`, so progress belongs to one browser on one device. There is no account and no sync. Export and import are planned (#185); sync between devices is for later (#202).

## Switching to Godot

This switch is for the site's maintainers. It has been on since November 4, and #197 decides what stays at `/classic/`.

One switch decides which game is at the main address: the repository variable
`GODOT_AT_ROOT`, which `.github/workflows/pages.yml` reads. Unset counts as off. It
has been on since November 4, 2026 (FAL-721).

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
- After one visit, `/` plays offline.

**Turn it off:** set the variable to `off` (or delete it) and run `pages` again. The
site goes back to the HTML game at `/` and Godot at `/next/`. Links to `/classic/` stop
working, and Godot links such as `/#functions/quadratics` open the HTML game.

What the switch changes, in `scripts/assemble-site.sh`:

- The HTML game's files move into `classic/` as they are. Every path in it is relative,
  so its routes work there unchanged, and its service worker registers with scope
  `classic/`.
- The root `service-worker.js` becomes `_takeover/service-worker.js`, and Godot's
  `index.html` registers it (`_takeover/register-worker.html`). It keeps a copy of the
  export in the cache `wasteland-academy-godot`, so Godot plays offline after one visit.
  Each file is network-first and revalidated, so a player who is online always gets
  the latest deploy. A browser that ran the old game at `/` fetches the worker as that
  game's worker's update: it deletes the old game's cached files (keeping
  `classic/`'s) and reloads the page.
- `next/index.html` becomes `_takeover/next.html`, the redirect.
- `classic/manifest.json` gets the app id `wasteland-academy-classic`. Without it, a
  student who opens `/classic/` inside the app they installed from the old `/` would
  have that app move to `classic/` and open the HTML game from then on.
- Godot's `index.html` gets `<meta name="wa-classic" content="classic/">`, which shows
  its "Classic game" link. The HTML game shows "NEW VERSION ▸" when it runs from
  `classic/`.

Jekyll skips `_takeover/`, so with the switch off none of it is published.

**Saves.** Both games are on one origin, and neither reads or deletes the other's:

- HTML game: `localStorage` keys `wa_save`, `wa_save_unreadable_<time>` and
  `wa_ios_install_tip_seen`, and the Cache Storage cache `wasteland-academy-v3`. Its
  worker deletes only its own old caches (`wasteland-academy-v<n>`).
- Godot: `user://save.json` and `user://settings.cfg`, in the IndexedDB database
  `/userfs`. It doesn't use `localStorage`. Its offline copy is the Cache Storage
  cache `wasteland-academy-godot`.

Storage belongs to the origin, not the path, so a Godot save made at `/next/` is there
at `/`, and an HTML game save made at `/` is there at `/classic/`.

## The legacy HTML game

> **Legacy.** This section describes the HTML game at `/classic/`, which students will no longer see (#197). The Godot game above is the product.

The HTML game is vanilla JS with no build step: `index.html`, `js/`, `css/`, `content/` (one question pack per topic, see `CONTENT_SCHEMA.md`) and `vendor/` (KaTeX and the two fonts, see `vendor/LICENSES.md`). `js/platform.js` is the only file that touches browser storage, links and files.

- **Offline.** Every file it loads is in this repo, linked by relative path. A test fails if a remote or root-absolute URL creeps into `index.html`, `manifest.json`, `service-worker.js`, `js/` or `css/`. The one exception is the GitHub link for student reports, in `js/platform.js`.
- **Saves.** The save lives in `localStorage` under `wa_save`, with a format `version`. When the format changes, add a step to `WA.MIGRATIONS` in `js/engine.js` and bump `WA.VERSION`. A save that can't be read is kept aside under `wa_save_unreadable_<time>`. Players can export and import it from the Stats screen.
- **Tests.** `tests/content/` is the content validator; known defects are in `tests/content/known-defects.mjs`. `tests/e2e/` is Playwright: a full fight on a phone screen, a small-phone layout, the service worker offline and on update, save export and import, and the install button.

## Status

Playable, and live at the main address. All five zones are open, each with its topics, runs, mini-bosses and bosses, and so are the Thunderdome, the Bazaar and Practice. The engine has 173 of the 183 catalogued question types built: every AA SL skill is playable, and AA HL, AI SL and AI HL play mostly the parts they share with it (`curriculum/COVERAGE.md`). Still to come: paintings for four zones and backdrops for their topics, explainers with voices, the Relic Library's lessons, encounters, save export and import, and the app builds. See [`ROADMAP.md`](ROADMAP.md).
