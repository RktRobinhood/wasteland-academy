class_name Courses
extends RefCounted
## The student's IB course (FAL-397, engine side): AA SL, AA HL, AI SL or AI HL. A course
## is a filter over the shared skills, not a separate game (curriculum/README.md,
## "Courses and IDs"). data/courses.json lists, for each course, the subtopics it covers;
## a skill belongs to the subtopic named by the first two parts of its id (SL2.6.vertex
## is in SL2.6, AI-SL1.6.bounds in AI-SL1.6).
##
##   Courses.of(save)                       # "aa-sl" until the student picks another
##   QuestionEngine.cells(false, [], "ai-sl")   # the coverage cells of that course
##
## An unknown is covered when every skill it lists is in the course and at least one of
## its methods is (QuestionEngine.covered), so a question never needs a skill the student
## has not met. An unknown that lists no skills (prior-learning algebra, which every
## course assumes) is covered by all four. A course of "" means no filter, and so does a
## courses.json that can't be read (the game plays as AA SL then).

const PATH := "res://data/courses.json"
const DEFAULT := "aa-sl"

## Course id -> {"id", "short", "name", "status", "subtopics": {subtopic id: true}}.
static var _index: Dictionary = {}
static var _loaded := false


static func _load(path: String = PATH) -> void:
	_loaded = true
	_index = {}
	var f := FileAccess.open(path, FileAccess.READ)
	var data = JSON.parse_string(f.get_as_text()) if f != null else null
	if not data is Dictionary or not data.get("courses") is Array:
		push_warning("Courses: could not read %s; every course plays as AA SL" % path)
		return
	for c in data.courses:
		var subs := {}
		for id in c.get("subtopics", []):
			subs[id] = true
		_index[c.id] = {"id": c.id, "short": c.get("short", c.id), "name": c.get("name", c.id),
			"status": c.get("status", ""), "subtopics": subs}


static func _courses() -> Dictionary:
	if not _loaded:
		_load()
	return _index


## The course ids, in courses.json order (AA SL, AA HL, AI SL, AI HL).
static func ids() -> Array:
	return _courses().keys()


static func has(course: String) -> bool:
	return _courses().has(course)


## {"id", "short", "name", "status"} of a course, or {} for one that is not listed.
static func info(course: String) -> Dictionary:
	var c: Dictionary = _courses().get(course, {})
	if c.is_empty():
		return {}
	return {"id": c.id, "short": c.short, "name": c.name, "status": c.status}


## The course a save is on: its `course`, or DEFAULT for a save without one (or with an
## id courses.json doesn't list, say from a newer game).
static func of(save: Dictionary) -> String:
	var c := String(save.get("course", DEFAULT))
	return c if c == "" or has(c) or _courses().is_empty() else DEFAULT


## The subtopic a skill id belongs to: "SL2.6.vertex" -> "SL2.6".
static func subtopic_of(skill: String) -> String:
	var parts := skill.split(".")
	return skill if parts.size() < 2 else "%s.%s" % [parts[0], parts[1]]


static func covers_skill(course: String, skill: String) -> bool:
	if course == "" or _courses().is_empty():
		return true
	return _courses().get(course, {}).get("subtopics", {}).has(subtopic_of(skill))


## Whether a student on `course` may be asked this catalogue unknown.
static func covers(course: String, unknown: Dictionary) -> bool:
	if course == "":
		return true
	for s in unknown.get("skills", []):
		if not covers_skill(course, s):
			return false
	return true


## Whether a student on `course` has met the skill a method (a catalogue angle) teaches.
## A method that names no skill is open to every course.
static func covers_method(course: String, angle: Dictionary) -> bool:
	return not angle.has("skill") or covers_skill(course, angle.skill)
