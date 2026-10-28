extends RefCounted
## The Bazaar's balance check (FAL-416): simulated players play real runs (engine/run.gd)
## and shop after each one. test_bazaar.gd checks the result; tools/bazaar_balance.gd
## prints the price table.
##
## A player answers each question right with chance p, at once (so never late), uses no
## lifelines, and plays until their HP runs out (or MOST_QUESTIONS). After each run they
## buy every permanent unlock (upgrade levels, then cosmetics, cheapest first) they can
## afford. With `perk_every` > 0 they also buy the cheapest perk before every n-th run.

const Combat := preload("res://tests/test_combat.gd")
const MOST_QUESTIONS := 300
const NOW := 1_800_000_000


## The permanent unlocks in the catalogue, as [item, lifeline] pairs, one per level.
static func unlocks() -> Array:
	var out := []
	for i in Bazaar.cap("max_hp"):
		out.append(["max_hp", ""])
	for i in Bazaar.cap("lifeline"):
		out.append(["lifeline", Bazaar.LIFELINE_NAMES.keys()[i % 3]])
	for c in Bazaar.cosmetics():
		out.append([c, ""])
	return out


## One run on `save` with the player's chance p of a right answer. Returns its summary.
static func play_run(save: Dictionary, p: float, seed_no: int, region: String = "quadratics") -> Dictionary:
	var r := Run.new(save, region, 1, seed_no)
	r.clock = func() -> int: return NOW + seed_no
	Bazaar.equip(r, save)
	r.start()
	var rng := Seeded.new("bazaar-sim|%d" % seed_no)
	var n := 0
	while r.state != "ended" and n < MOST_QUESTIONS:
		r.answer(Combat.respond(r.question, rng.chance(p)))
		r.next()
		n += 1
	r.quit()
	return r.summary


## Buys what the player can afford after a run, cheapest first. Returns the items bought.
static func shop(save: Dictionary) -> Array:
	var bought := []
	while true:
		var best: Array = []
		var best_price := -1
		for u in unlocks():
			if Bazaar.why_not(save, u[0], u[1]) == "":
				var cost := Bazaar.price(save, u[0])
				if best_price < 0 or cost < best_price:
					best = u
					best_price = cost
		if best.is_empty():
			break
		Bazaar.buy(save, best[0], best[1])
		bought.append(best[0])
	return bought


## Plays `players` players until each has every permanent unlock (or `most_runs`).
## Returns {"runs_per_unlock", "scrap_per_run", "unlocked", "runs", "by_item": item ->
## mean runs since the last unlock, "first_run": item -> mean run number it came on}.
static func simulate(players: int, p: float, perk_every: int = 0, most_runs: int = 80) -> Dictionary:
	var total_runs := 0
	var total_unlocks := 0
	var total_scrap := 0
	var played := 0
	var gaps := {}
	var at := {}
	for pl in players:
		var save := SaveData.blank()
		var last := 0
		var all := unlocks().size()
		var got := 0
		var runs := 0
		while got < all and runs < most_runs:
			if perk_every > 0 and runs % perk_every == 0:
				var cheapest := ""
				for id in Tuning.PERKS:
					if cheapest == "" or Tuning.PERKS[id] < Tuning.PERKS[cheapest]:
						cheapest = id
				Bazaar.buy(save, cheapest, "hint" if cheapest in Bazaar.PICK_LIFELINE else "")
			runs += 1
			var s := play_run(save, p, 10_000 * (pl + 1) + runs)
			total_scrap += int(s.scrap)
			played += 1
			for item in shop(save):
				var key: String = item if item in Bazaar.cosmetics() else "%s %d" % [item, Bazaar.level(save, item)]
				if not gaps.has(key):
					gaps[key] = []
					at[key] = []
				gaps[key].append(runs - last)
				at[key].append(runs)
				last = runs
				got += 1
		total_runs += last
		total_unlocks += got
	var by_item := {}
	var first_run := {}
	for k in gaps:
		by_item[k] = _mean(gaps[k])
		first_run[k] = _mean(at[k])
	return {"runs_per_unlock": float(total_runs) / maxi(1, total_unlocks), "unlocked": total_unlocks,
		"scrap_per_run": float(total_scrap) / maxi(1, played), "runs": total_runs,
		"by_item": by_item, "first_run": first_run}


static func _mean(xs: Array) -> float:
	var t := 0.0
	for x in xs:
		t += float(x)
	return t / maxi(1, xs.size())
