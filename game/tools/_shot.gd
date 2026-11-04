extends SceneTree
## Temporary: draws questions' figures with their text at phone width, then saves a PNG.
func _initialize() -> void:
	_run.call_deferred()

func _run() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			var kv := a.substr(2).split("=", true, 1)
			args[kv[0]] = kv[1]
	var views: Array = JSON.parse_string(FileAccess.get_file_as_string(args.list))
	var i := 0
	for v in views:
		var q := QuestionEngine.make({"type": v[0], "unknown": v[1], "rep": v[2], "angle": v[3], "seed": int(v[4]), "paper": int(v[5]), "format": "mcq"})
		if q.has("error"):
			print(q.error); continue
		var box := VBoxContainer.new()
		box.size = Vector2(1000, 2200); box.position = Vector2(40, 30)
		root.add_child(box)
		var bg := ColorRect.new(); bg.color = Color(0.05,0.06,0.08); bg.size = Vector2(1080, 2338); bg.show_behind_parent = true
		root.add_child(bg); root.move_child(bg, 0)
		var lab := Label.new(); lab.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; lab.custom_minimum_size = Vector2(1000, 0)
		lab.add_theme_font_size_override("font_size", 36)
		lab.text = "\n".join(q.lines) + "\n\n" + q.asked
		box.add_child(lab)
		var p := PlotView.new()
		box.add_child(p)
		if q.graph != null: p.set_spec(q.graph)
		for f in 6:
			await process_frame
		await RenderingServer.frame_post_draw
		var img := root.get_texture().get_image()
		img.resize(390, 844, Image.INTERPOLATE_LANCZOS)
		img.save_png("%s/%s.png" % [args.out, v[6]])
		box.queue_free(); bg.queue_free()
		await process_frame
		i += 1
	quit(0)
