class_name MathsEngine
extends RefCounted
## The reusable mathematics engine's interface (#134, FAL-798; game/docs/MATHS-ENGINE.md).
## Every screen that asks, marks or explains a question goes through here: the game's
## practice and fight screens, and the academic study screen (ui/study.gd). Nothing in
## it, or in what it calls, knows about combat, characters, rewards, the map or a scene:
## tests/test_maths_engine.gd checks that.
##
##   Curriculum selection   courses(), topics(), types(course), requests(course)
##   Generation             generate(request)            the same request, the same question
##   Marking                mark(question, response)
##   Worked solutions       worked_solutions(question), answer_sentence(question)
##   Learning results       blank_evidence(), record(evidence, question, result, now),
##                          results(evidence, course)
##
## A request is a Dictionary: {"type", "unknown", "rep", "angle", "format", "seed"} and,
## optionally, "paper" (1 or 2). A concept probe is {"type", "probe": index, "format":
## "probe"}. Evidence is a Dictionary with "cells", "probes" and "history" (the game's
## save is one, with its own fields beside them).

## The interface's version. A change that breaks a caller bumps it.
const VERSION := 1


# ── Curriculum selection ─────────────────────────────────────

## The IB courses, in order: each {"id", "short", "name", "status"}.
static func courses() -> Array:
	return Courses.ids().map(func(id): return Courses.info(id))


## The syllabus topics: each {"n", "name"}.
static func topics() -> Array:
	return QuestionEngine.catalogue().get("topics", [])


## The question types the engine can make for a course ("" for every course), in
## catalogue order: each {"id", "name", "topic", "exam"}. exam_only keeps exam types.
static func types(course: String = "", exam_only: bool = false) -> Array:
	var out: Array = []
	for id in QuestionEngine.built_types(course):
		var t := QuestionEngine.type_of(id)
		if exam_only and t.source != "exam":
			continue
		out.append({"id": id, "name": t.name, "topic": int(t.get("topic", 0)), "exam": t.source == "exam"})
	return out


## Every request a course can make (one per coverage cell), each {"type", "unknown",
## "rep", "angle", "key", "level", "exam"}: add a "format" and a "seed" to generate one.
## type_ids narrows it to those types. Read-only, as QuestionEngine.cells() is.
static func requests(course: String = "", exam_only: bool = false, type_ids: Array = []) -> Array:
	return QuestionEngine.cells(exam_only, type_ids, course)


## The syllabus topic (its "n") of a question type, or 0.
static func topic_of(type_id: String) -> int:
	return int(QuestionEngine.type_of(type_id).get("topic", 0))


## What a request asks for, in words ("the vertex"), or the unknown's id.
static func asked(type_id: String, unknown: String) -> String:
	return QuestionEngine.unknown_of(QuestionEngine.type_of(type_id), unknown).get("asked", unknown)


## The name of a method (a request's angle) on a type.
static func method_name(type_id: String, unknown: String, angle: String) -> String:
	return QuestionEngine.angle_info(QuestionEngine.type_of(type_id), unknown, angle).get("name", angle)


## A skill's name from the curriculum, or its id.
static func skill_name(id: String) -> String:
	return String(QuestionEngine.catalogue().get("skills", {}).get(id, id))


# ── Generation ───────────────────────────────────────────────

## The question for a request, or {"error"}. The same request always gives the same
## question. What a screen reads from it: "prompt" (prompt()), "format", "lines",
## "table", "graph", "diagram", "graphs", "answer" (its "template" lays out the answer
## boxes), "choices" (each "text"), "paper", "marks", "level", "exam", "type_name" and
## "cell" (the evidence key). A probe has "options" for its choices and "reveal".
static func generate(request: Dictionary) -> Dictionary:
	if request.get("format") == "probe":
		return QuestionEngine.probe(request.get("type", ""), int(request.get("probe", 0)))
	return QuestionEngine.make(request)


## The question's words as the student reads them.
static func prompt(question: Dictionary) -> String:
	return QuestionEngine.shown_prompt(question)


## Whether the question is answered by picking one option ({"choice": index}).
static func is_choice(question: Dictionary) -> bool:
	return question.get("format") == "probe" or QuestionEngine.is_choice(question)


# ── Marking ──────────────────────────────────────────────────

## Marks a response: {"choice": index} for a choice question or probe, else answer box
## id -> typed text (and pick id -> the option chosen). Returns {"correct", "complete",
## "glancing", "errors", "misconception"}; "errors" says what is missing when the
## response is not complete, and "misconception" is the ref of the mistake a wrong
## answer matches, or "".
static func mark(question: Dictionary, response: Dictionary) -> Dictionary:
	if question.get("format") != "probe":
		return QuestionEngine.mark(question, response)
	var i := int(response.get("choice", -1))
	if i < 0 or i >= question.options.size():
		return {"correct": false, "complete": false, "glancing": false, "errors": {"choice": "Choose one."}, "misconception": ""}
	var r := QuestionEngine.mark_probe(question, question.options[i])
	r.glancing = false
	r.errors = {}
	return r


## The response that answers the question right (or, with right = false, the way the
## commonest mistake does), as a student would type or pick it. Tests and demos use it.
static func model_response(question: Dictionary, right: bool = true) -> Dictionary:
	if is_choice(question):
		var items: Array = question.options if question.format == "probe" else question.choices
		var pick := -1
		for i in items.size():
			var ok: bool = (items[i] == question.verdict or (question.verdict == "" and i == 0)) if question.format == "probe" \
				else question.choices[i].correct
			if ok == right and pick < 0:
				pick = i
		# A wrong answer picks a misconception's option when there is one.
		if not right and question.format != "probe":
			for i in items.size():
				if question.choices[i].ref != "":
					pick = i
					break
		return {"choice": maxi(pick, 0)}
	var values: Dictionary = question.answer.values
	var boxes: Array = []
	var picks: Array = []
	for item in Answer.slots(question.answer):
		if item.has("slot"):
			boxes.append(item.slot)
		else:
			picks.append(item.pick)
	if not right:
		# A wrong option in another shape can be picked but not typed.
		for c in question.choices:
			if not c.correct and (boxes + picks).all(func(id): return c.values.has(id)):
				values = c.values
				if c.ref != "":
					break
	var out := {}
	for id in picks:
		out[id] = values[id]
	for id in boxes:
		# A measure is typed as a student would, to 3 s.f., and a decimal or money as written.
		if question.answer.kind in ["measure", "measures"]:
			out[id] = Fmt.sf(values[id]).replace("−", "-")
		elif question.answer.get("show", "") != "":
			out[id] = Answer.shown(question.answer, values[id]).replace("−", "-")
		else:
			out[id] = Answer.export_values({id: values[id]})[id]
	return out


# ── Worked solutions ─────────────────────────────────────────

## The worked solutions, the asked method first: each {"angle", "name", "steps": [text],
## "result"}. A probe's is its reveal, as one step.
static func worked_solutions(question: Dictionary) -> Array:
	if question.get("format") == "probe":
		return [{"angle": "any", "name": "Answer", "steps": [question.reveal], "result": ""}]
	return question.get("solutions", []).map(func(s): return {"angle": s.angle, "name": s.name,
		"steps": Step.texts(s.steps), "result": Answer.export_values(s.result) if s.result is Dictionary else s.result})


## "The answer is ...": the right answer as feedback names it.
static func answer_sentence(question: Dictionary) -> String:
	if question.get("format") == "probe":
		return "The answer is " + Fmt.stop(question.verdict if question.verdict != "" else question.reveal)
	return QuestionEngine.answer_sentence(question)


# ── Learning results ─────────────────────────────────────────

## How many answer keys the evidence keeps in "history", for spacing repeats.
const HISTORY := 20


## Evidence with nothing in it.
static func blank_evidence() -> Dictionary:
	return {"cells": {}, "probes": {}, "history": []}


## Records a marked answer in the evidence.
static func record(evidence: Dictionary, question: Dictionary, result: Dictionary, now: int) -> void:
	record_key(evidence, question.cell, result.correct, now, result.get("misconception", ""), question.get("format") == "probe")


## Records one answer by key: a cell key (or a probe key with probe = true). Each cell
## keeps {"seen", "right", "wrong", "last", "last_result", "misconceptions": {ref:
## times}, "last_misconception"}; a probe the same, without misconceptions.
static func record_key(evidence: Dictionary, key: String, right: bool, now: int, misconception: String = "", probe: bool = false) -> void:
	var book: Dictionary = evidence.probes if probe else evidence.cells
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
	var hist: Array = evidence.history
	hist.append(key)
	while hist.size() > HISTORY:
		hist.pop_front()


## A skill needs this many answers before it can be called weak.
const MIN_ATTEMPTS := 3
## How many weakest skills results() lists.
const WEAKEST := 3


## What the evidence says about a course (or about type_ids of it): {"coverage":
## {"checked", "total"}, "accuracy": {"right", "seen", "percent"}, "skills": {id:
## {"right", "seen"}}, "weakest": up to WEAKEST {"id", "name", "right", "seen",
## "percent"}}. percent is -1 when nothing has been answered.
static func results(evidence: Dictionary, course: String = "", exam_only: bool = false, type_ids: Array = []) -> Dictionary:
	var pool := requests(course, exam_only, type_ids)
	return {"coverage": coverage(evidence, pool), "accuracy": accuracy(evidence, pool), "skills": skill_stats(evidence, pool),
		"weakest": weakest_skills(evidence, pool)}


## {"checked": cells of the pool the evidence has seen, "total": the pool's cells}.
static func coverage(evidence: Dictionary, pool: Array) -> Dictionary:
	var checked := 0
	for c in pool:
		if int(evidence.cells.get(c.key, {}).get("seen", 0)) > 0:
			checked += 1
	return {"checked": checked, "total": pool.size()}


## {"right", "seen", "percent"} over every answer in the pool's cells.
static func accuracy(evidence: Dictionary, pool: Array) -> Dictionary:
	var right := 0
	var seen := 0
	for c in pool:
		var r: Dictionary = evidence.cells.get(c.key, {})
		right += int(r.get("right", 0))
		seen += int(r.get("seen", 0))
	return {"right": right, "seen": seen, "percent": percent(right, seen)}


## Skill id -> {"right", "seen"}: each answer in a cell counts for every skill its
## unknown lists.
static func skill_stats(evidence: Dictionary, pool: Array) -> Dictionary:
	var out := {}
	for c in pool:
		var r: Dictionary = evidence.cells.get(c.key, {})
		var seen := int(r.get("seen", 0))
		if seen == 0:
			continue
		var u := QuestionEngine.unknown_of(QuestionEngine.type_of(c.type), c.unknown)
		for s in u.get("skills", []):
			var st: Dictionary = out.get(s, {"right": 0, "seen": 0})
			st.right += int(r.get("right", 0))
			st.seen += seen
			out[s] = st
	return out


## The n skills with the lowest accuracy among those with at least MIN_ATTEMPTS
## answers, weakest first (ties: more answers first, then by id).
static func weakest_skills(evidence: Dictionary, pool: Array, n: int = WEAKEST) -> Array:
	var stats := skill_stats(evidence, pool)
	var out: Array = []
	for id in stats:
		var st: Dictionary = stats[id]
		if st.seen < MIN_ATTEMPTS:
			continue
		out.append({"id": id, "name": skill_name(id), "right": st.right, "seen": st.seen,
			"percent": percent(st.right, st.seen)})
	out.sort_custom(func(a, b):
		var fa: float = float(a.right) / a.seen
		var fb: float = float(b.right) / b.seen
		if fa != fb:
			return fa < fb
		if a.seen != b.seen:
			return a.seen > b.seen
		return a.id < b.id)
	return out.slice(0, n)


## right ÷ seen as a whole percent, or -1 when seen is 0.
static func percent(right: int, seen: int) -> int:
	return -1 if seen == 0 else roundi(100.0 * right / seen)
