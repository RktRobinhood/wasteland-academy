# Wasteland Academy

A post-apocalyptic roguelite for IB mathematics revision, built in Godot 4.7.2. It covers all of Analysis and Approaches SL, and most of the maths that AA HL, AI SL and AI HL share with it. Students play it in the browser at <https://rktrobinhood.github.io/wasteland-academy/>, on a phone or a laptop.

The product is an app for PC, Android and iOS. PC comes first, after the web build is ready for a class (#199). GitHub Pages stays the testing host.

Wasteland Academy is one presentation of a reusable IB mathematics engine. The same question generation, marking, worked solutions and curriculum selection should also support more academic interfaces. The game is the current product; a separate academic interface is future work.

The [Math-AA question bank](https://github.com/RktRobinhood/Math-AA---Question-Bank) stays in its own repository. Its exam metadata already informs the question-type catalogue; planned higher-level and other-course additions should expand that coverage and improve generated questions and filtering. See the [engine direction](SPEC.md#reusable-mathematics-engine-direction), [bank integration plan](curriculum/README.md#question-bank-integration-direction) and [implementation follow-up #134](https://github.com/RktRobinhood/wasteland-academy/issues/134).

## For teachers

- [`TEACHERS.md`](TEACHERS.md): what each course can play, what the game doesn't train, how typed answers are marked, and where progress is kept.
- [`PRIVACY.md`](PRIVACY.md): what the game stores and sends.

## Docs

- [`docs/BUILD-LOOP.md`](docs/BUILD-LOOP.md) — Start here for the current integration queue and landing process
- [`docs/PRODUCT-CHARTER.md`](docs/PRODUCT-CHARTER.md) — Accepted AA SL product target
- [`docs/DOMAIN-GLOSSARY.md`](docs/DOMAIN-GLOSSARY.md) — Shared domain meanings; player wording stays in `writing/glossary.md`
- [`docs/DECISION-REGISTER.md`](docs/DECISION-REGISTER.md) and [`docs/adr/`](docs/adr/) — Accepted decisions, proposals and open choices
- [`docs/ALIGNMENT-AUDIT-2026-11-24.md`](docs/ALIGNMENT-AUDIT-2026-11-24.md) — Current implementation gaps and branch inventory

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
                        ← the legacy HTML game, not published (see below)
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
- `export`: the web export, built once and shared with `web` and `takeover`.
- `web`: the export, booted in headless Chromium at phone and PC sizes, with screenshots.
- `answers-shard` and `answers`: the SymPy answer checker in ten shards, then merged.
- `feedback`: what a student reads after each wrong option (`tools/feedback-check`).
- `takeover`: the site laid out as Pages publishes it, checked in a browser (`tools/takeover-dry-run`).
- `test`: `npm test`, the Node unit tests, the content validator and the HTML game's Playwright tests, plus the telemetry report's tests.
- `telemetry`: type-check and tests for the collector in `services/telemetry/`.

`.github/workflows/stress.yml` runs the seed sweep in twelve shards every night on `main`, then `stress` passes only if all twelve did. Run it on a branch with `gh workflow run stress --ref <branch>`. Play draws its seeds only from the range the checker and the sweep cover (`game/engine/verified_seeds.gd`), and `test_verified_seeds` fails if the two drift apart. `.github/workflows/release.yml` runs `test.yml` and `stress.yml` on a `v*` tag. Its `green` job passes only when every job of both passed.

`.github/workflows/pages.yml` publishes the site on every push to `main`.

## Saves

The Godot game keeps progress in `user://save.json` and its settings in `user://settings.cfg`. On the web that is the browser's IndexedDB database `/userfs`, so progress belongs to one browser on one device. There is no account and no sync, and progress is per device and per browser: a student on another device or browser starts again, and clearing the browser's site data deletes it.

To move or back up progress, open Settings (the gear) and choose "Export or import save". Export gives a code to copy (`WA-SAVE-1:` and the save, one line) or a file to save; import takes the code pasted in or a file, and asks twice because it replaces the save on this device. The save it replaces is kept beside it as `save.before-import-<time>.json`. Nothing is sent anywhere. Sync between devices is for later (#202).

The save is one versioned document (`game/engine/save_data.gd`, with migrations) keyed by permanent ids. Writes go to `save.json.tmp` and are renamed over `save.json`, which keeps the previous good save as `save.json.bak`. A save that can't be read is moved to `save.unreadable-<time>.json`, never overwritten, and the `.bak` is used if there is one.

## Releases

*For the site's maintainers (#184).* A merge to `main` must not change what a class is using, so the student address is pinned to a release and `main` has its own preview address. GitHub Pages serves one site per repository, so both are on it: the **release at the root** and **`main` under `/preview/`**.

- **Cut a release:** push a tag, `git tag v1.0.0 && git push origin v1.0.0`. `.github/workflows/release.yml` runs the whole `test` run and the stress sweep on it, and only if both are green builds the site of that tag and keeps it as a prerelease on GitHub, with the build id in its notes. A tag that fails the gate publishes nothing. Cutting tags is free: they reach nobody.
- **Pin it for students:** `gh variable set STUDENT_RELEASE --body v1.0.0 -R RktRobinhood/wasteland-academy`, then `gh workflow run pages.yml --ref main -R RktRobinhood/wasteland-academy`. This is the step that makes a release the one students are told to use, so it is the owner's decision (#204). Change the variable and run `pages` again to move to another release, or back to an earlier one.
- **Until a release is pinned** (`STUDENT_RELEASE` unset) the root is `main`, as before, and every merge reaches it. Once it is set, a push to `main` refreshes `/preview/` and leaves the root alone.
- **The build id** is the tag (`v1.0.0`), or `main-<commit>` on the preview, or `dev` in the editor. It is on the title screen, bottom right, in the release's notes and in the service worker's cache name (`scripts/build-id.sh`, `game/engine/build.gd`). A student can read it out to check a class is on one build.
- **The service worker** (`_takeover/service-worker.js`) is cache first: a page loads from its build's own cache and never waits on the network, so slow Wi-Fi doesn't stall it and a reload is not a download. The browser checks for a new worker in the background. A new build downloads into its own cache and waits until no page is open on the old one, so a lesson stays on one build.
- **A run is saved as it goes:** Scrap is banked with each answer and the save is written after each one (`Run._bank`), and a floor is recorded when it opens, so a reload or crash keeps what was earned and the floors reached.

## Switching to Godot

This switch is for the site's maintainers.

One switch decides which game is at the main address: the repository variable
`GODOT_AT_ROOT`, which `.github/workflows/pages.yml` reads. Unset counts as off. It
has been on since November 4, 2026 (FAL-721).

Students get one game and one save (#197, the owner's decision on 2026-11-16): with
the switch on, the HTML game isn't published at all. Its source stays in this
repository as the legacy game, and the switch off is how to bring it back.

| Switch | `/` | `/classic/` | `/next/` |
|---|---|---|---|
| `off` | the HTML game (legacy) | not published | Godot |
| `on` | Godot | not published | sends people to `/`, keeping the `?…` and `#…` |

Either way the site has no repository document or source: no `*.md`, and no `game/`,
`services/`, `writing/`, `tools/` or `curriculum/`. `scripts/check-site.sh` stops the
deploy if one is left.

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
  with no "Classic game" link.
- `/classic/`, `/classic/ROADMAP.md`, `/ROADMAP.md` and `/game/project.godot` are 404.
- `/next/#functions/quadratics` opens the Quadratics region, at `/#functions/quadratics`.
- In a browser that played the old game, `/` shows Godot. The page reloads once.
- After one visit, `/` plays offline.

**Turn it off:** set the variable to `off` (or delete it) and run `pages` again. The
site goes back to the HTML game at `/` and Godot at `/next/`. Godot links such as
`/#functions/quadratics` open the HTML game.

What `scripts/assemble-site.sh` does:

- Jekyll publishes the whole repository, so it keeps only the HTML game's own files
  (`index.html`, `js`, `css`, `content`, `vendor`, `assets`, `manifest.json`,
  `service-worker.js`), less any `*.md` and the page Jekyll made of it. With the
  switch on it drops those too.
- With the switch on, the root `service-worker.js` becomes `_takeover/service-worker.js`,
  and Godot's `index.html` registers it (`_takeover/register-worker.html`). It keeps a
  copy of the export in the cache `wasteland-academy-godot`, so Godot plays offline
  after one visit. Each file is network-first and revalidated, so a player who is
  online always gets the latest deploy. A browser that ran the old game at `/` fetches
  the worker as that game's worker's update: it deletes the HTML game's caches (the
  root's and `classic/`'s) and reloads the page. The Godot page unregisters the HTML
  game's worker at `classic/`, from when that copy was published.
- `next/index.html` becomes `_takeover/next.html`, the redirect.

Jekyll skips `_takeover/`, so with the switch off none of it is published.

**Saves.** Both games are on one origin, and neither reads or deletes the other's:

- HTML game (legacy): `localStorage` keys `wa_save`, `wa_save_unreadable_<time>` and
  `wa_ios_install_tip_seen`, and the Cache Storage cache `wasteland-academy-v3`. Its
  worker deletes only its own old caches (`wasteland-academy-v<n>`). With the switch
  on, the root worker deletes its caches, but its `localStorage` save stays, so the
  switch off brings that save back.
- Godot: `user://save.json` and `user://settings.cfg`, in the IndexedDB database
  `/userfs`. It doesn't use `localStorage`. Its offline copy is the Cache Storage
  cache `wasteland-academy-godot`.

Storage belongs to the origin, not the path, so a Godot save made at `/next/` is there
at `/`.

## The legacy HTML game

> **Legacy.** This section describes the HTML game, which isn't published for students (#197). Its source stays here. The Godot game above is the product.

The HTML game is vanilla JS with no build step: `index.html`, `js/`, `css/`, `content/` (one question pack per topic, see `CONTENT_SCHEMA.md`) and `vendor/` (KaTeX and the two fonts, see `vendor/LICENSES.md`). `js/platform.js` is the only file that touches browser storage, links and files.

- **Offline.** Every file it loads is in this repo, linked by relative path. A test fails if a remote or root-absolute URL creeps into `index.html`, `manifest.json`, `service-worker.js`, `js/` or `css/`. The one exception is the GitHub link for student reports, in `js/platform.js`.
- **Saves.** The save lives in `localStorage` under `wa_save`, with a format `version`. When the format changes, add a step to `WA.MIGRATIONS` in `js/engine.js` and bump `WA.VERSION`. A save that can't be read is kept aside under `wa_save_unreadable_<time>`. Players can export and import it from the Stats screen.
- **Tests.** `tests/content/` is the content validator; known defects are in `tests/content/known-defects.mjs`. `tests/e2e/` is Playwright: a full fight on a phone screen, a small-phone layout, the service worker offline and on update, save export and import, and the install button.

## Status

Playable, and live at the main address. All five zones are open, each with its topics, runs, mini-bosses and bosses, and so are the Thunderdome, the Bazaar and Practice. The engine has 173 of the 183 catalogued question types built: every AA SL skill is playable, and AA HL, AI SL and AI HL play mostly the parts they share with it (`curriculum/COVERAGE.md`). Still to come: paintings for four zones and backdrops for their topics, explainers with voices, the Relic Library's lessons, encounters, save export and import, and the app builds. See [`ROADMAP.md`](ROADMAP.md).
