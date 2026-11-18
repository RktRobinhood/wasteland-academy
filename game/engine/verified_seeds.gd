class_name VerifiedSeeds
extends RefCounted
## The seeds the CI checks have made, and so the only seeds play draws (#192, FAL-1038).
## The SymPy checker (tools/check-answers) makes seeds 1 to CHECKED of every cell and
## boss chain; the seed sweep (tools/stress-questions) makes CHECKED + 1 to LAST of every
## cell, and the first CHAIN_SEEDS of those for every boss chain. Both tools take their
## defaults from here, and test_verified_seeds fails if the tools, the workflows or the
## draws below drift apart. Widen the range here, never at a draw: a wider range is only
## verified once the sweep has run it.

## tools/check-answers: --per-cell and --per-chain.
const CHECKED := 50
## tools/stress-questions: --to.
const LAST := 2250
## tools/stress-questions makes each boss chain on this many seeds from CHECKED + 1.
const CHAIN_SEEDS := 1000
## The last seed a boss chain has been made on.
const CHAIN_LAST := CHECKED + CHAIN_SEEDS


## A seed for one question of a cell.
static func cell(rng: Seeded) -> int:
	return rng.int_in(1, LAST)


## A seed for a mini-boss or boss chain.
static func chain(rng: Seeded) -> int:
	return rng.int_in(1, CHAIN_LAST)


## Any whole number folded into 1 to LAST: the explainer's "new numbers" counts on from
## the seed it has, so the next one stays verified too.
static func wrap(n: int) -> int:
	return posmod(n - 1, LAST) + 1
