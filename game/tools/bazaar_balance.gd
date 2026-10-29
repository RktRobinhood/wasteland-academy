extends SceneTree
## Prints the Bazaar's price table (FAL-416): each unlock's price, how many runs of a
## 70%-right player's Scrap it costs, and the runs it took in the simulation
## (tools/bazaar_sim.gd), for players at 50%, 70% and 90%.
##
##   godot --headless --path game --script res://tools/bazaar_balance.gd -- [--players=6]

const Sim := preload("res://tools/bazaar_sim.gd")


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var players := 6
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--players="):
			players = int(a.get_slice("=", 1))
	var rows := {}
	for p in [0.5, 0.7, 0.9]:
		rows[p] = Sim.simulate(players, p)
	var perks: Dictionary = Sim.simulate(players, 0.7, 3)
	var mid: Dictionary = rows[0.7]
	print("Players per row: %d. Scrap per run at 70%%: %.0f (Tuning.SCRAP_PER_RUN_70 = %d)" % [players,
		mid.scrap_per_run, Tuning.SCRAP_PER_RUN_70])
	print("")
	print("| Unlock | Price | Runs of Scrap at 70% | Runs since the last unlock (sim, 70%) | Run it came on (sim, 70%) |")
	print("|---|---|---|---|---|")
	for k in mid.by_item:
		var price := _price_of(k)
		print("| %s | %d | %.2f | %.2f | %.1f |" % [k, price, price / mid.scrap_per_run, mid.by_item[k], mid.first_run[k]])
	print("")
	print("| Perk (one run) | Price | Runs of Scrap at 70% |")
	print("|---|---|---|")
	for id in Tuning.PERKS:
		print("| %s | %d | %.2f |" % [Bazaar.PERKS[id].name, Tuning.PERKS[id], Tuning.PERKS[id] / mid.scrap_per_run])
	print("")
	print("| Player | Scrap per run | Runs per unlock | Unlocks | Runs |")
	print("|---|---|---|---|---|")
	for p in rows:
		var r: Dictionary = rows[p]
		print("| %d%% right | %.0f | %.2f | %d | %d |" % [roundi(p * 100), r.scrap_per_run, r.runs_per_unlock, r.unlocked, r.runs])
	print("| 70%%, a perk every 3rd run | %.0f | %.2f | %d | %d |" % [perks.scrap_per_run, perks.runs_per_unlock, perks.unlocked, perks.runs])
	quit(0)


func _price_of(key: String) -> int:
	if key.begins_with("frame:") or key.begins_with("tint:"):
		return Tuning.COSMETIC_PRICE
	var parts := key.split(" ")
	return int(Tuning.UPGRADES[parts[0]][int(parts[1]) - 1])
