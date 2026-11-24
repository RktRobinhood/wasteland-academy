# ADR-0004: Thunderdome, characters, economy and tactical risk

- Status: **Accepted design boundaries; pricing/XP/combat tuning OPEN**, 2026-11-21

## Decision A - Thunderdome

- Thunderdome is the primary survival roguelike. The basic **Exhibition** is free or inexpensive and immediately accessible, with any topics inside the selected course available regardless of overworld progression. Questions may begin near the mastery-informed run floor and then escalate quickly.
- **Boss Rush** is the more dramatic escalating, multi-phase, exam-style sequence. It unlocks permanently after a meaningful Exhibition milestone, has a Scrap fee and can provide stronger rewards. The player chooses an eligible topic subset; broader selected syllabus scope increases risk and potential returns. Do not require an entire two-year syllabus before play.
- Encounter topics are sampled from **adaptive probability weights**, not a deterministic rotation. Recently featured topics/miniboss themes become less likely; neglected selected topics trend upward; very long runs still have nonzero probability of missing a topic. Minibosses/bosses may momentarily focus on one topic and present linked extended problems.
- Boss Rush is an **approved format within the Thunderdome**, not permission to invent adjacent new modes. Its unlock metric, fee/prizes, optional stop/retreat policy and balance are open.

## Decision B - Characters and XP

- Playable characters presently envisioned are **Tilly/Scout**, **Banjo/Ranger**, and **cyber-dog/Tinker**. Preserve the published identities unless explicitly changed by the owner. Three skill trees per character (nine total) with mix-or-specialize point allocation and access to ultimates, similar in spirit to Borderlands.
- Players can switch characters **between** runs only. Each character has its **own** XP, level and tree allocation; only the actively used character gains XP. The syllabus, mathematical mastery, Scrap and collected shared items persist across characters. Respec costs a modest amount of Scrap.
- Early levels come relatively quickly, then XP requirements grow strongly. Gameplay gives small XP; first-time player accolades, mastery milestones, meaningful boss victories and PBs give more. Accolade bonuses are **account-wide once**, not farmable per alternate character. Individual alts may progress more slowly; ensure max level remains realistically attainable.
- Max level should be calibrated against substantial participation (owner target: roughly 70-80% of meaningful AA SL game completion for a first character, subject to quantitative simulation). The point budget at max level should allow the end of one tree plus modest investment elsewhere, not all nine/three trees at once.

## Decision C - Currency, items, assistance and Raiders

- Scrap is **earned, persistent and cross-character**. Item availability should produce choice, not abundance or scarcity as the main activity. Do not take Scrap away when a player dies.
- **Bazaar** has the full stable selection of upgrades, cosmetics, consumables, modifiers and respecs. **Travelling merchants** are occasional run encounters with a small and potentially regional/rare catalogue. The same item/effect system governs both; do not duplicate effects per shop.
- Mathematical assists (extra time, freezes, 50/50, hints, progressive worked-solution steps) apply where question capabilities permit; stronger effects are rare/limited. Their use reduces the score bonus and weighted mastery evidence according to strength. Combat boosts (HP, damage, armor) do **not** reduce maths-performance bonuses by themselves.
- **Raider Attention is approved for the initial roguelike**. Conspicuous item use/spending makes raiders probabilistically more likely, without a permanent UI meter. Show attention only after it becomes relevant; rare recurring raider bosses may drop exclusive cosmetics/items. On defeat, the raider escapes with a villain line and attention resets to zero. Repeated pursuit is possible. This is danger/reward layered onto maths, not a penalty simply for requesting learning support.
- No real-money stake, cash-out or randomized purchase. Boss Rush entry is earned in-game Scrap.

## Open balancing/architecture questions

1. Boss Rush unlock metric, entry cost, rewards by topic breadth and optional withdrawal semantics.
2. XP curve and maximum level for first character and for alts after first-time account accolades are exhausted.
3. Item rarity, effect compatibility, current inventory interactions and time/hint progression **within the existing inventory system**. A new stash/carrying-capacity/quick-bar architecture was explicitly deferred in ADR-0007.
4. Numerical Raider Attention formula, cooldown, meter display threshold, probability tests and limits on deliberate boss farming.
5. Does using a mathematical assist reduce total score or only the performance bonus? The accepted direction is a *bonus reduction*, not changing question correctness.
6. Exact question weighting in Thunderdome and the fallback starting floor if no skills have yet been attempted.

## Test implications

- Course selection filters all Exhibition and Boss Rush questions; user selection allows only relevant skills.
- One boss topic decreases subsequent topical probability without forcing rotation; seeded runs are reproducible.
- Correct floor computed once per run and never decreases; question engine still records actual earned skill mastery.
- XP accrued by active character only, account accolade only once; sharing Scrap/items does not merge characters' XP/trees.
- Mathematical assists are format-gated; healing/damage modifiers do not alter question correctness or mastery update.
- Raider probability increases with conspicuous behavior, resets after victory, and remains bounded. All encounters still exercise maths.
