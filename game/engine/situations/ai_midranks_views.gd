extends ExtensionViews

const SPEC := preload("res://engine/situations/ai_midranks.gd")
const RANK := "AI-SL4.10.rank-with-ties"

func needs() -> Dictionary:
	return {"ranks-with-a-tie": {}}

func papers(unknown: String, _rep: String, _angle: String) -> Array:
	return [2] if has(unknown) else []

func u_ranks_with_a_tie(_rep: String, s: Dictionary, _rng: Seeded) -> Dictionary:
	var labels := ["A", "B", "C", "D", "E", "F"]
	var target: int = s.scores[s.asked_index]
	var answer_rank := Q.new(SPEC.rank_twice(s.scores, target), 2)
	var answer := Answer.make("number", {"v": answer_rank}, {}, "rank")
	answer.show = "dec"
	answer.exact = true
	var sorted: Array = s.scores.duplicate()
	sorted.sort()
	sorted.reverse()
	var ordered := ", ".join(sorted.map(func(x): return str(x)))
	var slips := [wrong({"v": Q.new(s.first)}, RANK + "#1"), wrong({"v": Q.new(s.first + 1)}, RANK + "#0"),
		wrong({"v": Q.new(7).sub(answer_rank)})]
	if slips[2].values.v.eq(answer_rank):
		slips[2] = wrong({"v": Q.new(s.first + 2)})
	return {
		"lines": ["Technicians at the Radio Spires tested six aerials. The highest signal score gets rank 1."],
		"table": {"rows": [["Aerial", labels], ["Signal score", s.scores.map(func(x): return str(x))]]},
		"asked": "Write down the rank of aerial %s." % labels[s.asked_index],
		"answer": answer, "wrongs": slips,
		"fillers": [wrong({"v": Q.new(1)}), wrong({"v": Q.new(6)}), wrong({"v": Q.new(3)})],
		"given": {"scores": s.scores, "asked_index": s.asked_index},
		"methods": {"order-and-average": method([
			"Order the scores from highest to lowest: %s." % ordered,
			"The score %d occupies positions %d and %d." % [target, s.first, s.first + 1],
			"The tied aerials share the mean rank: (%d + %d) ÷ 2 = %s." % [s.first, s.first + 1, Fmt.dec(answer_rank)]
		], answer.values)}
	}
