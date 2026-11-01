extends "res://tests/test_case.gd"
## The seeded stream (FAL-460): the first draw is as fair as every later one, so no
## recipe has to spend it, and a seed and a key always give the same numbers.

const SEEDS := 1000


func _first_draws(draw: Callable) -> Array:
	var out := []
	for i in SEEDS:
		out.append(draw.call(Seeded.new("first|%d" % i)))
	return out


func test_the_first_chance_is_not_always_true() -> void:
	# chance(0.25) was true for every seed while the state had no high bits.
	var hits := _first_draws(func(s: Seeded): return s.chance(0.25)).filter(func(b): return b).size()
	check(hits >= 200 and hits <= 300, "chance(0.25) was true %d times in %d first draws" % [hits, SEEDS])


func test_the_first_float_spreads_over_the_range() -> void:
	var low := 0
	var high := 0
	for i in SEEDS:
		var r := Seeded.new("float|%d" % i).rng.randf()
		if r < 0.1:
			low += 1
		elif r >= 0.9:
			high += 1
	# Each tenth of the range expects 100 of 1000; the old stream put all of them in the lowest.
	check(low >= 60 and low <= 140, "%d of %d first floats under 0.1" % [low, SEEDS])
	check(high >= 60 and high <= 140, "%d of %d first floats at 0.9 or more" % [high, SEEDS])


func test_the_first_whole_number_reaches_every_value() -> void:
	var counts := {}
	for v in _first_draws(func(s: Seeded): return s.int_in(0, 9)):
		counts[v] = int(counts.get(v, 0)) + 1
	for v in 10:
		var n: int = counts.get(v, 0)
		check(n >= 55 and n <= 150, "first int_in(0, 9) was %d on %d seeds" % [v, n])


func test_the_first_pick_and_weighted_pick_are_fair() -> void:
	var picks := {}
	for v in _first_draws(func(s: Seeded): return s.pick(["a", "b", "c", "d"])):
		picks[v] = int(picks.get(v, 0)) + 1
	for k in ["a", "b", "c", "d"]:
		var n: int = picks.get(k, 0)
		check(n >= 190 and n <= 310, "first pick was %s on %d seeds" % [k, n])
	var heavy := 0
	for i in SEEDS:
		if Seeded.new("weighted|%d" % i).weighted([1, 3]) == 1:
			heavy += 1
	check(heavy >= 700 and heavy <= 800, "weighted([1, 3]) chose the heavy one %d times in %d" % [heavy, SEEDS])


func test_the_same_text_gives_the_same_stream() -> void:
	for text in ["a", "paper|fn-x", "quadratic|7"]:
		var a := Seeded.new(text)
		var b := Seeded.new(text)
		for i in 20:
			check_eq(a.int_in(0, 1000000), b.int_in(0, 1000000), "%s draw %d" % [text, i])
	check(Seeded.new("a").int_in(0, 1000000) != Seeded.new("b").int_in(0, 1000000), "two keys gave the same first draw")


func test_the_stream_is_pinned() -> void:
	# PCG32 is integer-only, so desktop and web agree. If this fails, every seed now makes
	# a different question: say so on the task before changing the numbers.
	var s := Seeded.new("pinned")
	var got := []
	for i in 5:
		got.append(s.int_in(0, 1000000))
	check_eq(got, PINNED, "the first five draws of \"pinned\"")


const PINNED := [580530, 92367, 107400, 563213, 47258]
