extends "res://tests/test_case.gd"
## The boot scene loads, runs a few frames and logs no errors, and its column fits on a
## phone and in a PC browser window. The "Classic game" link shows only with the
## takeover switch on, and sits clear of the column.

const MAIN := "res://scenes/main.tscn"


## Every error the engine logs (script or not), from any thread.
class AllErrors extends Logger:
	var _lock := Mutex.new()
	var seen: PackedStringArray = []

	func _log_error(_function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, _error_type: int, _backtraces: Array[ScriptBacktrace]) -> void:
		_lock.lock()
		seen.append("%s:%d: %s" % [file, line, rationale if rationale != "" else code])
		_lock.unlock()


func test_main_scene_boots_with_no_errors() -> void:
	var errors := AllErrors.new()
	OS.add_logger(errors)
	var packed := load(MAIN) as PackedScene
	var main: Node = packed.instantiate() if packed != null else null
	var loaded := main != null
	if loaded:
		tree.root.add_child(main)
		for i in 5:
			await tree.process_frame
		main.queue_free()
		await tree.process_frame
	OS.remove_logger(errors)
	check(loaded, "%s did not load" % MAIN)
	check_eq(errors.seen, PackedStringArray(), "errors logged while booting")


func test_main_is_the_run_scene() -> void:
	check_eq(ProjectSettings.get_setting("application/run/main_scene"), MAIN)


func test_title_and_avatar() -> void:
	var main := (load(MAIN) as PackedScene).instantiate()
	var title := main.get_node_or_null("Center/Column/Title") as Label
	var spark := main.get_node_or_null("Center/Column/Spark") as TextureRect
	check(title != null, "no Title label")
	check(spark != null and spark.texture != null, "no avatar texture")
	if title != null:
		check_eq(title.text, "Wasteland Academy", "title text")
	main.free()


func test_column_fits_on_a_phone() -> void:
	await _check_fits(Vector2i(390, 844))


func test_column_fits_in_a_pc_window() -> void:
	await _check_fits(Vector2i(1280, 800))


func test_no_classic_link_with_the_switch_off() -> void:
	# Off the web there's no page, so no wa-classic meta: as with the switch off
	check_eq(preload("res://ui/main.gd").classic_url(), "")
	var main := (load(MAIN) as PackedScene).instantiate()
	tree.root.add_child(main)
	await tree.process_frame
	check(main.get_node_or_null("Classic") == null, "a Classic link with the switch off")
	main.free()


func test_classic_link_on_a_phone() -> void:
	await _check_fits(Vector2i(390, 844), "classic/")


func test_classic_link_in_a_pc_window() -> void:
	await _check_fits(Vector2i(1280, 800), "classic/")


## Lays the scene out in the area the "expand" stretch gives a window of this size,
## and checks the title column sits inside it with no clipped text.
## With `classic`, also adds the "Classic game" link and checks it's on screen, clear
## of the column.
func _check_fits(window: Vector2i, classic := "") -> void:
	var base := Vector2(ProjectSettings.get_setting("display/window/size/viewport_width"),
			ProjectSettings.get_setting("display/window/size/viewport_height"))
	var scale := minf(window.x / base.x, window.y / base.y)
	var area := Vector2(window) / scale
	var frame := Control.new()
	frame.size = area
	tree.root.add_child(frame)
	var main := (load(MAIN) as PackedScene).instantiate() as Control
	frame.add_child(main)
	var link: LinkButton = main.add_classic_link(classic) if classic != "" else null
	for i in 3:
		await tree.process_frame
	var column := main.get_node("Center/Column") as Control
	var rect := column.get_global_rect()
	var screen := Rect2(Vector2.ZERO, area)
	check(screen.encloses(rect), "%s: column %s outside %s" % [window, rect, screen])
	for label in column.get_children():
		if label is Label:
			check(label.get_visible_line_count() == label.get_line_count(),
					"%s: %s clips its text" % [window, label.name])
	if link != null:
		var at := link.get_global_rect()
		check(screen.encloses(at), "%s: Classic link %s outside %s" % [window, at, screen])
		check(not at.intersects(rect), "%s: Classic link %s over the column %s" % [window, at, rect])
		check_eq(link.text, "Classic game")
	frame.free()
