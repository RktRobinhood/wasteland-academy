class_name SaveData
extends RefCounted
## The save: a versioned Dictionary in user://save.json.
##
## One document with a version and migrations (#202): question results are keyed by
## cell key and lesson progress by explainer id, both permanent ids. Writes go through
## <path>.tmp and keep <path>.bak; a file that can't be read is set aside, never
## overwritten. export_code() and import_text() move a save between devices; nothing is
## sent anywhere.
##
##   version    VERSION; older saves go through migrate() on load
##   settings   {"exam_only": false, "reduced_motion": false, "timer": 1.0, "larger_text":
##              false}; reduced_motion cuts between the map's layers instead of zooming
##              (ui/map.gd) and stills the fight (ui/fight.gd); timer is the clock's
##              multiplier, one of Tuning.TIMER_CHOICES (0.0 for off, #196); larger_text
##              raises the text sizes (UiTheme.set_larger_text)
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
##              ids, "frame" and "tint" worn ("" for none), "spent": Scrap spent,
##              "met": true once the store owner has said their first-visit line}
##   here       the place on the world map the player last went into (FAL-988): an
##              island id, "thunderdome" or "bazaar", where the map's "you are here"
##              marker stands. A new save starts at the Bazaar
##   intro      {"course": true once the student has picked their course, "cards": true once
##              they have seen or skipped the "How a fight works" cards} (FAL-1041, #186). A
##              blank save has both false, so the first launch asks for the course; every
##              older save counts as done, because it already plays a course
##   watched    the tutor lessons played to the end (#218, ui/lesson/lesson_player.gd), by
##              explainer id, oldest first. A recall section picks its version from it
##
## When a wrong answer matches a multiple-choice distractor, the distractor's
## misconception ref is recorded on the cell, so lesson feedback and suggestions can
## use it later.

const VERSION := 7
const PATH := "user://save.json"
const HISTORY := MathsEngine.HISTORY


static func blank() -> Dictionary:
	return {"version": VERSION, "settings": {"exam_only": false, "reduced_motion": false, "timer": 1.0, "larger_text": false}, "course": Courses.DEFAULT, "cells": {}, "probes": {}, "history": [],
		"seed": 0, "class": null, "trees": {}, "lessons": {}, "scrap": 0,
		"runs": {"played": 0, "best_fights": 0, "questions": 0, "right": 0}, "dungeon": {},
		"bazaar": blank_bazaar(), "here": "bazaar", "watched": [], "intro": {"course": false, "cards": false}}


static func blank_bazaar() -> Dictionary:
	return {"max_hp": 0, "lifelines": {"fifty": 0, "hint": 0, "freeze": 0}, "perk": {}, "owned": [],
		"frame": "", "tint": "", "spent": 0, "met": false}


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
		5:
			# Version 5 to 6 (FAL-988): where the player is on the world map. No save
			# recorded it before, so every one starts at the Bazaar, as a new save does.
			var out := data.duplicate(true)
			out["here"] = "bazaar"
			return out
		6:
			# Version 6 to 7 (FAL-1041): the first-run steps. A save that exists has
			# played, so it is not asked for its course or shown the cards.
			var out := data.duplicate(true)
			out["intro"] = {"course": true, "cards": true}
			return out
	return data


## Puts the save on a course (Courses.ids()). Returns false, changing nothing, for an id
## courses.json doesn't list. The cell records stay: a cell is a skill's question, so a
## course that shares the skill keeps what the student has done on it.
static func set_course(data: Dictionary, course: String) -> bool:
	if not Courses.has(course):
		return false
	data["course"] = course
	if data.get("intro") is Dictionary:
		data.intro["course"] = true
	return true


## True while a new save has not picked its course (first launch, #186).
static func needs_course(data: Dictionary) -> bool:
	return not bool((data.get("intro", {}) as Dictionary).get("course", true))


## True while a new save has not seen the "How a fight works" cards.
static func needs_cards(data: Dictionary) -> bool:
	return not bool((data.get("intro", {}) as Dictionary).get("cards", true))


## Reads the save at path. A missing file is a new save. A file that can't be read
## (truncated, corrupt, not a save) is never thrown away: it is set aside as
## <name>.unreadable-<time>.json beside it, and the .bak of the last good write is used
## if there is one, otherwise the player starts blank.
static func load_from(path: String = PATH) -> Dictionary:
	if not FileAccess.file_exists(path):
		return blank()
	var parsed := _read_save(path)
	if not parsed.is_empty():
		return migrate(parsed)
	var kept := set_aside(path)
	push_warning("SaveData: %s is not a save; kept as %s" % [path, kept])
	var from_bak := _read_save(backup_path(path))
	if not from_bak.is_empty():
		return migrate(from_bak)
	return blank()


static func backup_path(path: String = PATH) -> String:
	return path + ".bak"


static func temp_path(path: String = PATH) -> String:
	return path + ".tmp"


## The save in the file at path, or {} if it is missing or isn't a save (a JSON object
## with a "version" number).
static func _read_save(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	return parse(f.get_as_text())


## The save in a JSON text, or {} if the text isn't one.
static func parse(text: String) -> Dictionary:
	var parsed = JSON.parse_string(text)
	if not parsed is Dictionary or not (parsed.get("version") is float or parsed.get("version") is int):
		return {}
	return parsed


## Moves an unreadable save out of the way, to <name>.unreadable-<time>.json in the same
## folder. Returns the new path, or "" if it could not be moved.
static func set_aside(path: String) -> String:
	var stamp := int(Time.get_unix_time_from_system())
	var kept := ""
	var n := 0
	while kept == "" or FileAccess.file_exists(kept):
		kept = "%s.unreadable-%d%s.json" % [path.get_basename(), stamp, "" if n == 0 else "-%d" % n]
		n += 1
	if DirAccess.rename_absolute(path, kept) == OK:
		return kept
	# A rename can fail where a copy works; either way the bytes stay.
	if DirAccess.copy_absolute(path, kept) == OK:
		DirAccess.remove_absolute(path)
		return kept
	return ""


## Writes the save safely: to <path>.tmp first, checked by reading it back, then the
## last good file becomes <path>.bak and the temp file takes its place. A write that
## dies halfway leaves the old save, or its .bak, whole.
static func store(data: Dictionary, path: String = PATH) -> bool:
	var tmp := temp_path(path)
	var f := FileAccess.open(tmp, FileAccess.WRITE)
	if f == null:
		push_warning("SaveData: can't write %s" % tmp)
		return false
	var text := JSON.stringify(data, "\t")
	f.store_string(text)
	f.flush()
	f.close()
	if parse(FileAccess.get_file_as_string(tmp)).is_empty():
		push_warning("SaveData: %s did not read back; keeping %s" % [tmp, path])
		DirAccess.remove_absolute(tmp)
		return false
	if FileAccess.file_exists(path):
		if DirAccess.copy_absolute(path, backup_path(path)) != OK:
			push_warning("SaveData: can't write %s" % backup_path(path))
	if DirAccess.rename_absolute(tmp, path) != OK:
		# Some platforms won't rename over a file. The .bak holds the old save.
		DirAccess.remove_absolute(path)
		if DirAccess.rename_absolute(tmp, path) != OK:
			push_warning("SaveData: can't replace %s" % path)
			return false
	return true


## The save as a code a student can copy: "WA-SAVE-1:" and the JSON, base64 encoded.
## It is one line, with no characters a chat app or a form field will change.
const CODE_PREFIX := "WA-SAVE-1:"


static func export_code(data: Dictionary) -> String:
	return CODE_PREFIX + Marshalls.utf8_to_base64(JSON.stringify(data))


## The exported file's text: the JSON itself.
static func export_text(data: Dictionary) -> String:
	return JSON.stringify(data, "\t")


## Reads what a student pasted or opened: an export code or the exported JSON. Returns
## {"ok": true, "save": migrated save} or {"ok": false, "error": a sentence for the
## student}. Nothing is written; the caller stores the save once the student agrees.
static func import_text(text: String) -> Dictionary:
	var t := text.strip_edges()
	if t.begins_with(CODE_PREFIX):
		t = t.substr(CODE_PREFIX.length()).replace("\n", "").replace(" ", "")
		t = Marshalls.base64_to_utf8(t)
	var parsed := parse(t)
	if parsed.is_empty():
		return {"ok": false, "error": "That isn't a Wasteland Academy save. Copy the whole code again, or choose the exported file."}
	if int(parsed.version) > VERSION:
		return {"ok": false, "error": "That save is from a newer version of the game. Update the game, then try again."}
	return {"ok": true, "save": migrate(parsed)}


## Puts an imported save in place of the one at path. The save being replaced is first
## copied to <name>.before-import-<time>.json, so an import is never a loss. Returns
## false if it could not be written.
static func replace_with(data: Dictionary, path: String = PATH) -> bool:
	if FileAccess.file_exists(path):
		var kept := "%s.before-import-%d.json" % [path.get_basename(), int(Time.get_unix_time_from_system())]
		DirAccess.copy_absolute(path, kept)
	return store(data, path)


## Records one answer (MathsEngine.record_key: the save is the engine's evidence). key
## is a cell key (or a probe key with probe = true); misconception is the ref of the
## wrong option the answer matched, or "".
static func record(data: Dictionary, key: String, right: bool, now: int, misconception: String = "", probe: bool = false) -> void:
	MathsEngine.record_key(data, key, right, now, misconception, probe)
