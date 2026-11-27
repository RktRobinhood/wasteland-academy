extends "res://tests/test_case.gd"
## Synthetic opted-in smoke on a scaled board; actual input is sent through the viewport.

const SCALE := 0.42
const POS := Vector2(554, 1003)
const ANCHOR := Vector2(130, 128)

func _build(stir := true, reduced := false) -> Array:
	var stage := Control.new()
	tree.root.add_child(stage)
	stage.position = Vector2(16, 22)
	stage.scale = Vector2(SCALE, SCALE)
	var layer := AmbientLayer.new()
	stage.add_child(layer)
	layer.reduced_motion = reduced
	layer.build([{
		"id": "smoke-example", "sheet": "engine-smoke",
		"position": [POS.x, POS.y], "anchor": [ANCHOR.x, ANCHOR.y],
		"frames": "still", "motion": "none", "still": 0, "stir": stir,
	}])
	return [stage, layer, layer.thing("smoke-example")]

func _move(stage: Control, at: Vector2, travel: Vector2, touch := false, emulated := false) -> void:
	var event: InputEvent
	if touch:
		event = InputEventScreenDrag.new()
	else:
		event = InputEventMouseMotion.new()
	if emulated:
		event.device = InputEvent.DEVICE_ID_EMULATION
	event.position = stage.get_global_transform_with_canvas() * at
	event.relative = travel * SCALE
	tree.root.push_input(event, true)

func test_mouse_sweeps_the_plume_and_holds_the_painted_nozzle_fixed() -> void:
	var made := _build()
	var stage: Control = made[0]
	var layer: AmbientLayer = made[1]
	var t: Dictionary = made[2]
	var pivot: Node2D = t["stir_pivot"]
	var sprite: Sprite2D = t["sprite"]
	var nozzle := pivot.get_global_transform_with_canvas().origin
	check(not layer.is_processing() and layer.is_processing_input(), "no frame loop before first pass")
	# Both endpoints are outside the scaled sprite, but the path crosses its plume.
	_move(stage, POS + Vector2(45, -62), Vector2(235, 0))
	check(layer.is_processing(), "a swept crossing wakes the pivot")
	layer._process(0.09)
	check(pivot.rotation_degrees > 8.0 and pivot.rotation_degrees < 12.01, "gentle capped tilt")
	check_eq(t["holder"].position, POS, "painting attachment stays in place")
	check_eq(pivot.get_global_transform_with_canvas().origin, nozzle, "pivot never drifts")
	check((sprite.get_global_transform_with_canvas() * (ANCHOR + sprite.offset)).is_equal_approx(nozzle),
		"the original cell pixel for the nozzle is still at the exact attachment")
	layer._process(0.22)
	check(pivot.rotation_degrees > 0.0 and pivot.rotation_degrees < 8.0, "smooth return without snap or overshoot")
	layer._process(0.85)
	check_eq(pivot.rotation, 0.0, "comes fully to rest")
	check(not layer.is_processing(), "resting still image does not keep a process loop alive")
	stage.free()

func test_touch_drag_stirs_but_tap_and_touch_mouse_emulation_do_not() -> void:
	var made := _build()
	var stage: Control = made[0]
	var layer: AmbientLayer = made[1]
	var pivot: Node2D = made[2]["stir_pivot"]
	var point := POS + Vector2(-50, -45)
	var at := stage.get_global_transform_with_canvas() * point
	var button := Button.new()
	button.position = point - Vector2(15, 15)
	button.size = Vector2(30, 30)
	stage.add_child(button)
	var hit := []
	button.pressed.connect(func(): hit.append(true))
	for down in [true, false]:
		var tap := InputEventScreenTouch.new()
		tap.pressed = down
		tap.position = at
		tree.root.push_input(tap, true)
		var click := InputEventMouseButton.new()
		click.device = InputEvent.DEVICE_ID_EMULATION
		click.button_index = MOUSE_BUTTON_LEFT
		click.pressed = down
		click.position = at
		click.global_position = at
		tree.root.push_input(click, true)
	check_eq(hit.size(), 1, "a normal emulated touch click reaches the button on the board")
	check(not layer.is_processing(), "tap never wakes the stir")
	_move(stage, point, Vector2(-34, 0), false, true)
	check(not layer.is_processing(), "no second shove from a touch-derived mouse event")
	_move(stage, point, Vector2(-34, 0), true)
	layer._process(0.10)
	check(pivot.rotation_degrees < -8.0 and pivot.rotation_degrees >= -12.01, "real drag leans the other way")
	stage.free()

func test_outside_hidden_reentry_and_reduced_motion_never_carry_stale_tilt() -> void:
	var made := _build()
	var stage: Control = made[0]
	var layer: AmbientLayer = made[1]
	var t: Dictionary = made[2]
	var pivot: Node2D = t["stir_pivot"]
	var at := POS + Vector2(-50, -45)
	_move(stage, POS + Vector2(260, 32), Vector2(37, 0))
	check(not layer.is_processing(), "faraway motion does not wake it")
	_move(stage, at, Vector2(37, 0))
	layer._process(0.1)
	check(pivot.rotation > 0.0, "active before hiding the ancestor")
	stage.hide()
	check_eq(pivot.rotation, 0.0, "hiding clears any old target and visible tilt")
	check(not layer.is_processing() and not layer.is_processing_input(), "no hidden observers")
	_move(stage, at, Vector2(-70, 0), true)
	stage.show()
	check(not layer.is_processing() and layer.is_processing_input(), "reappearing waits for fresh movement")
	check_eq(pivot.rotation, 0.0, "hidden drag did not mark it")
	_move(stage, at, Vector2(30, 0))
	layer._process(0.1)
	layer.reduced_motion = AmbientLayer.motion_reduced({"settings": {"reduced_motion": true}})
	_move(stage, at, Vector2(30, 0), true)
	check_eq(pivot.rotation, 0.0, "preference immediately clears and keeps a calm fixed frame")
	check(not layer.is_processing() and not layer.is_processing_input(), "no hooks under reduced motion")
	check(t["holder"].visible, "the explicitly authored still frame remains")
	layer.reduced_motion = false
	check_eq(pivot.rotation, 0.0, "motion re-enable needs a fresh input")
	stage.free()

func test_unflagged_missing_and_pre_reduced_rows_have_no_listener() -> void:
	var plain := _build(false)
	var layer: AmbientLayer = plain[1]
	check(not plain[2].has("stir_pivot"), "no new nodes for unchanged rows")
	check(not layer.is_processing() and not layer.is_processing_input(), "calm plain layer")
	layer.build([{"id": "missing", "sheet": "!fixture-missing", "position": [0, 0], "stir": true}])
	check(layer.things.is_empty(), "missing sheet safely skipped")
	check(not layer.is_processing() and not layer.is_processing_input(), "missing-only layer never schedules")
	plain[0].free()
	var reduced := _build(true, true)
	check(not reduced[1].is_processing() and not reduced[1].is_processing_input(), "initial reduced motion stays calm")
	reduced[0].free()
