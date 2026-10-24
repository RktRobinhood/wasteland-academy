extends SceneTree
## Renders a scene and saves the viewport to a PNG, then quits.
## Needs a real display (use ./screenshot.sh, which wraps this in Xvfb).
##
##   godot --path game --rendering-driver opengl3 --resolution 1080x1920 \
##       --script res://tools/screenshot.gd -- --scene=res://scenes/main.tscn --out=/abs/out.png
##
## Options after "--": --scene=<res path> (default: the main scene), --out=<png path>,
## --frames=<frames to wait before capture> (default 10).


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args := {}
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and a.contains("="):
			var kv := a.substr(2).split("=", true, 1)
			args[kv[0]] = kv[1]
	var scene_path: String = args.get("scene", ProjectSettings.get_setting("application/run/main_scene"))
	var out_path: String = args.get("out", "user://screenshot.png")
	if DisplayServer.get_name() == "headless":
		printerr("screenshot: headless display has no pixels; run under Xvfb (see ./screenshot.sh)")
		quit(2)
		return
	var err := change_scene_to_file(scene_path)
	if err != OK:
		printerr("screenshot: could not load %s (error %d)" % [scene_path, err])
		quit(1)
		return
	for i in int(args.get("frames", "10")):
		await process_frame
	await RenderingServer.frame_post_draw
	var img := root.get_texture().get_image()
	err = img.save_png(out_path)
	if err != OK:
		printerr("screenshot: could not save %s (error %d)" % [out_path, err])
		quit(1)
		return
	print("screenshot: saved %s (%dx%d)" % [ProjectSettings.globalize_path(out_path), img.get_width(), img.get_height()])
	quit(0)
