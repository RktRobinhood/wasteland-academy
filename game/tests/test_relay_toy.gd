extends "res://tests/test_case.gd"
## The relay toy (#217) and the toy interface (game/docs/TOYS.md), driven by scripted
## input: the engine's real touch events at a 390 px phone for the dial and the switch,
## and perform() for the scripted runs the lesson player makes.

const ITEM := {"toy": "relay", "rule": "x² − 4", "dial": [-5, 5]}
const WOBBLE := 10.0


func _toy(item: Dictionary = ITEM) -> Array:
	Input.emulate_touch_from_mouse = true
	var base := Vector2(1080, 1920)
	var window := Vector2(390, 844)
	var frame := Control.new()
	frame.size = window / minf(window.x / base.x, window.y / base.y)
	frame.theme = UiTheme.make()
	tree.root.add_child(frame)
	var toy := Toys.make(item)
	toy.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.add_child(toy)
	await _settle()
	return [frame, toy]


func _done(made: Array) -> void:
	made[0].free()
	Input.emulate_touch_from_mouse = false


func _settle() -> void:
	for i in 4:
		await tree.process_frame


func _send(e: InputEvent) -> void:
	Input.parse_input_event(e)
	Input.flush_buffered_events()
	await tree.process_frame


func _touch(at: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.position = tree.root.get_final_transform() * at
	e.pressed = pressed
	await _send(e)


func _tap(c: Control) -> void:
	var at := c.get_global_rect().get_center()
	await _touch(at, true)
	var e := InputEventScreenDrag.new()
	e.position = tree.root.get_final_transform() * (at + Vector2(WOBBLE, WOBBLE))
	await _send(e)
	await _touch(at, false)
	await _settle()


## Dial to a value and throw the switch, by touch.
func _send_by_touch(toy: RelayToy, v: int) -> void:
	while toy.value < v:
		await _tap(toy.plus_button)
	while toy.value > v:
		await _tap(toy.minus_button)
	await _tap(toy.switch_button)


func test_the_registry_builds_the_relay_and_checks_its_item() -> void:
	check(Toys.has("relay"))
	check(Toys.make({"toy": "kettle"}) == null, "an unknown toy builds nothing")
	check(not Toys.check({"toy": "kettle"}).is_empty())
	check(Toys.check(ITEM).is_empty(), "the exemplar's item is good: %s" % [Toys.check(ITEM)])
	check(not Toys.check({"toy": "relay"}).is_empty(), "no rule")
	check(not Toys.check({"toy": "relay", "rule": "x +* 2"}).is_empty(), "a rule it can't read")
	check(not Toys.check({"toy": "relay", "rule": "x", "dial": [5, -5]}).is_empty(), "dial least first")
	check(not Toys.check({"toy": "relay", "rule": "x", "dial": [0.5, 3]}).is_empty(), "dial whole numbers")
	var toy := Toys.make(ITEM)
	check(toy is LessonToy and toy is RelayToy)
	check_eq(Array(toy.kinds()), ["free", "send", "find"])
	toy.free()


func test_the_rule_comes_from_the_item() -> void:
	var f := Toys.make(ITEM) as RelayToy
	check_eq(f.outputs_for(-3), [5.0])
	check_eq(f.outputs_for(2), [0.0])
	var g := Toys.make({"toy": "relay", "rule": "6 - 2x", "dial": [-6, 6], "label": "g"}) as RelayToy
	check_eq(g.outputs_for(-4), [14.0])
	check_eq(g.box.label, "g")
	check_eq(RelayToy.num(-3.0), "−3")
	check_eq(RelayToy.num(4.5), "4.5")
	f.free()
	g.free()


func test_touch_dials_and_sends_at_phone_width() -> void:
	var made: Array = await _toy()
	var toy: RelayToy = made[1]
	for c in [toy.plus_button, toy.minus_button, toy.switch_button, toy.dial_face]:
		var r: Rect2 = c.get_global_rect()
		check(made[0].get_rect().encloses(r), "%s is on the screen" % c.name)
		check(r.size.y >= RelayToy.TOUCH, "%s is big enough to tap" % c.name)
	var acts := []
	toy.acted.connect(func(a: Dictionary) -> void: acts.append(a))
	toy.start({"kind": "free", "count": 3})
	await _tap(toy.plus_button)
	await _tap(toy.plus_button)
	check_eq(toy.value, 2, "two taps on +")
	await _tap(toy.switch_button)
	check_eq(acts.size(), 1, "the switch sends")
	check_eq(acts[0].board, "in 2 → out 0")
	check_eq(acts[0].hit, null, "a free send is never marked")
	# A tap on the dial's left half turns it down one.
	var left: Vector2 = toy.dial_face.get_global_rect().position + Vector2(30, toy.dial_face.size.y / 2.0)
	await _touch(left, true)
	await _touch(left, false)
	check_eq(toy.value, 1, "a tap on the dial's left")
	# A drag along the dial turns it several steps.
	var from: Vector2 = toy.dial_face.get_global_rect().get_center()
	await _touch(from, true)
	for i in 8:
		var e := InputEventScreenDrag.new()
		e.position = tree.root.get_final_transform() * (from - Vector2(30 * (i + 1), 0))
		e.relative = tree.root.get_final_transform().basis_xform(Vector2(-30, 0))
		await _send(e)
	await _touch(from - Vector2(240, 0), false)
	check_eq(toy.value, -2, "a 240-unit drag left is three steps")
	_done(made)


func test_free_sends_finish_after_the_count_and_log_every_send() -> void:
	var made: Array = await _toy()
	var toy: RelayToy = made[1]
	var results := []
	toy.task_done.connect(func(r: Dictionary) -> void: results.append(r))
	toy.start({"kind": "free", "count": 3})
	for v in [2, -1, 5]:
		await _send_by_touch(toy, v)
	check_eq(results.size(), 1, "done after three")
	check_eq(results[0].actions, 3)
	check_eq(Array(toy.board), ["in 2 → out 0", "in −1 → out −3", "in 5 → out 21"])
	check_eq(toy.log_lines.get_child_count(), 3, "every send is on the board")
	check(toy.task.is_empty(), "between tasks")
	_done(made)


func test_a_send_task_misses_then_hits() -> void:
	var made: Array = await _toy()
	var toy: RelayToy = made[1]
	var acts := []
	var results := []
	toy.acted.connect(func(a: Dictionary) -> void: acts.append(a))
	toy.task_done.connect(func(r: Dictionary) -> void: results.append(r))
	toy.start({"kind": "send", "input": -3})
	await _send_by_touch(toy, 3)
	check_eq(acts[-1].hit, false, "3 is not the input asked for")
	check(results.is_empty(), "a miss doesn't end the task")
	check(toy.static_overlay.visible, "a miss puts static on the box")
	check_eq(toy.map_strip.pin_hit, false, "and the pin lights as a miss")
	check_eq(acts[-1].outputs, [5.0], "the signal still goes out")
	await _send_by_touch(toy, -3)
	check_eq(acts[-1].hit, true)
	check_eq(results.size(), 1)
	check_eq(results[0].misses, 1)
	check_eq(results[0].input, -3)
	_done(made)


func test_a_find_takes_any_input_that_gives_the_output() -> void:
	for answer in [4, -4]:
		var made: Array = await _toy()
		var toy: RelayToy = made[1]
		var results := []
		toy.task_done.connect(func(r: Dictionary) -> void: results.append(r))
		toy.start({"kind": "find", "output": 12, "place": "Scrap Fields"})
		check_eq(toy.task_label.text, "Find an input that gives 12")
		await _send_by_touch(toy, 1)
		check(results.is_empty(), "1 gives −3, not 12")
		check(toy.static_overlay.visible)
		await _send_by_touch(toy, answer)
		check_eq(results.size(), 1, "%d gives 12" % answer)
		check_eq(results[0].answers, [-4, 4], "both inputs are right")
		_done(made)


func test_the_broken_relay_gives_two_outputs_for_one_input() -> void:
	var item := ITEM.duplicate()
	item.broken = "x² + 4"
	var made: Array = await _toy(item)
	var toy: RelayToy = made[1]
	toy.start({"kind": "free", "count": 1})
	await _send_by_touch(toy, 2)
	check_eq(toy.last_outputs, [0.0, 8.0])
	check_eq(toy.board[-1], "in 2 → out 0 and 8")
	check(toy.box.broken)
	_done(made)


func test_scripted_runs_meet_every_task() -> void:
	for t in [{"kind": "free", "count": 3}, {"kind": "send", "input": -3}, {"kind": "find", "output": 12}]:
		for miss in [false, true]:
			var toy := Toys.make(ITEM)
			var done := []
			var acts := []
			toy.task_done.connect(func(r: Dictionary) -> void: done.append(r))
			toy.acted.connect(func(a: Dictionary) -> void: acts.append(a))
			toy.start(t)
			for a in toy.script_for(t, miss):
				toy.perform(a)
			check_eq(done.size(), 1, "%s, miss %s" % [t, miss])
			if miss and t.kind != "free":
				check_eq(acts[0].hit, false, "the scripted miss misses: %s" % [t])
			toy.free()


func test_reduced_motion_cuts_the_signal_and_stills_the_static() -> void:
	check(not LessonToy.reduce_motion({}), "off by default")
	check(LessonToy.reduce_motion({"settings": {"reduced_motion": true}}), "the save's setting")
	var made: Array = await _toy()
	var toy: RelayToy = made[1]
	toy.reduced_motion = true
	toy.start({"kind": "send", "input": 0})
	toy.perform({"send": 1})
	check_eq(toy.travel, -1.0, "no signal travels the wire")
	await _settle()
	check(toy.static_overlay.visible, "the miss still shows")
	check(toy.static_overlay.still, "as a still wash")
	toy.reduced_motion = false
	toy.perform({"send": 2})
	check(toy.travel >= 0.0, "with motion the signal travels")
	_done(made)
