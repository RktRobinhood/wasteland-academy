extends "res://tests/test_case.gd"
## Play draws only seeds the CI checks have made (#192, FAL-1038): the checker's 1 to
## VerifiedSeeds.CHECKED and the sweep's CHECKED + 1 to LAST, with boss chains to
## CHAIN_LAST. Fails if the draws, the tools' defaults or the workflows drift apart.

const StressQuestions := preload("res://tools/stress_questions.gd")
const ExportQuestions := preload("res://tools/export_questions.gd")
const NOW := 1_800_000_000
## The repo's CI, beside game/.
const WORKFLOWS := "res://../.github/workflows"
## The arguments that would change which seeds a check makes.
const RANGE_ARGS := ["--from", "--to", "--per-cell", "--per-chain", "--types"]


func test_the_checker_and_the_sweep_cover_every_seed_play_draws() -> void:
	check(ExportQuestions.PER_CELL >= VerifiedSeeds.CHECKED, "the checker makes fewer seeds per cell than CHECKED")
	check(ExportQuestions.PER_CHAIN >= VerifiedSeeds.CHECKED, "the checker makes fewer seeds per chain than CHECKED")
	check(StressQuestions.FROM <= VerifiedSeeds.CHECKED + 1, "a gap between the checker's seeds and the sweep's")
	check(StressQuestions.TO >= VerifiedSeeds.LAST, "the sweep stops before the last seed play draws")
	check(StressQuestions.FROM + StressQuestions.CHAIN_SEEDS - 1 >= VerifiedSeeds.CHAIN_LAST,
		"the sweep's boss chains stop before the last chain seed play draws")
	check(VerifiedSeeds.CHAIN_LAST <= VerifiedSeeds.LAST, "chain seeds past the cells' range")


func test_ci_runs_the_tools_on_their_default_seeds() -> void:
	var dir := ProjectSettings.globalize_path(WORKFLOWS)
	var files := DirAccess.get_files_at(dir)
	check(files.has("stress.yml"), "no stress.yml in %s" % dir)
	var runs := {"tools/stress-questions": 0, "tools/check-answers": 0}
	for f in files:
		var text := FileAccess.get_file_as_string(dir.path_join(f))
		for line in text.split("\n"):
			for tool in runs:
				if not line.contains(tool):
					continue
				runs[tool] += 1
				for arg in RANGE_ARGS:
					check(not line.contains(arg + "="), "%s narrows the seeds with %s: %s" % [f, arg, line.strip_edges()])
	for tool in runs:
		check(runs[tool] > 0, "no workflow runs %s" % tool)


func test_the_stress_sweep_runs_nightly_and_is_never_cancelled() -> void:
	var text := FileAccess.get_file_as_string(ProjectSettings.globalize_path(WORKFLOWS).path_join("stress.yml"))
	check(text.contains("schedule:") and text.contains("cron:"), "stress.yml isn't scheduled")
	check(text.contains("cancel-in-progress: false"), "stress.yml can be cancelled")
	check(not FileAccess.get_file_as_string(ProjectSettings.globalize_path(WORKFLOWS).path_join("test.yml")).contains("tools/stress-questions"),
		"the sweep is back in test.yml, where each push cancels it")


func test_the_planner_draws_only_verified_seeds() -> void:
	var save := SaveData.blank()
	for i in 400:
		var v := Planner.next(save, NOW)
		if v.has("seed"):
			check(int(v.seed) >= 1 and int(v.seed) <= VerifiedSeeds.LAST, "planner seed %d" % int(v.seed))


func test_bosses_draw_only_verified_seeds() -> void:
	var seen := 0
	for seed_no in range(1, 61):
		for kind in ["miniboss", "boss"]:
			var plan := Dungeon.boss_plan(seed_no, Dungeon.ALL, 4, kind)
			if plan.is_empty():
				continue
			seen += 1
			check(int(plan.seed) >= 1 and int(plan.seed) <= VerifiedSeeds.CHAIN_LAST, "chain seed %d" % int(plan.seed))
			if not plan.link.is_empty():
				check(int(plan.link.seed) >= 1 and int(plan.link.seed) <= VerifiedSeeds.LAST, "link seed %d" % int(plan.link.seed))
	check(seen > 0, "no boss plans to check")


func test_wrap_keeps_counting_on_inside_the_range() -> void:
	check_eq(VerifiedSeeds.wrap(1), 1)
	check_eq(VerifiedSeeds.wrap(VerifiedSeeds.LAST), VerifiedSeeds.LAST)
	check_eq(VerifiedSeeds.wrap(VerifiedSeeds.LAST + 1), 1)
	check_eq(VerifiedSeeds.wrap(0), VerifiedSeeds.LAST)
	for s in [1, 7, VerifiedSeeds.LAST]:
		for step in [1, 500, VerifiedSeeds.LAST - 1]:
			var n := VerifiedSeeds.wrap(s + step)
			check(n != s and n >= 1 and n <= VerifiedSeeds.LAST, "wrap(%d + %d) = %d" % [s, step, n])
