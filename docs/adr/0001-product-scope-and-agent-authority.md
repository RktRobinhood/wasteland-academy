# ADR-0001: Product scope and agent authority

- Status: **Accepted**, 2026-11-21
- Owner decision: gameplay first, AA SL first, no invented new modes
- Supersedes: any reading of root `AGENTS.md` that treats an agent recommendation as product approval.

## Context

Autonomous work made substantial progress but allowed loosely defined terms, suggested features and existing issues to be interpreted as permission for design expansion. The owner wants to recover a shared vocabulary and finish the core roguelike rather than spawn new modes.

## Decision

1. The product promise is in `../PRODUCT-CHARTER.md`. AA SL's **all five zones**, their educational content, narrative bosses, visual/audio polish and core game systems form the first classroom-ready release.
2. The maths engine remains reusable and all four IB courses inform the schema; AA HL/AI SL/AI HL complete content is **not** a first-release blocker.
3. Agents may implement accepted features, fix defects, validate existing content, improve performance and perform bounded refactors autonomously.
4. Any new game mode, major economy or progression subsystem, unapproved pedagogical mechanism, changes to student data handling or substantial scope expansion requires **explicit owner approval** before implementation. A brainstorming suggestion or GitHub issue recommendation is not approval.
5. Approval can happen via the existing Paperclip/GitHub workflow. If unavailable, record the blocked decision and work on independent authorized tasks; never substitute an unapproved default.
6. Keep one player-visible wording source (`writing/glossary.md` and `glossary.json`) and one domain-meaning source (`docs/DOMAIN-GLOSSARY.md`). Update code/API docs and SPEC/ROADMAP to match accepted ADRs. Do not pretend documentation changes automatically make code conform.
7. Preserve the current Godot game and reusable `MathsEngine` seam; do not undertake a speculative rewrite or launch a separate academic product as part of scope recovery.

## Why

Predictable product direction, fewer agent surprises, and explicit separation of content implementation from product-design authority. This still permits unattended coding on approved work.

## Consequences and verification

- Root [AGENTS.md](../../AGENTS.md) must restrict the former 'Everything else goes ahead without a card' exception to approved scope, including explicit review for **feature design and game modes**. The handoff's proposed policy insert was selectively integrated on 2026-11-24; existing operational approvals remain.
- For every PR changing gameplay semantics: cite the relevant ADR, test acceptance conditions, note any new decisions needing approval.
- Tests should verify actual player behavior and preserve existing save IDs; do not count a document update as feature completion.

## Alternatives rejected

- Allowing agents to infer approval from informal planning: caused feature drift.
- Requiring owner approval for every bug fix and routine task: unnecessary friction.
