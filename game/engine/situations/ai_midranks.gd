extends RefCounted
## A Radio Spires check: six aerials with distinct signal scores except one exact tie.
## Authoring link: the bank's t4-ai-spearman / ranks-with-a-tie, not its wording or data.

static func generate(rng: Seeded, _need: Dictionary = {}) -> Dictionary:
	var start := rng.int_in(34, 52)
	var sorted: Array = [start]
	for i in 5:
		sorted.append(sorted[i] - rng.int_in(1, 5))
	var first := rng.int_in(0, 4)
	sorted[first + 1] = sorted[first]
	var values: Array = rng.shuffled(sorted)
	var at := values.find(sorted[first]) if rng.chance(0.5) else values.rfind(sorted[first])
	return {"scores": values, "asked_index": at, "first": first + 1, "paper": 2}

## Twice a descending midrank, exact as an integer. No rounding or epsilon ties.
static func rank_twice(scores: Array, target: int) -> int:
	var greater := 0
	var tied := 0
	for score in scores:
		greater += int(score > target)
		tied += int(score == target)
	return 2 * greater + tied + 1

static func export(s: Dictionary) -> Dictionary:
	return s.duplicate(true)
