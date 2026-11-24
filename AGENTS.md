# Repository instructions

## Start every build loop here

Read [the product charter](docs/PRODUCT-CHARTER.md), [decision register](docs/DECISION-REGISTER.md), [domain glossary](docs/DOMAIN-GLOSSARY.md), and [delivery queue](docs/BUILD-LOOP.md) before choosing work. Read the governing ADR and the selected issue, including comments and linked PRs. Fetch `origin` and check the actual default branch: a local checkout or the November 21 audit may be stale.

The accepted November 21 direction takes precedence over older scope/order defaults below: finish the complete five-zone **AA SL roguelike** first. Keep the four-course architecture and existing work; further course rollout, a separate academic product and platform expansion do not displace that milestone. The charter is the target, not a claim that those features already work.

Use `docs/BUILD-LOOP.md` as the single integration queue. One bounded implementation PR is active at a time, with a named integration owner, issue acceptance criteria and evidence. Land or explicitly defer that slice before opening another. Existing branches are work to assess, not automatic priorities or permission to merge. Preserve unfinished branches; do not delete them to tidy the list.

## Product authority

- Accepted owner decisions and accepted ADR clauses define intended behavior. Code and tests show what exists. Older specs/issues are reconciled against those decisions; neither existing behavior nor an agent recommendation grants product approval.
- New modes, major progression/economy systems, substantial learner-experience changes and unapproved mechanics need explicit owner approval. The framework principles in ADR-0005 to ADR-0007 are accepted; proposed creatures, items, story graphs and OPEN numeric values are not automatically authorized. Do not introduce the deferred stash/run-bag/quick-bar architecture.
- Approved implementation, ordinary bug fixes, validation, wording and bounded refactoring proceed autonomously. Before changing gameplay semantics, cite the ADR, describe the behavior and define its acceptance checks. Keep save/skill IDs, routes and seeded question reproducibility stable.
- Record unresolved choices and continue independent approved work. Do not ship guessed calibration, prerequisite gates, boss-to-story mappings or a Thunderdome floor for an unattempted learner.
- Use `writing/glossary.md` and `writing/glossary.json` for exact player copy; the domain glossary defines meaning. A proposed interface is not a mandated rewrite.
- Keep paid production, new voices, student-data handling, asset and release approvals below. Never claim classroom readiness from coverage counts or CI alone; record mathematical, asset and human playtest evidence separately.

## Work while the owner is away

The owner wants this project to run without them at the keyboard (#204, 2026-11-16). Agents work through the open GitHub issues on their own. The owner's contact point is **Paperclip**: a card appears there when something needs approval or when art is wanted, and the owner answers there. Read #204 before picking up an issue; it stays open and pinned as the index.

- **Do not wait for sign-off on ordinary approved work.** Suggested wording and routine implementation choices may proceed. A recommendation for a new mode, major mechanic or OPEN design value remains a proposal until explicitly accepted.
- **Never block on the owner.** While a card waits in Paperclip, carry on with other issues. Do not stop the queue.
- **Batch requests.** One card with several questions or several art prompts is better than many cards.
- **Every card stands on its own:** what is needed, why, the options with a recommendation, and what happens if there is no answer.
- **Record the outcome** on the GitHub issue when the owner answers (see "Keep GitHub issues current" below).

### What needs a Paperclip approval card

- Spending money or raising a cap: text-to-speech runs, paid services, store fees.
- Anything published beyond the test site: store submissions, public announcements, a release students are told to use.
- Deleting content or assets that cannot be regenerated, and rewriting git history.
- Anything that sends or stores student data: telemetry, accounts, sync.
- Reversing a decision listed below, or adding a new speaking character (the owner auditions voices for new characters).
- Licence questions that could block a paid release.

Routine work within accepted scope goes ahead without a card. Product changes covered by "Product authority" also need explicit approval; silence is not approval. If Paperclip is unavailable, record the question and dependency on GitHub and continue independent work. Do not claim a Paperclip card was sent without a receipt.

### Art requests

Local image generation is not good enough for map and level art, so the owner makes it in ChatGPT (#201).

- Raise a Paperclip card with the prompt card: the full prompt, size and aspect, what must and must not appear, and the reference images.
- The owner returns about five candidates on that card, sometimes with a comment. A comment is a strong preference.
- The Artist chooses and records why. If none pass, reply on the card with a revised prompt.
- Send prompts in priority order and in batches, so one sitting covers several pieces.

### Decisions already made

Owner decisions, 2026-11-16. Reversing one needs a card. #204 holds the current list.

- Voices: Gemini text-to-speech with a cost cap; casting is finished (#18).
- Captions show proper notation; the voice gets separate spoken text (#190).
- The classic HTML game is removed for students (#197).
- First platform after the web classroom build: PC, then Android and iOS (#199).
- No save sync for now; export and import only (#185, future sync in #202).
- Map and level art comes from the owner through ChatGPT; the Artist decides (#201).
- "The Wasteland" for the main map, no "islands", places called by name (#203).

Defaults that stand unless the owner objects:

- Pronunciation is checked automatically by transcribing takes back to text; the owner hears only lines that still fail (#190).
- One audio clip per spoken line, captions by line, word timings optional (#190).
- The agents choose the animation technique for maps from a comparison, testing still-plus-effects and layered paintings first (#201).
- The exam switch becomes "Exam questions only" or "Exam questions plus training", defaulting to plus training (#203).
- Code and docs use "zone" as the common noun; save keys, routes and ids are not renamed (#203).
- Wording and label changes are applied without prior sign-off (#203).

### Order of work

The current order is [the delivery queue](docs/BUILD-LOOP.md). Classroom defects and mathematical correctness remain urgent. Interactive explainers retain #215's prototype and cost gates; #224 replaces the unapproved whole-map voice estimate. PC then mobile remains the eventual platform order, after the AA SL core milestone. Do not resurrect closed issues from this older list without checking their acceptance evidence.

## Keep GitHub issues current

- Read the relevant issue and its acceptance criteria before working on it. Check existing code, documentation and linked pull requests so already completed work is recognized.
- As part of finishing work, reconcile the related issues. The owner has authorized closing issues when their requirements are verified as resolved; do not ask for routine confirmation each time.
- For implementation delivered through a pull request, include `Closes #<number>` in the PR body only when that PR completes the issue. This lets GitHub close the issue when the PR merges into the default branch. Describe the behavior delivered and the relevant verification.
- For partial work, use `Refs #<number>`, update the remaining work on the issue, and leave it open. Deferred work and work in an unmerged PR are not completed work.
- If an issue is already satisfied on the default branch, close it with a concise comment linking the implementation or documentation and explaining how it meets the request. For a creative-direction issue, durable adopted guidance can satisfy the request; distinguish that from unfinished implementation requirements.
- If the owner confirms an issue has been superseded, close it with a comment linking the replacement plan or issues and identifying any remaining work. Do not treat superseded work as fully implemented.
- Keep umbrella issues open until all their requirements are accounted for. Preserve unresolved decisions and follow-up work explicitly rather than closing an umbrella because one part landed.
- Include issue updates and closures in the final report. Never close issues solely because they are old or have matching keywords.

## Keep completed work on main

- The owner wants pull requests open only while work is actively in flight, under review, or under testing. Do not leave completed PRs idle while they fall behind `main`.
- For authorized implementation work, review the final diff, resolve conflicts while preserving newer changes, run the relevant checks, and merge promptly when ready. Keep failed checks and unresolved requirements visible; do not bypass branch protections or merge unfinished work to reduce the PR count.
- Close duplicate or superseded PRs with a link to the work that replaced them. For a genuine external blocker, record the concrete blocker and next action instead of leaving the status ambiguous.
