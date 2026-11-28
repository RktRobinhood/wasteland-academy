class_name ScriptedRun
extends RefCounted
## Plays a lesson the way a player would (#218), for ./test.sh and the capture: it answers
## every action the lesson player waits on, through the same buttons, boxes, board lines
## and toy actions a tap uses. With misses on, it slips once on every item that can be
## slipped on before getting it right, so a run sees each reaction and not-yet line.
##
##   var run := ScriptedRun.new()
##   run.call_value = "−13"            # the call to make in act 1
##   player.driver = run
##
## delay is the seconds it waits before each action at 1×, so a capture shows the
## action's screen before it is done; 0 for the tests.

## The call: the predict's answer when empty, so the recap's match line plays.
var call_value := ""
var misses := true
var take_optional := true
var delay := 0.0
## What it did, in order, for the tests: "predict −13", "toy send −2", "build miss 1"…
var done: PackedStringArray = []
## The kinds of actions met, in order.
var met: PackedStringArray = []
var _seen_items := {}


func act(p: LessonPlayer, kind: String, item: Dictionary) -> void:
	met.append(kind)
	if delay > 0.0:
		await p.get_tree().create_timer(delay / p.speed).timeout
	if not is_instance_valid(p) or p.state == "done":
		return
	match kind:
		"predict":
			var v := call_value
			if v == "":
				var a: Variant = item.get("answer", "")
				v = str(a[0]) if a is Array else str(a)
			if str(item.get("kind", "type")) == "choose":
				_press(p, "Choices/Choice%d" % maxi(0, item.get("choices", []).find(v)))
			else:
				_type(p, v)
			done.append("predict " + v)
		"ask":
			var right := int(item.get("answer", 0))
			if misses and not _seen(p, "ask", item):
				var wrong := (right + 1) % maxi(1, item.get("choices", []).size())
				done.append("ask miss")
				_press(p, "Choices/Choice%d" % wrong)
			else:
				done.append("ask right")
				_press(p, "Choices/Choice%d" % right)
		"tap-line":
			var keys: Array = item.get("choices", [])
			var right := str(keys[int(item.get("answer", 0))])
			if misses and not _seen(p, "tap", item) and keys.size() > 1:
				var wrong := str(keys[(int(item.get("answer", 0)) + 1) % keys.size()])
				done.append("tap miss " + wrong)
				p.tap_line(wrong)
			else:
				done.append("tap right " + right)
				p.tap_line(right)
		"optional":
			done.append("optional " + ("try" if take_optional else "skip"))
			_press(p, "Optional/Try" if take_optional else "Optional/SkipToy")
		"toy":
			var toy := p.toy()
			if toy == null:
				return
			var acts := toy.script_for(item, misses)
			for a in acts:
				if delay > 0.0:
					await p.get_tree().create_timer(delay / p.speed).timeout
				if not is_instance_valid(toy) or p.toy() != toy:
					return
				done.append("toy %s %s" % [item.get("kind", "free"), a.get("send", "")])
				toy.perform(a)
		"build":
			var st: Dictionary = item.build.steps[item.step]
			var right := int(st.get("answer", 0))
			if misses and not _seen(p, "build%d" % item.step, item.build):
				for i in st.tiles.size():
					if i != right:
						done.append("build miss %d" % i)
						_press(p, "Tiles/Tile%d" % i)
						return
			done.append("build right %d" % item.step)
			_press(p, "Tiles/Tile%d" % right)
		"typed":
			if misses and not _seen(p, "typed", item):
				done.append("typed miss")
				_type(p, "1")
			else:
				var a: Variant = item.get("answer", "")
				done.append("typed right")
				_type(p, str(a[0]) if a is Array else str(a))
		"turn":
			var miss := misses and not _seen(p, "turn%d" % item.part, item.turn)
			if item.get("engine", false):
				_answer_engine(p, item.question, miss)
				return
			if not (item.get("authored_slots", {}) as Dictionary).is_empty():
				_answer_engine(p, {"answer": item.authored_slots}, false)
				return
			var right: String = Lesson.part_item(item.turn.fallback.parts[item.part]).answer
			done.append("turn %s %s" % ["miss" if miss else "right", right])
			_type(p, _wrong(right) if miss else right)



## Whether this item has been met before in the run: the first time, it slips.
func _seen(_p: LessonPlayer, kind: String, item: Dictionary) -> bool:
	var k := "%s|%d" % [kind, hash(item)]
	if _seen_items.has(k):
		return true
	_seen_items[k] = true
	return false


func _press(p: LessonPlayer, path: String) -> void:
	var b := p.actions.get_node_or_null(path) as Button
	if b == null:
		push_warning("scripted run: no %s" % path)
		return
	b.pressed.emit()


func _type(p: LessonPlayer, text: String) -> void:
	var e := p.actions.get_node_or_null("Entry/Box") as MathEntry
	if e == null:
		push_warning("scripted run: no answer box")
		return
	e.text = text.replace("−", "-")
	(p.actions.get_node("Entry/Send") as Button).pressed.emit()


## An engine question answered in its boxes: its right values, or a wrong option's.
func _answer_engine(p: LessonPlayer, q: Dictionary, miss: bool) -> void:
	var values: Dictionary = q.answer.values
	if miss:
		for c in q.get("choices", []):
			if not c.correct and Answer.typable(q.answer, c.values):
				values = c.values
				break
	done.append("turn %s engine" % ("miss" if miss else "right"))
	for s in Answer.slots(q.answer):
		var v: Variant = values.get(str(s.get("slot", s.get("pick", ""))))
		var text: String = v.text() if v is Q else str(v)
		if s.has("slot"):
			var e := p.actions.get_node_or_null("Slots/Slot_" + str(s.slot)) as MathEntry
			if e != null:
				e.text = text.replace("−", "-")
		else:
			for b in p.actions.get_node("Slots").get_children():
				if b is Button and b.toggle_mode and b.text == text:
					b.button_pressed = true
					b.pressed.emit()
	(p.actions.get_node("Send") as Button).pressed.emit()


static func _wrong(right: String) -> String:
	var n := Lesson.number(right)
	return RelayToy.num(n + 1.0) if not is_nan(n) else "0"
