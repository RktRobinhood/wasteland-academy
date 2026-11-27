extends RefCounted
## Two signed unit-axis terms, exactly one absent component. The magnitudes must
## differ so exchanging axes does not give the same distractor as reversing both signs.

static func generate(rng: Seeded, _need: Dictionary = {}) -> Dictionary:
	var axes := rng.shuffled([0, 1, 2])
	var a := rng.int_in(1, 8)
	var b := rng.int_in(1, 7)
	if b >= a:
		b += 1
	var sign := 1 if rng.chance(0.5) else -1
	return {"terms": [[axes[0], sign * a], [axes[1], -sign * b]], "paper": 1}

static func export(s: Dictionary) -> Dictionary:
	return s.duplicate(true)
