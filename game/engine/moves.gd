class_name Moves
extends RefCounted
## The explainer moves (FAL-429): the general step Spark voices once for every question
## that uses it, and the move for each worked step of every built method. Read from
## data/moves.json, the generated copy of curriculum/moves.json and moves-map.json
## (node tools/game-moves.mjs --write). The engine tags a worked solution's steps here
## as it builds the question, so a mapped step becomes {"move", "board"} (see Step).
##
##   Moves.tag("fn-quadratic-features", "vertex-from-general", "equation", "complete-square", steps)
##   Moves.say("substitute")       # the caption: the line Spark says
##   Moves.voice("substitute", 2)  # res://assets/audio/voice/spark/moves/substitute_2.ogg
##   Moves.any_tagged(steps)       # whether a solution has something to watch

const DATA := "res://data/moves.json"
const VOICE_DIR := "res://assets/audio/voice/spark/moves/"
## Each move is recorded twice; the player picks one at random.
const TAKES := 2

static var _data: Dictionary = {}
## "key|steps|index" -> [[RegEx, move], ...]
static var _branches: Dictionary = {}


static func data() -> Dictionary:
	if _data.is_empty():
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(DATA))
		_data = parsed if parsed is Dictionary else {"moves": {}, "map": {}, "branches": []}
		for b in _data.get("branches", []):
			var k := "%s|%s|%d" % [b.key, b.steps, int(b.index)]
			if not _branches.has(k):
				_branches[k] = []
			_branches[k].append([RegEx.create_from_string(b.match), b.move])
	return _data


## Every move id, in the order of curriculum/moves.json.
static func ids() -> Array:
	return data().moves.keys()


static func has(id: String) -> bool:
	return data().moves.has(id)


## The move's name ("Substitute"), or "".
static func name_of(id: String) -> String:
	return str(data().moves.get(id, {}).get("name", ""))


## The line Spark says for the move, which is the caption, or "".
static func say(id: String) -> String:
	return str(data().moves.get(id, {}).get("say", ""))


## The path of one take (1 or 2) of the move's voice line.
static func voice(id: String, take: int) -> String:
	return "%s%s_%d.ogg" % [VOICE_DIR, id, take]


## The move list for a method's solution: the "<rep>/<n>" list where there is one,
## else the "<n>" list, as [list key, moves], or ["", []] when the map has neither.
static func list_for(type: String, unknown: String, rep: String, angle: String, n: int) -> Array:
	var by_count: Dictionary = data().map.get("%s/%s/%s" % [type, unknown, angle], {})
	for k in ["%s/%d" % [rep, n], str(n)]:
		if by_count.has(k):
			return [k, by_count[k]]
	return ["", []]


## The steps with their move tags. A step already tagged keeps its tag; a method or step
## count the map doesn't know leaves the steps as they are.
static func tag(type: String, unknown: String, rep: String, angle: String, steps: Array) -> Array:
	var found := list_for(type, unknown, rep, angle, steps.size())
	var list: Array = found[1]
	if list.size() != steps.size():
		return steps
	var key := "%s/%s/%s" % [type, unknown, angle]
	var out: Array = []
	for i in steps.size():
		var st = steps[i]
		if Step.move(st) != "":
			out.append(st)
			continue
		var m = list[i]
		for br in _branches.get("%s|%s|%d" % [key, found[0], i], []):
			if br[0].search(Step.text(st)) != null:
				m = br[1]
				break
		out.append(Step.tagged(m, Step.text(st)) if m != null and has(str(m)) else st)
	return out


## Whether any step carries a move: the explainer's "Watch it" shows only then.
static func any_tagged(steps: Array) -> bool:
	return steps.any(func(st): return Step.move(st) != "")
