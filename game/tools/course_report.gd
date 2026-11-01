extends SceneTree
## What the engine can ask each IB course, as JSON, for the course audit
## (tools/course-audit.mjs). Used by tools/course-audit.
##
##   godot --headless --path game --script res://tools/course_report.gd -- --out=/abs/report.json
##
## {"built": [type ids the engine can make],
##  "courses": {course id: {"cells": n, "types": {type id: {"cells": n, "unknowns": [ids]}}}}}
## A course lists only the types and unknowns it covers (QuestionEngine.covered).


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var out := "user://course_report.json"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
	var courses := {}
	for course in Courses.ids():
		var types := {}
		var total := 0
		for id in QuestionEngine.built_types(course):
			var cells := QuestionEngine.cells(false, [id], course)
			var unknowns: Array = []
			for c in cells:
				if not unknowns.has(c.unknown):
					unknowns.append(c.unknown)
			types[id] = {"cells": cells.size(), "unknowns": unknowns}
			total += cells.size()
		courses[course] = {"cells": total, "types": types}
	var f := FileAccess.open(out, FileAccess.WRITE)
	if f == null:
		printerr("course_report: can't write %s" % out)
		quit(1)
		return
	f.store_string(JSON.stringify({"built": QuestionEngine.built_types(), "courses": courses}, "\t"))
	f.close()
	print("course_report: wrote %s" % out)
	quit()
