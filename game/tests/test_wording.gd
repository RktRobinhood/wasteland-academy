extends "res://tests/test_case.gd"
## Player-facing wording (GitHub #203, #186; FAL-1041): the string literals in the UI
## scripts and scenes, and the text fields of the data files, must not use a word the
## glossary bans (writing/glossary.json, the machine copy of writing/glossary.md). Above
## all: no "island" anywhere a player reads.
##
## What is checked is what a player can read: a string literal in game/ui/*.gd,
## game/audio/*.gd, game/engine/{bazaar,dungeon}.gd and the `text =` of game/scenes/*.tscn,
## and the name, taunt, label, hit, done and lines fields of game/data/*.json and
## assets/journey. Comments, ids (an all-lowercase word like "island"), node names, save
## keys, routes and dictionary keys are not. The study screen and the question explorer
## are plain or developer tools and are left out (string audit, "Not covered here").

const GLOSSARY := "res://../writing/glossary.json"
const SCRIPT_DIRS := ["res://ui", "res://audio"]
const SCRIPT_FILES := ["res://engine/bazaar.gd", "res://engine/dungeon.gd"]
const SKIP := ["study.gd", "explorer.gd"]
const DATA_FIELDS := ["name", "taunt", "label", "hit", "done", "lines", "text"]
## A line that names a node, a meta key or a signal is wiring, not text.
const WIRING := [".name =", "get_node", "_layer(", "find_child", "has_node", "set_meta", "get_meta", "\"screen\"", "NodePath", "preload(", "load("]

var _banned: Array = []
var _regex := {}


func _load() -> void:
	if not _banned.is_empty():
		return
	var d = JSON.parse_string(FileAccess.get_file_as_string(GLOSSARY))
	check(d is Dictionary, "glossary.json can't be read")
	if not d is Dictionary:
		return
	_banned = d.banned
	for b in _banned:
		var re := RegEx.new()
		var err := re.compile(b.pattern if b.get("case_sensitive", false) else "(?i)" + b.pattern)
		check(err == OK, "bad pattern for %s" % b.id)
		_regex[b.id] = re


## The string literals on a line of GDScript, with the line's comment cut off.
static func literals(line: String) -> Array:
	var out: Array = []
	var cur := ""
	var in_str := false
	var i := 0
	while i < line.length():
		var ch := line[i]
		if in_str:
			if ch == "\\" and i + 1 < line.length():
				cur += line[i + 1]
				i += 2
				continue
			if ch == "\"":
				in_str = false
				var rest := line.substr(i + 1).strip_edges(true, false)
				# A dictionary key: "name": value
				if not (rest.begins_with(":") and not rest.begins_with(":=")):
					out.append(cur)
				cur = ""
			else:
				cur += ch
		elif ch == "\"":
			in_str = true
		elif ch == "#":
			break
		i += 1
	return out


## An id, a key or a path: lowercase letters, digits and the joiners, no spaces.
static func is_id(s: String) -> bool:
	var re := RegEx.new()
	re.compile("^[a-z0-9_\\-./:#?=&%]*$")
	return re.search(s) != null


## The player-facing strings of a script, as [text, "file:line"].
static func script_strings(path: String) -> Array:
	var out: Array = []
	var n := 0
	for line in FileAccess.get_file_as_string(path).split("\n"):
		n += 1
		var stripped := line.strip_edges()
		if stripped.begins_with("#") or stripped.begins_with("##"):
			continue
		var wired := false
		for w in WIRING:
			if line.contains(w):
				wired = true
		if wired:
			continue
		for lit in literals(line):
			if not is_id(lit):
				out.append([lit, "%s:%d" % [path, n]])
	return out


func _scripts() -> Array:
	var out: Array = SCRIPT_FILES.duplicate()
	for dir in SCRIPT_DIRS:
		for f in DirAccess.get_files_at(dir):
			if f.ends_with(".gd") and not f in SKIP:
				out.append("%s/%s" % [dir, f])
	return out


func _scene_strings() -> Array:
	var out: Array = []
	var re := RegEx.new()
	re.compile("^text = \"(.*)\"$")
	for f in DirAccess.get_files_at("res://scenes"):
		if not f.ends_with(".tscn") or f in ["study.tscn", "explorer.tscn"]:
			continue
		var n := 0
		for line in FileAccess.get_file_as_string("res://scenes/" + f).split("\n"):
			n += 1
			var m := re.search(line)
			if m != null:
				out.append([m.get_string(1), "res://scenes/%s:%d" % [f, n]])
	return out


func _data_strings(node: Variant, path: String, out: Array, under_field: bool = false) -> void:
	if node is Dictionary:
		for k in node:
			_data_strings(node[k], path, out, String(k) in DATA_FIELDS)
	elif node is Array:
		for v in node:
			_data_strings(v, path, out, under_field)
	elif node is String and under_field:
		out.append([node, path])


func _data_files(dir: String, out: Array) -> void:
	for f in DirAccess.get_files_at(dir):
		if f.ends_with(".json"):
			out.append(dir.path_join(f))
	for d in DirAccess.get_directories_at(dir):
		_data_files(dir.path_join(d), out)


## Every banned pattern against one string. `scope` is "ui" for UI strings (every
## pattern applies) and "all" for data text (only the patterns marked "all").
func _hits(text: String, where: String, scope: String) -> Array:
	var out: Array = []
	for b in _banned:
		if scope == "all" and b.scope != "all":
			continue
		if text in b.get("allow", []):
			continue
		if _regex[b.id].search(text) != null:
			out.append("%s: \"%s\" (%s; use %s)" % [where, text, b.id, b.use])
	return out


func test_no_ui_string_uses_a_banned_word() -> void:
	_load()
	var seen := 0
	var hits: Array = []
	var strings := _scene_strings()
	for path in _scripts():
		strings.append_array(script_strings(path))
	for s in strings:
		seen += 1
		hits.append_array(_hits(s[0], s[1], "ui"))
	check(seen > 300, "only %d UI strings found; the scanner is broken" % seen)
	check(hits.is_empty(), "banned words in UI strings:\n  " + "\n  ".join(hits))


func test_no_data_text_says_island() -> void:
	_load()
	var files: Array = []
	_data_files("res://data", files)
	_data_files(ProjectSettings.globalize_path("res://").path_join("../assets/journey").simplify_path(), files)
	var strings: Array = []
	for f in files:
		var d = JSON.parse_string(FileAccess.get_file_as_string(f))
		if d != null:
			_data_strings(d, f, strings)
	check(strings.size() > 100, "only %d data strings found" % strings.size())
	var hits: Array = []
	for s in strings:
		hits.append_array(_hits(s[0], s[1], "all"))
	check(hits.is_empty(), "banned words in data text:\n  " + "\n  ".join(hits))


func test_the_scanner_finds_what_it_should() -> void:
	_load()
	check_eq(literals("x.text = \"Back to the map\" # \"island\""), ["Back to the map"])
	check_eq(literals("{\"island\": \"Every island mixed\"}"), ["Every island mixed"])
	check(not _hits("Every island mixed", "t", "ui").is_empty(), "island")
	check(not _hits("Floor 3", "t", "ui").is_empty(), "floor")
	check(not _hits("Exam-style only: on", "t", "ui").is_empty(), "exam-style")
	check(not _hits("Missed. −20 HP.", "t", "ui").is_empty(), "missed")
	check(not _hits("Engine", "t", "ui").is_empty(), "Engine")
	check(_hits("Engine Core", "t", "ui").is_empty(), "Engine Core is a place")
	check(_hits("◂ Signal Tower", "t", "ui").is_empty(), "a back button")
	check(_hits("Exam questions plus training", "t", "ui").is_empty(), "the exam switch")
	check(is_id("island") and not is_id("Island") and not is_id("every island"), "ids")


func test_the_glossary_names_the_places_the_map_shows() -> void:
	var d = JSON.parse_string(FileAccess.get_file_as_string(GLOSSARY))
	for i in preload("res://ui/map.gd").ISLANDS:
		check(i.name in d.places, "%s is not in the glossary's places" % i.name)
	check_eq(ExamSwitch.ONLY, d.exam_switch.only)
	check_eq(ExamSwitch.PLUS, d.exam_switch.plus)
	check_eq(ExamSwitch.HELP, d.exam_switch.help)
	check_eq(Bazaar.LIFELINE_NAMES, d.lifelines)
