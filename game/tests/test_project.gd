extends "res://tests/test_case.gd"
## Project and Web export settings the FAL-274 plan depends on.

const PRESETS := "res://export_presets.cfg"


func test_own_user_dir_name() -> void:
	# config/name picks the user:// folder; the Atlas uses "The Unruly Atlas".
	check_eq(ProjectSettings.get_setting("application/config/name"), "Wasteland Academy")


func test_portrait_base_resolution() -> void:
	check_eq(ProjectSettings.get_setting("display/window/size/viewport_width"), 1080)
	check_eq(ProjectSettings.get_setting("display/window/size/viewport_height"), 1920)
	check_eq(ProjectSettings.get_setting("display/window/stretch/aspect"), "expand")


func test_compatibility_renderer() -> void:
	check_eq(ProjectSettings.get_setting("rendering/renderer/rendering_method"), "gl_compatibility")
	check_eq(ProjectSettings.get_setting("rendering/renderer/rendering_method.mobile"), "gl_compatibility")


func test_web_preset() -> void:
	var cfg := ConfigFile.new()
	check_eq(cfg.load(PRESETS), OK, "load export_presets.cfg")
	var section := ""
	for s in cfg.get_sections():
		if cfg.get_value(s, "name", "") == "Web":
			section = s
	check(section != "", "no preset named Web")
	if section == "":
		return
	check_eq(cfg.get_value(section, "platform"), "Web", "platform")
	var opts := section + ".options"
	# GitHub Pages can't send the COOP/COEP headers that threads need.
	check_eq(cfg.get_value(opts, "variant/thread_support"), false, "thread_support")
	# The HTML game's service worker already covers the whole site.
	check_eq(cfg.get_value(opts, "progressive_web_app/enabled"), false, "progressive_web_app/enabled")
