# ADR-0007: Configurable encounter modifiers, reward integrity and bounded item systems

- Status: **Accepted principles; numeric tuning and item catalogue OPEN**
- Decision date: 2026-11-21
- Depends on: ADR-0002, ADR-0004, ADR-0005

## Decision

1. Effects from class skills, consumables, environmental hazards, enemies and equipment should compose from a **small, testable set of modifiers** rather than each authoring new bespoke code. Candidate levers: time policy, question-selection difficulty, hint/answer affordances, damage taken/dealt, armor/shield, ailment chance/severity, recovery chance, resource gain and encounter probabilities.
2. The same reusable modifier infrastructure supports *positive* and *negative* effects when semantically compatible; every modifier states when it activates, how long it persists, and whether/how it stacks.
3. Difficulty increases can be an interesting **opt-in risk/reward** action (e.g. a berserk/rage consumable that increases both damage output and incoming damage). Such an item is **only an idea**, not an approved entry in the shop. In any case, inflated difficulty must not allow raw rewards or inflated mastery to be bought without successful mathematical performance.
4. Item compatibility depends on question presentation: 50/50 applies only when there are answer options, hints only where valid hints are available, successive reveal steps only when a verified multi-step solution exists.
5. Mathematical assists reduce mastery-evidence strength and a performance bonus, scaled by degree of help. Combat-only effects do not automatically reduce mathematical credit.
6. **Do not add a carrying-capacity or stash rearchitecture now.** The owner explicitly declined an additional persistent-stash/run-inventory/quick-bar model after exploring it. Reuse existing inventory. A purchasable backpack expansion, vehicle as shield, Dune-style probabilistic shield and Rage Serum remain **unapproved possibilities**.
7. Conspicuous spending/item display can attract raiders via approved probabilistic Raider Attention. Random raider pressure can be deliberately sought for exclusive drops; it must not become automatic punishment whenever a student requests a hint.
8. Keep earned Scrap permanently even after a failed run and secure one-time accolades/rewards at milestone completion. A chance encounter must not revoke a saved narrative victory.

## Open tuning (propose, test, seek approval)

- Modifier ordering/cap rules, critical status interactions, timer pause/resume and question re-generation semantics.
- Distinguish an opt-in risk item that raises question difficulty from a **forced** status debuff that makes already-struggling students face questions outside their demonstrated level; keep the latter controlled and accessible.
- Score and mastery adjustments for question conditions that are made easier/harder by non-mathematical causes.
- Exact inventories, prices, status cure chances, resistance effectiveness, Raider Attention thresholds, probabilities and boss-drop odds.

## Verification

Use deterministic seeded tests proving: format gating, stacking precedence, score/maths separation, finite caps, persistence through save/reload, no course violation, status tick once per resolved question, noncombat use of effects, and no runaway positive feedback from purchases.
