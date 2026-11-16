# Recording the explainers: licence, cost, cap and fallback

How the explainer narration gets recorded on Gemini text-to-speech, decided by the owner on 2026-11-16 (GitHub #18). Written on FAL-1035. The cast, with each tutor's model, voice, direction and processing, is `tools/explainer-clips/teachers.json`. The tool is `falcon-voice` (a local repo on Falcon, shared by every project), with its ledger and caps.

Nothing in this file starts production. Production waits on the script format (#188 to #191) and on the owner approving the cap below.

## Licence

Checked on 2026-11-16 against the Gemini API Additional Terms of Service (aistudio.google.com/docs/terms, effective 2026-03-23) and Google's Generative AI Prohibited Use Policy.

**The terms allow the audio in a paid Android, iOS and PC release.**

- **Ownership.** "Google won't claim ownership over that content." Google may generate the same or similar content for others, so the takes are ours to use but not exclusive.
- **Commercial use.** The API is for "professional or business purposes", which a studio making a game is. Nothing in the terms limits distributing or selling generated output. "You're responsible for your use of generated content."
- **Audio.** The terms say nothing specific about speech or voices. The prohibited-use policy bans impersonating a real person, so no direction ever names or imitates one (`AGENTS.md` for the voice work says the same).
- **Age.** API users must be 18 or over (Matt's account is), and an "API Client" must not be directed at under-18s. The API Client here is the offline recording tool on Falcon, which only the studio uses. The game ships static audio files and never calls the API, so the players' ages (16 to 19) don't bring the game under that clause. This is the one point that rests on a reading of the terms, so it is on the owner's cap card too.
- **Data.** Production runs on the paid key. On paid services Google doesn't use prompts or responses to improve its products. Only scripted lines are sent, never student data.
- **Watermark.** Every take carries Google's SynthID watermark. It's inaudible and needs no action.
- **Stores.** Steam asks for a disclosure of pre-generated AI content in its content survey. Answer it at submission: the tutor voices are generated with Gemini text-to-speech. Google Play's and Apple's AI rules cover apps that generate content on the device, which this game doesn't.
- **Credit.** Each clip is credited as "Generated with Gemini text-to-speech (`<model>`, voice `<voice>`) via the Gemini API", with the direction and the date (`teachers.json`).

Recheck the terms before the first store submission, and record the date here.

## Estimate for the 336 explainers

From `curriculum/explainers.json` (336 planned) and the 12 approved scripts (Tess 5, Mags 2, Rook 5), counting every `say` line in both recall versions, plus `callbacks.json`.

| | Per script (mean of 12) | All 336 + callbacks |
|---|---|---|
| Spoken lines | 58 | about 19,700 |
| Words | 1,069 | about 360,000 |
| Audio | 9.1 min | about 3,050 min (51 h) |

Audio is priced at 125 words a minute, the low end of the cast's measured pace on Gemini (123 to 142 a minute across the cast takes), plus half a second of edge silence a line. That's more than the 34 h in the review on #18, which counted only the watched version at 150 words a minute.

Price for `gemini-3.8-flash-tts`, Standard tier (aistudio.google.com/docs/pricing, read 2026-11-16): $9 per million audio tokens and $0.50 per million text tokens until 2026-12-31, **doubling to $18 and $1.00 from 2027-01-01**. Audio is 25 tokens a second.

| | At 2026 prices | At 2027 prices |
|---|---|---|
| Audio, 3,050 min | $41 | $82 |
| Text in, about 3.4 M tokens | $2 | $3 |
| Retakes and round-trip fixes, +25% | $11 | $21 |
| **Total** | **about $54** | **about $107** |

Production will mostly fall in 2027, since 12 of 336 scripts exist, so plan on the 2027 figure. The Batch tier costs half, but whether it takes `gemini-3.8-flash-tts` is unconfirmed; test it before production and lower the cap if it does.

**Requests, not dollars, set the pace.** The paid key is on Google's Tier 1: 100 requests a day on `gemini-3.8-flash-tts` (seen on FAL-992). At one line a request, 19,700 lines take about 200 days. Production should send one section's lines in one request (6 to 10 lines, one take) and cut it into one clip per line on the known text, with the round-trip check on every cut. That's about 2,500 requests, or 25 days at 100 a day.

## The cap

Built into `falcon-voice` (`caps.mjs`, `caps.json`, `manifest.mjs`, with offline tests). Before each request the tool checks, and refuses with nothing sent if a take could pass any of them:

- **Requests** per model per Pacific day (the ledger FAL-992 uses, `--daily-limit`).
- **Audio seconds and dollars** per model per day (`caps.json` `daily`).
- **Dollars per run** (`--run <id>`, `--run-cap-usd`, default $2).
- **Dollars per named budget** over its life (`--budget <name>`): `wa-pronunciation` for the round trip on #190, $2, and `wa-explainers` for production, **$0 until the owner approves the cap**.

The check uses a deliberately high estimate of each take's length. After the take, the ledger records what it really cost, from the length of the audio. Prices sit in `caps.json` by date, so the 2027 rise applies by itself.

**Accepted lines are never billed twice.** With `--manifest`, a line whose stable id already has an accepted take for the same `say` text (hashed), provider, model, voice and direction is refused before sending. Editing a caption doesn't change the hash, so it never forces a re-record.

**Recommended cap** (on the owner's card, FAL-1035): $120 in total for `wa-explainers`, and $5 and 3 hours of audio a day, which keeps a day's batched requests well inside it. Until it is approved, nothing beyond the pronunciation set is generated.

## If the model or a voice is withdrawn mid-production

A tutor's voice is fixed: same provider, model, voice and direction for every line (`teachers.json`). Two things can break that: Google retires `gemini-3.8-flash-tts`, or a library voice (such as `en-nz-commercial-3`) disappears. Neither has an announced date. The older preview speech models are due to stop on 2026-12-18, with the 3.8 models as their replacement, so Google does retire speech models and announces it in its release notes ahead of time.

- **Accepted takes keep working.** The game ships static files we own. A withdrawal only stops new and changed lines.
- **Record a tutor in one block.** Finish each tutor's scripts in a run of consecutive days, so a tutor is rarely half-recorded.
- **Check before each production day.** `node gemini-tts.mjs models` and `voices` cost no requests. If the model or a cast voice is missing or marked deprecated, stop the run and report it.
- **On a deprecation notice,** finish the lines of any tutor already started before the shutdown date. That may need a cap raise, which is a card.
- **If a tutor's voice is lost before their lines are done,** don't mix two voices for one tutor. Recasting is a casting decision for the owner (a card, under `AGENTS.md`): audition the nearest replacement on the replacement model, then re-record every line that tutor has. One tutor is about a sixth of the total, about $18 at 2027 prices. Edits to that tutor's script wait until the recast.
- **Last resort:** VoxCPM2 on Falcon is free, but it couldn't hold these accents in casting, so it is a fallback for a tutor only if no Gemini voice passes.
