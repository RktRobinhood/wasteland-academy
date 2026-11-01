class_name SaveData
extends RefCounted
## The save: a versioned Dictionary in user://save.json.
##
##   version    VERSION; older saves go through migrate() on load
##   settings   {"exam_only": false}
##   course     the student's IB course (FAL-397): "aa-sl", "aa-hl", "ai-sl" or "ai-hl".
##              Courses.of(save) reads it; set_course() changes it and keeps every cell
##              record, so progress on the skills two courses share is not lost
##   cells      coverage cell key -> {"seen", "right", "wrong", "last", "last_result",
##              "misconceptions": {ref: times}, "last_misconception"}
##   probes     concept probe key -> the same record, without misconceptions
##   history    the last HISTORY cell keys asked, newest last (for spacing repeats)
##   seed       the planner's counter, so a run of questions is reproducible
##   class      the chosen class (FAL-308); null until classes exist
##   trees      skill trees (FAL-308); empty for now
##   lessons    The Relic lessons (FAL-325); empty for now
##   scrap      Scrap banked from runs, for the Bazaar (G6)
##   runs       {"played", "best_fights", "questions", "right"} over every run
##   dungeon    region id (or "all") -> {"best": deepest floor reached, "beaten":
##              [floors whose boss fell]}; a run may start on floor 1 or on the floor
##              after any beaten one
##   bazaar     what the Bazaar sold (G6, engine/bazaar.gd): {"max_hp": levels bought,
##              "lifelines": {"fifty", "hint", "freeze"} -> extra charges bought,
##              "perk": {} or {"id", "lifeline"} for the next run, "owned": cosmetic
##              ids, "frame" and "tint" worn ("" for none), "spent": Scrap spent}
##
## When a wrong answer matches a multiple-choice distractor, the distractor's
## misconception ref is recorded on the cell, so lesson feedback and suggestions can
## use it later.

const VERSION := 5
const PATH := "user://save.json"
const HISTORY := 20


static func blank() -> Dictionary:
	return {"version": VERSION, "settings": {"exam_only": false}, "course": Courses.DEFAULT, "cells": {}, "probes": {}, "history": [],
		"seed": 0, "class": null, "trees": {}, "lessons": {}, "scrap": 0,
		"runs": {"played": 0, "best_fights": 0, "questions": 0, "right": 0}, "dungeon": {},
		"bazaar": blank_bazaar()}


static func blank_bazaar() -> Dictionary:
	return {"max_hp": 0, "lifelines": {"fifty": 0, "hint": 0, "freeze": 0}, "perk": {}, "owned": [],
		"frame": "", "tint": "", "spent": 0}


## Brings any older save up to VERSION, one step at a time, then fills in fields a
## step didn't know about. A save from a newer game is kept as it is.
static func migrate(data: Dictionary) -> Dictionary:
	var out := data.duplicate(true)
	var v := int(out.get("version", 0))
	while v < VERSION:
		out = call_step(v, out)
		v += 1
		out.version = v
	var fresh := blank()
	for key in fresh:
		if not out.has(key):
			out[key] = fresh[key]
	for key in fresh.settings:
		if not out.settings.has(key):
			out.settings[key] = fresh.settings[key]
	return out


## The migration from version v to v + 1. Add a case for each new version.
static func call_step(v: int, data: Dictionary) -> Dictionary:
	match v:
		0:
			# Version 0: anything saved before saves had a version. Keep what can be
			# read; blank() fills the rest.
			var out := {}
			for key in ["settings", "cells", "probes", "history", "seed"]:
				if data.has(key):
					out[key] = data[key]
			return out
		1:
			# Version 1 to 2 (FAL-413): class is null until one is chosen, not "". A
			# save without class or trees gets them from blank(); Scrap and run
			# totals start at 0.
			var out := data.duplicate(true)
			if out.get("class") == "":
				out["class"] = null
			return out
		2:
			# Version 2 to 3 (FAL-415): the dungeon record per region. A save from
			# before floors has beaten no boss, so blank() gives it an empty one.
			return data.duplicate(true)
		3:
			# Version 3 to 4 (FAL-416): the Bazaar. Nothing could be bought before it,
			# so the record starts blank, and the Scrap banked so far is kept to spend.
			var out := data.duplicate(true)
			out["bazaar"] = blank_bazaar()
			return out
		4:
			# Version 4 to 5 (FAL-397): the IB course. Every save so far played AA SL, the
			# only course built, so that is the course it keeps.
			var out := data.duplicate(true)
			out["course"] = Courses.DEFAULT
			return out
	return data


## Puts the save on a course (Courses.ids()). Returns false, changing nothing, for an id
## courses.json doesn't list. The cell records stay: a cell is a skill's question, so a
## course that shares the skill keeps what the student has done on it.
static func set_course(data: Dictionary, course: String) -> bool:
	if not Courses.has(course):
		return false
	data["course"] = course
	return true


static func load_from(path: String = PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return blank()
	var f := FileAccess.open(path, FileAccess.READ)
	var parsed = JSON.parse_string(f.get_as_text()) if f != null else null
	if not parsed is Dictionary:
		push_warning("SaveData: %s is not a save; starting fresh" % path)
		return blank()
	return migrate(parsed)


static func store(data: Dictionary, path: String = PATH) -> bool:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		push_warning("SaveData: can't write %s" % path)
		return false
	f.store_string(JSON.stringify(data, "\t"))
	return true


## Records one answer. key is a cell key (or a probe key with probe = true);
## misconception is the ref of the wrong option the answer matched, or "".
static func record(data: Dictionary, key: String, right: bool, now: int, misconception: String = "", probe: bool = false) -> void:
	var book: Dictionary = data.probes if probe else data.cells
	var r: Dictionary = book.get(key, {"seen": 0, "right": 0, "wrong": 0, "last": 0, "last_result": ""})
	r.seen = int(r.seen) + 1
	if right:
		r.right = int(r.right) + 1
	else:
		r.wrong = int(r.wrong) + 1
	r.last = now
	r.last_result = "right" if right else "wrong"
	if not probe:
		var mis: Dictionary = r.get("misconceptions", {})
		if misconception != "":
			mis[misconception] = int(mis.get(misconception, 0)) + 1
		r.misconceptions = mis
		r.last_misconception = misconception
	book[key] = r
	var hist: Array = data.history
	hist.append(key)
	while hist.size() > HISTORY:
		hist.pop_front()
