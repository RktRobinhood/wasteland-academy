extends "res://tests/test_case.gd"
## The planner and the save (FAL-310 plan): never-seen cells first, then recent wrong
## ones, then exam frequency; "Exam-style only"; the versioned save.

const NOW := 1_800_000_000


func _all_seen(save: Dictionary, right: bool) -> void:
	for c in QuestionEngine.cells():
		SaveData.record(save, c.key, right, NOW - 1000)
	for p in QuestionEngine.probes():
		SaveData.record(save, p.key, right, NOW - 1000, "", true)


func test_never_seen_cells_come_first() -> void:
	var save := SaveData.blank()
	var seen := {}
	for i in 200:
		var v := Planner.next(save, NOW)
		if v.rule == "probe":
			SaveData.record(save, "%s|concept|%d" % [v.type, v.probe], true, NOW, "", true)
			continue
		check_eq(v.rule, "unseen")
		var key := QuestionEngine.cell_key(v.type, v.unknown, v.rep, v.angle)
		check(not seen.has(key), "a seen cell came back while others were unseen")
		seen[key] = true
		SaveData.record(save, key, true, NOW)
		if seen.size() == QuestionEngine.cells().size():
			break
	check_eq(seen.size(), QuestionEngine.cells().size(), "every cell was served once")


func test_recent_wrong_cells_come_back_spaced() -> void:
	var save := SaveData.blank()
	_all_seen(save, true)
	var key: String = QuestionEngine.cells()[10].key
	SaveData.record(save, key, false, NOW - 60)
	# Just answered: it waits SPACING questions.
	var v := Planner.next(save, NOW)
	check(v.rule != "wrong", "a just-missed cell came straight back")
	for i in Planner.SPACING:
		save.history.append("filler|%d" % i)
	var found := false
	for i in 6:
		v = Planner.next(save, NOW)
		if v.rule == "wrong":
			check_eq(QuestionEngine.cell_key(v.type, v.unknown, v.rep, v.angle), key)
			found = true
			break
	check(found, "the wrong cell came back")


func test_old_wrong_answers_fall_to_frequency() -> void:
	var save := SaveData.blank()
	_all_seen(save, true)
	SaveData.record(save, QuestionEngine.cells()[3].key, false, NOW - Planner.RECENT - 10)
	for i in Planner.SPACING:
		save.history.append("filler|%d" % i)
	for i in 10:
		check(Planner.next(save, NOW).rule in ["frequency", "probe"])


func test_exam_only_follows_exam_frequency() -> void:
	var save := SaveData.blank()
	save.settings.exam_only = true
	var counts := {}
	var n := 3000
	for i in n:
		var v := Planner.next(save, NOW)
		check_eq(v.rule, "frequency")
		var c := QuestionEngine.cells(true).filter(func(x): return x.key == QuestionEngine.cell_key(v.type, v.unknown, v.rep, v.angle))
		check(c.size() == 1, "not an exam cell")
		counts[v.type] = int(counts.get(v.type, 0)) + 1
		if failures.size() > 3:
			return
	check(not counts.has("fn-concept-quadratic-forms"))
	# fn-quadratic-features is asked in 11 bank parts, fn-quadratic-from-conditions in 7.
	var share := float(counts.get("fn-quadratic-features", 0)) / n
	check(absf(share - 11.0 / 18.0) < 0.04, "features share %.3f, expected about %.3f" % [share, 11.0 / 18.0])


func test_planner_is_reproducible() -> void:
	var a := SaveData.blank()
	var b := SaveData.blank()
	for i in 20:
		check_eq(Planner.next(a, NOW), Planner.next(b, NOW))


func test_planner_views_make_questions() -> void:
	var save := SaveData.blank()
	for i in 60:
		var v := Planner.next(save, NOW)
		var q := QuestionEngine.probe(v.type, v.probe) if v.format == "probe" else QuestionEngine.make(v)
		check(not q.has("error"), str(v))
		SaveData.record(save, q.cell, i % 3 != 0, NOW, "", v.format == "probe")


# ── Save ─────────────────────────────────────────────────────

func test_blank_save() -> void:
	var s := SaveData.blank()
	check_eq(s.version, SaveData.VERSION)
	check_eq(s.settings.exam_only, false, "exam-only is off by default")
	for key in ["class", "trees", "lessons", "cells", "probes"]:
		check(s.has(key), key)
	check_eq(s["class"], "")
	check_eq(s.trees, {})
	check_eq(s.lessons, {})


func test_migrates_an_unversioned_save() -> void:
	var old := {"cells": {"x|y|z|w": {"seen": 2, "right": 1, "wrong": 1, "last": 5, "last_result": "wrong"}}, "junk": 1}
	var s := SaveData.migrate(old)
	check_eq(s.version, SaveData.VERSION)
	check_eq(s.cells["x|y|z|w"].seen, 2)
	check(not s.has("junk"))
	check(s.has("lessons") and s.has("trees") and s.has("class"))
	check_eq(s.settings.exam_only, false)


func test_keeps_a_newer_save() -> void:
	var s := SaveData.migrate({"version": SaveData.VERSION + 1, "cells": {}, "future": true})
	check_eq(s.version, SaveData.VERSION + 1)
	check(s.future)


func test_records_cells_and_misconceptions() -> void:
	var s := SaveData.blank()
	SaveData.record(s, "c1", false, 100, "SL2.6.vertex#0")
	SaveData.record(s, "c1", true, 200)
	SaveData.record(s, "c1", false, 300, "SL2.6.vertex#0")
	var r: Dictionary = s.cells.c1
	check_eq([r.seen, r.right, r.wrong, r.last, r.last_result], [3, 1, 2, 300, "wrong"])
	check_eq(r.misconceptions, {"SL2.6.vertex#0": 2})
	check_eq(r.last_misconception, "SL2.6.vertex#0")
	check_eq(s.history, ["c1", "c1", "c1"])


func test_store_and_load() -> void:
	var path := "user://test_save_roundtrip.json"
	var s := SaveData.blank()
	SaveData.record(s, "c1", true, 100)
	s.settings.exam_only = true
	check(SaveData.store(s, path))
	var back := SaveData.load_from(path)
	check_eq(back.cells.c1.right, 1)
	check_eq(back.settings.exam_only, true)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	check_eq(SaveData.load_from("user://no_such_save.json"), SaveData.blank())
