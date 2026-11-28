class_name Lesson
extends RefCounted
## A tutor lesson's script (writing/explainers/, format 3, #216) as the lesson player
## reads it (#218, ui/lesson/lesson_player.gd): loading, and the choices the player makes
## from it that need no screen. Which recall version plays, which back_to group a stored
## call picks, which reaction plays, whether a typed answer is right and which not-yet
## line answers it. Kept apart from the player so the tests can check each rule alone.
##
## The scripts live in writing/explainers/, outside game/, so the game reads a generated
## copy in res://data/explainers/ (tools/game-explainers.mjs).

const DIR := "res://data/explainers/"
const MINUS := "−"

## The parsed script.
var data: Dictionary = {}
## Every predict in the script, by id, so a back_to can be chosen even when its call was
## skipped.
var predicts: Dictionary = {}


## A lesson by script id, such as "ex.functions.function-machine", or null.
static func load_id(id: String) -> Lesson:
	return from_file(DIR + id + ".json")


static func from_file(path: String) -> Lesson:
	if not FileAccess.file_exists(path):
		return null
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return from_data(parsed) if parsed is Dictionary else null


static func from_data(d: Dictionary) -> Lesson:
	var l := Lesson.new()
	l.data = d
	l._find_predicts(d.get("sections", []))
	return l


## The lesson ids the game has a copy of.
static func ids() -> Array:
	var out: Array = []
	var dir := DirAccess.open(DIR)
	if dir == null:
		return out
	for f in dir.get_files():
		if f.begins_with("ex.") and f.ends_with(".json"):
			out.append(f.trim_suffix(".json"))
	out.sort()
	return out


## A self-contained part of an existing lesson. Do not rename the source id:
## line recordings are owned by that lesson. Preview callers opt out of saving.
func excerpt(section_id: String) -> Lesson:
	for section in sections():
		if section.get("id") == section_id:
			var copy := data.duplicate(true)
			copy["sections"] = [section.duplicate(true)]
			return from_data(copy)
	return null


## The stock lines the scripts share: callbacks, reactions and the verified voice index.
static func shared(name: String) -> Dictionary:
	var path := DIR + name + ".json"
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	return parsed if parsed is Dictionary else {}


func _find_predicts(v: Variant) -> void:
	if v is Dictionary:
		if v.has("predict") and v.predict is Dictionary:
			predicts[str(v.predict.get("id", ""))] = v.predict
		for k in v:
			_find_predicts(v[k])
	elif v is Array:
		for x in v:
			_find_predicts(x)


func id() -> String:
	return str(data.get("id", ""))


func tutor() -> String:
	return str(data.get("tutor", ""))


func sections() -> Array:
	return data.get("sections", [])


# ── Recall ───────────────────────────────────────────────────

## The explainer a recall section builds on: its own builds_on, else the script's first.
func recall_of(section: Dictionary) -> String:
	if section.has("builds_on"):
		return str(section.builds_on) if section.builds_on != null else ""
	var b: Array = data.get("builds_on", [])
	return str(b[0]) if not b.is_empty() else ""


## The beats a section plays. A recall section with two versions plays "watched" when
## the explainer it builds on is in the watched record and "not_watched" otherwise;
## force ("watched" or "not_watched") picks one, so both can be played.
func beats_of(section: Dictionary, watched: Array, force := "") -> Array:
	if section.has("watched") or section.has("not_watched"):
		var seen := watched.has(recall_of(section))
		if force == "watched" or force == "not_watched":
			seen = force == "watched"
		return section.get("watched" if seen else "not_watched", [])
	return section.get("beats", [])


## Whether a section has two recall versions.
static func has_versions(section: Dictionary) -> bool:
	return section.has("watched") or section.has("not_watched")


# ── The call ─────────────────────────────────────────────────

## Text as the game compares it: trimmed, lower case, true minus signs as "-", no spaces.
static func norm(s: String) -> String:
	return s.strip_edges().to_lower().replace(MINUS, "-").replace("–", "-").replace(" ", "")


## A number in s, or NAN: "−13", "4.5", "3/2", "80%".
static func number(s: String) -> float:
	var t := norm(s).trim_suffix("%")
	if t == "":
		return NAN
	var r := Answer.parse_number(t)
	return r.q.to_float() if r.ok else NAN


## Whether two answers are the same: as numbers when both are, else as text.
static func same(a: String, b: String) -> bool:
	var x := number(a)
	var y := number(b)
	if not is_nan(x) and not is_nan(y):
		return is_equal_approx(x, y)
	return norm(a) == norm(b)


static func _answers(v: Variant) -> Array:
	return v.map(func(x): return str(x)) if v is Array else [str(v)]


## The group of lines a back_to plays for a stored call (null when the call was never
## made): match when the call is the predict's answer, then the first value it is, then
## other.
func back_to_lines(back: Dictionary, call: Variant) -> Array:
	var p: Dictionary = predicts.get(str(back.get("predict", "")), {})
	if call != null:
		var c := str(call)
		for a in _answers(p.get("answer", "")):
			if same(c, a) and back.has("match"):
				return back.match
		for v in back.get("values", []):
			if same(c, str(v.get("value", ""))):
				return v.get("lines", [])
	return back.get("other", [])


# ── Typed answers ────────────────────────────────────────────

## Marks a typed answer: {"right": bool, "misconception": the wrong answer's, or ""}.
static func mark_typed(item: Dictionary, typed: String) -> Dictionary:
	if norm(typed) == "":
		return {"right": false, "misconception": "", "empty": true}
	var ok: Array = _answers(item.get("answer", ""))
	ok.append_array(item.get("accept", []))
	for a in ok:
		if same(typed, str(a)):
			return {"right": true, "misconception": ""}
	for w in item.get("wrong", []):
		if same(typed, str(w.get("answer", ""))):
			return {"right": false, "misconception": str(w.get("misconception", ""))}
	return {"right": false, "misconception": ""}


## The not-yet line for a misconception: the line keyed to it, else the neutral line (the
## one with no misconception). `turn` is the count of misses so far, so a set of neutral
## lines takes turns.
static func not_yet_for(lines: Array, misconception: String, turn := 0) -> Array:
	if misconception != "":
		for l in lines:
			if str(l.get("misconception", "")) == misconception:
				return [l]
	var neutral := lines.filter(func(l): return not l.has("misconception"))
	if neutral.is_empty():
		neutral = lines
	return [neutral[turn % neutral.size()]] if not neutral.is_empty() else []


## The first number in a fallback part's answer, which a typed answer is marked against:
## "300; the tank holds 300 litres…" is 300, "20 minutes" is 20. "" for none.
static func leading_number(answer: String) -> String:
	var re := RegEx.create_from_string("[−\\-]?\\d+(\\.\\d+)?(/\\d+)?")
	var m := re.search(answer)
	return m.get_string() if m != null else ""


## A fallback expression can ask for exact coefficient slots instead of guessing a
## numeric answer from the first digit of an equation.
static func part_slots(part: Dictionary) -> Dictionary:
	var spec: Dictionary = part.get("polynomial", {})
	if spec.is_empty():
		return {}
	var fixed := {"powers": spec.powers, "var": spec.variable}
	var values := {}
	for i in spec.coefficients.size():
		values["c%d" % i] = Q.of(int(spec.coefficients[i]))
	var answer := Answer.make("poly", values, fixed, str(spec.get("label", "")))
	answer.exact = true
	return answer


## A fallback part as a typed item: marked on its leading number, with its wrong answers.
static func part_item(part: Dictionary) -> Dictionary:
	var n := leading_number(str(part.get("answer", "")))
	return {"answer": n if n != "" else str(part.get("answer", "")), "wrong": part.get("wrong", [])}


# ── Reactions ────────────────────────────────────────────────

## Picks the tutor's stock reactions (reactions.json, #220) by the README's rules: an ack
## only on some actions, a slip only on the first miss of an item. The player asks; this
## answers with a line or {}. Each tutor and kind draws from a shuffle bag kept for the
## session (FAL-1134): no line plays again until every other line of its kind in that set
## has, and a refilled bag never starts with the line that played last.
class Reactions:
	const VOICE_DIR := "res://assets/audio/voice/explainers/reactions/"
	## "tutor|kind" -> {"bag": [line ids still to play], "last": the id played last}.
	static var _bags := {}
	var tutor := ""
	var lines := {"ack": [], "slip": []}
	var _acks := 0
	var _rng := RandomNumberGenerator.new()

	func _init(tutor_id: String, table: Dictionary, seed := 0) -> void:
		tutor = tutor_id
		var t: Dictionary = table.get("tutors", {}).get(tutor, {})
		lines.ack = t.get("ack", [])
		lines.slip = t.get("slip", [])
		_rng.seed = seed

	## Forget what this session has played: a new session, or a test.
	static func new_session() -> void:
		_bags.clear()

	## A reaction's recorded take, or null.
	static func take(l: Dictionary) -> AudioStream:
		var id := str(l.get("line", ""))
		var path := VOICE_DIR + id + ".ogg"
		return load(path) as AudioStream if id != "" and ResourceLoader.exists(path) else null

	## A slip, for the first miss of an item (misses_before is 0); {} otherwise.
	func slip(misses_before: int) -> Dictionary:
		if misses_before > 0:
			return {}
		return _pick("slip")

	## An ack on a free send or a right tile with no line of its own: every other one.
	func ack() -> Dictionary:
		_acks += 1
		if _acks % 2 == 0:
			return {}
		return _pick("ack")

	func _pick(kind: String) -> Dictionary:
		var by_id := {}
		for l in lines[kind]:
			if str(l.get("line", "")) != "":
				by_id[str(l.line)] = l
		if by_id.is_empty():
			return {}
		var key := tutor + "|" + kind
		var s: Dictionary = _bags.get(key, {"bag": [], "last": ""})
		# A line the set no longer has doesn't play.
		var bag: Array = s.bag.filter(func(id): return by_id.has(id))
		if bag.is_empty():
			bag = by_id.keys()
			for i in range(bag.size() - 1, 0, -1):
				var j := _rng.randi_range(0, i)
				var tmp = bag[i]
				bag[i] = bag[j]
				bag[j] = tmp
			if bag.size() > 1 and bag[0] == s.last:
				var j := _rng.randi_range(1, bag.size() - 1)
				bag[0] = bag[j]
				bag[j] = s.last
		var id: String = bag.pop_front()
		_bags[key] = {"bag": bag, "last": id}
		return by_id[id]
