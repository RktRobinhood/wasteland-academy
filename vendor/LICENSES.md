# Vendored files

Everything the game loads from a third party is copied here, so a phone never
requests anything from another host and an app build can ship the same files.
Each file is unchanged from its source. `tests/unit/offline.test.mjs` checks
that every file here is precached by the service worker.

## KaTeX 0.16.9 (MIT)

Copied from the `katex@0.16.9` npm package (`dist/`). Licence: [`katex/LICENSE`](katex/LICENSE).
Copyright (c) 2013-2020 Khan Academy and other contributors.

| File | Licence |
|---|---|
| `katex/katex.min.css` | MIT |
| `katex/katex.min.js` | MIT |
| `katex/contrib/auto-render.min.js` | MIT |
| `katex/fonts/KaTeX_*.woff2` (20 files) | MIT |

Only the woff2 fonts are shipped. `katex.min.css` also lists woff and ttf
fallbacks, which every browser that supports woff2 never requests.

## Bangers (SIL Open Font License 1.1)

Downloaded from Google Fonts (`fonts.gstatic.com/s/bangers/v25`), one file per
unicode range. Licence: [`fonts/OFL-Bangers.txt`](fonts/OFL-Bangers.txt).
Copyright 2010 The Bangers Project Authors.

| File | Licence |
|---|---|
| `fonts/bangers-latin.woff2` | OFL 1.1 |
| `fonts/bangers-latin-ext.woff2` | OFL 1.1 |
| `fonts/bangers-vietnamese.woff2` | OFL 1.1 |

## Share Tech Mono (SIL Open Font License 1.1)

Downloaded from Google Fonts (`fonts.gstatic.com/s/sharetechmono/v16`). Licence:
[`fonts/OFL-ShareTechMono.txt`](fonts/OFL-ShareTechMono.txt).
Copyright (c) 2012, Carrois Type Design, Ralph du Carrois, with Reserved Font Name 'Share'.

| File | Licence |
|---|---|
| `fonts/share-tech-mono-latin.woff2` | OFL 1.1 |

## Ours

`fonts/fonts.css` declares the two fonts above. It is the Google Fonts CSS for
`Bangers` and `Share Tech Mono`, with the URLs pointed at the files here.
