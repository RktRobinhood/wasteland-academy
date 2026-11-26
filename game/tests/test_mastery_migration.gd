extends "res://tests/test_case.gd"
## Save v7 -> v8: mastery back-filled from the cell counts (#268, FAL-1668, ADR-0002;
## docs/proposals/mastery-calibration.md §8, accepted 2026-11-25 on FAL-1603). The tests
## are the proposal's §11 check 10: cells, probes and history stay byte-for-byte, the
## migration is deterministic, migrated evidence stays below L4, and v8 -> v7 -> v8
## round-trips.
##
##   godot --headless --path game --script res://tests/run_tests.gd -- --only=mastery_migration

const E := preload("res://engine/maths_engine.gd")
const Study := preload("res://ui/study.gd")
const STUDY_FILE := "user://test_mastery_migration_study.json"


## The first AA SL cells whose unknown lists n skills, at the given level.
static func _cells(n_skills: int, level: int, count: int) -> Array:
	var out := []
	for c in E.requests("aa-sl"):
		if int(c.level) != level:
			continue
		if QuestionEngine.unknown_of(QuestionEngine.type_of(c.type), c.unknown).get("skills", []).size() == n_skills:
			out.append(c)
			if out.size() == count:
				break
	return out


static func _skills(c: Dictionary) -> Array:
	return QuestionEngine.unknown_of(QuestionEngine.type_of(c.type), c.unknown).get("skills", [])


static func _cell(right: int, wrong: int, last: int) -> Dictionary:
	return {"seen": right + wrong, "right": right, "wrong": wrong, "last": last,
		"last_result": "right" if right > 0 else "wrong", "misconceptions": {}, "last_misconception": ""}


## A v7 save as a v7 build wrote it: no mastery, version 7, real cells, a probe, a
## history, and one cell key the catalogue no longer has.
static func _v7_save() -> Dictionary:
	var s := SaveData.blank()
	s.erase("mastery")
	s.version = 7
	var d2: Array = _cells(1, 2, 1)
	var d3: Array = _cells(1, 3, 2)
	var multi: Array = _cells(2, 3, 1)
	s.cells[d2[0].key] = _cell(6, 2, 1764000100)
	s.cells[d3[0].key] = _cell(5, 1, 1764000300)
	s.cells[d3[1].key] = _cell(9, 0, 1764000200)
	s.cells[multi[0].key] = _cell(1, 3, 1764000400)
	s.cells["gone-type|gone|r|a"] = _cell(4, 0, 1764000500)
	s.probes["sequences|concept|0"] = {"seen": 2, "right": 1, "wrong": 1, "last": 1764000050, "last_result": "wrong"}
	s.history = [d2[0].key, d3[0].key, multi[0].key, "sequences|concept|0"]
	s.scrap = 42
	return s


static func _bytes(v: Variant) -> String:
	return JSON.stringify(v)


## v as it reads back from a file: JSON numbers come back as floats, so a value that went
## through a file is compared with the other side's file form.
static func _filed(v: Variant) -> String:
	return JSON.stringify(JSON.parse_string(JSON.stringify(v)))


# ── The step adds mastery and changes nothing else ───────────

func test_the_save_is_version_8_and_a_blank_save_has_empty_mastery() -> void:
	check_eq(SaveData.VERSION, 8)
	var s := SaveData.blank()
	check_eq(_bytes(s.mastery), _bytes(E.blank_mastery()), "a new save starts with no skill records")


func test_cells_probes_history_and_game_fields_stay_byte_for_byte() -> void:
	var v7 := _v7_save()
	var v8 := SaveData.migrate(v7)
	check_eq(int(v8.version), 8)
	for key in v7:
		if key == "version":
			continue
		check_eq(_bytes(v8[key]), _bytes(v7[key]), "%s is kept byte-for-byte" % key)
	var added := []
	for key in v8:
		if not v7.has(key):
			added.append(key)
	check_eq(added, ["mastery"], "the step adds mastery and nothing else")
	check_eq(int(v7.version), 7, "migrate works on a copy")


func test_every_skill_with_catalogue_evidence_gets_a_migrated_record() -> void:
	var v7 := _v7_save()
	var book: Dictionary = SaveData.migrate(v7).mastery.skills
	var expected := {}
	for c in E.requests():
		if v7.cells.has(c.key):
			for s in _skills(c):
				expected[s] = true
	check(not expected.is_empty())
	var got := book.keys()
	got.sort()
	var want := expected.keys()
	want.sort()
	check_eq(got, want, "one record per skill the replayed cells test; the stale cell is skipped")
	for s in book:
		check(bool(book[s].migrated), "%s is marked migrated" % s)
		check_eq(int(book[s].exam_ok), 0, "%s: migrated evidence never counts toward Exam Ready" % s)


func test_the_replay_order_spreads_misses_evenly_misses_first() -> void:
	check_eq(E.migration_order(0, 0), [])
	check_eq(E.migration_order(1, 1), ["wrong", "right"], "a tie puts the miss first")
	check_eq(E.migration_order(3, 1), ["wrong", "right", "right", "right"])
	check_eq(E.migration_order(6, 2), ["wrong", "right", "right", "right", "wrong", "right", "right", "right"])
	check_eq(E.migration_order(0, 2), ["wrong", "wrong"])
	for rw in [[5, 1], [12, 3], [1, 7], [9, 0]]:
		var order := E.migration_order(rw[0], rw[1])
		check_eq(order.count("right"), rw[0])
		check_eq(order.count("wrong"), rw[1])


func test_the_replay_matches_a_hand_run_of_the_update() -> void:
	# One single-skill d3 cell, replayed by hand through mastery_update: the same record.
	var c: Dictionary = _cells(1, 3, 1)[0]
	var skill: String = _skills(c)[0]
	var ev := {"cells": {c.key: _cell(5, 1, 1764000300)}}
	var rec := {}
	for outcome in ["wrong", "right", "right", "right", "right", "right"]:
		rec = E.mastery_update(rec, 3, E.skill_top(skill), outcome, ["migrated"], c.key, 1.0, 1764000300)
	check_eq(_bytes(E.backfill_mastery(ev).skills[skill]), _bytes(rec))


# ── Deterministic, and capped below L4 ───────────────────────

func test_the_migration_is_deterministic() -> void:
	var a := _bytes(SaveData.migrate(_v7_save()).mastery)
	var b := _bytes(SaveData.migrate(_v7_save()).mastery)
	check_eq(a, b, "the same v7 save always gives the same v8 mastery")
	# Key order in the stored dictionary does not matter: the replay sorts the keys.
	var v7 := _v7_save()
	var reversed := {}
	var keys: Array = v7.cells.keys()
	keys.reverse()
	for k in keys:
		reversed[k] = v7.cells[k]
	v7.cells = reversed
	check_eq(_bytes(SaveData.migrate(v7).mastery), a, "cell order in the file does not change the result")


func test_migrated_evidence_stays_below_level_4() -> void:
	# Far more right answers than a learner needs for L4, on every exam-tier cell of a skill.
	var c: Dictionary = _cells(1, 3, 1)[0]
	var skill: String = _skills(c)[0]
	var v7 := _v7_save()
	v7.cells.clear()
	for r in E.requests():
		if _skills(r).has(skill):
			v7.cells[r.key] = _cell(40, 0, 1764000000)
	var rec: Dictionary = SaveData.migrate(v7).mastery.skills[skill]
	check(float(rec.m) <= E.MASTERY_ASSISTED_CAP, "the rating stops at 3.999 (got %.4f)" % float(rec.m))
	check_eq(int(rec.exam_ok), 0)
	var shown := E.mastery(SaveData.migrate(v7), skill)
	check_eq(int(shown.level), 3, "migrated evidence alone shows L3 at most")
	check(not bool(shown.exam_ready))


func test_two_live_exam_tier_successes_then_open_level_4() -> void:
	# The proposal's example: after the back-fill, two unassisted d3 successes open L4.
	var c: Dictionary = _cells(1, 3, 1)[0]
	var skill: String = _skills(c)[0]
	var v7 := _v7_save()
	v7.cells.clear()
	for r in E.requests():
		if _skills(r).has(skill):
			v7.cells[r.key] = _cell(40, 0, 1764000000)
	var v8 := SaveData.migrate(v7)
	var rec: Dictionary = v8.mastery.skills[skill]
	var top := E.skill_top(skill)
	for i in 2:
		rec = E.mastery_update(rec, 3, top, "right", [], "live|%d" % i, 1.0, 1764100000)
	check(not bool(rec.migrated), "a live answer ends the migrated state")
	check_eq(int(rec.exam_ok), 2)
	check(E.mastery_level(rec, E.skill_cells(skill)) >= 4, "L4 opens on live exam-tier evidence")


func test_a_multi_skill_miss_shares_one_answers_worth_of_blame() -> void:
	var c: Dictionary = _cells(2, 3, 1)[0]
	var skills := _skills(c)
	var book: Dictionary = E.backfill_mastery({"cells": {c.key: _cell(0, 1, 1)}}).skills
	# Both start at 1.0, so each takes half a miss; both stay on the floor.
	for s in skills:
		check(book.has(s), "%s gets a record from the multi-skill cell" % s)
		check_eq(float(book[s].m), E.MASTERY_FLOOR)
		check_eq(int(book[s].n), 1)


func test_record_times_are_the_latest_cell_answer() -> void:
	var v8 := SaveData.migrate(_v7_save())
	var newest := 0
	for k in v8.cells:
		newest = maxi(newest, int(v8.cells[k].last))
	for s in v8.mastery.skills:
		check(int(v8.mastery.skills[s].last) <= newest)
		check(int(v8.mastery.skills[s].last) > 0, "%s keeps a time for display" % s)


func test_a_save_with_no_cells_migrates_to_empty_mastery() -> void:
	var s := SaveData.blank()
	s.erase("mastery")
	s.version = 7
	check_eq(_bytes(SaveData.migrate(s).mastery), _bytes(E.blank_mastery()), "nothing answered, nothing invented")
	var old := SaveData.migrate({"version": 0, "cells": {}})
	check_eq(int(old.version), 8)
	check(old.mastery.skills.is_empty())


# ── Downgrade for export and import ──────────────────────────

func test_downgrade_drops_mastery_and_gives_the_v7_save_back() -> void:
	var v7 := _v7_save()
	var v8 := SaveData.migrate(v7)
	var back := SaveData.downgrade(v8, 7)
	check_eq(_bytes(back), _bytes(v7), "v8 -> v7 gives back the v7 save exactly")
	check(v8.has("mastery"), "downgrade works on a copy")
	check(SaveData.downgrade(v8, 6).is_empty(), "only 8 -> 7 is supported")
	check_eq(_bytes(SaveData.downgrade(v8, 8)), _bytes(v8))


func test_v8_to_v7_to_v8_round_trips() -> void:
	var v8 := SaveData.migrate(_v7_save())
	var again := SaveData.migrate(SaveData.downgrade(v8, 7))
	check_eq(_bytes(again), _bytes(v8), "a back-filled v8 save survives a trip through v7 unchanged")


func test_round_trip_after_live_answers_keeps_every_v7_field() -> void:
	# Live mastery is v8-only: through a v7 build it is rebuilt from the cells as migrated,
	# and everything a v7 build keeps comes back byte-for-byte.
	var v8 := SaveData.migrate(_v7_save())
	var key: String = _cells(1, 3, 1)[0].key
	SaveData.record(v8, key, true, 1764200000)
	var again := SaveData.migrate(SaveData.downgrade(v8, 7))
	for k in v8:
		if k != "mastery":
			check_eq(_bytes(again[k]), _bytes(v8[k]), "%s survives the round trip" % k)
	check_eq(_bytes(again.mastery), _bytes(E.backfill_mastery(v8)))


func test_export_for_an_older_build_imports_back() -> void:
	var v8 := SaveData.migrate(_v7_save())
	var code := SaveData.export_code(v8, 7)
	var parsed := SaveData.parse(Marshalls.base64_to_utf8(code.substr(SaveData.CODE_PREFIX.length())))
	check_eq(int(parsed.version), 7, "the code is a v7 save")
	check(not parsed.has("mastery"))
	var read := SaveData.import_text(code)
	check(bool(read.ok))
	check_eq(_filed(read.save), _filed(v8), "this build imports it back to the same v8 save")
	var as_text := SaveData.import_text(SaveData.export_text(v8, 7))
	check_eq(_filed(as_text.save), _filed(v8))
	check_eq(int(SaveData.parse(SaveData.export_text(v8)).version), 8, "the default export is this build's version")


# ── The study evidence file gets the same addition ───────────

func test_study_evidence_without_mastery_is_back_filled() -> void:
	var v7 := _v7_save()
	var old := {"cells": v7.cells, "probes": v7.probes, "history": v7.history}
	var f := FileAccess.open(STUDY_FILE, FileAccess.WRITE)
	f.store_string(JSON.stringify(old, "\t"))
	f.close()
	var ev: Dictionary = Study._load_evidence(STUDY_FILE)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(STUDY_FILE))
	for k in ["cells", "probes", "history"]:
		check_eq(_filed(ev[k]), _filed(old[k]), "study %s kept byte-for-byte" % k)
	check_eq(_filed(ev.mastery), _filed(SaveData.migrate(v7).mastery), "the same back-fill as the game save")


func test_study_evidence_with_mastery_is_read_as_it_is() -> void:
	var ev := E.blank_evidence()
	E.record_key(ev, _cells(1, 3, 1)[0].key, true, 1)
	var f := FileAccess.open(STUDY_FILE, FileAccess.WRITE)
	f.store_string(JSON.stringify(ev, "\t"))
	f.close()
	var read: Dictionary = Study._load_evidence(STUDY_FILE)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(STUDY_FILE))
	check(read.mastery.skills.is_empty(), "stored mastery is not rebuilt")
