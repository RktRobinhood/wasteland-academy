extends "res://tests/test_case.gd"
## The explainers (FAL-429): steps tagged from the move map as the engine builds them,
## every move with its two voice files, the player, "Watch it" and the Voice bus.

const PRACTICE := "res://scenes/practice.tscn"
const SAVE := "user://test_explainer_save.json"
const VIEW := {"type": "fn-quadratic-features", "unknown": "vertex-from-general", "rep": "equation", "angle": "complete-square", "format": "value", "seed": 2}


func _question() -> Dictionary:
	return preload("res://ui/explain_screen.gd").question_for(VIEW)


func test_every_move_used_exists_and_has_two_voice_files() -> void:
	var d := Moves.data()
	check(Moves.ids().size() >= 80, "only %d moves" % Moves.ids().size())
	for key in d.map:
		for count in d.map[key]:
			for m in d.map[key][count]:
				check(m == null or Moves.has(m), "%s (%s): no move %s" % [key, count, m])
	for b in d.branches:
		check(Moves.has(b.move), "branch %s: no move %s" % [b.key, b.move])
	for id in Moves.ids():
		check(Moves.say(id) != "", "%s has no line" % id)
		for take in range(1, Moves.TAKES + 1):
			check(ResourceLoader.exists(Moves.voice(id, take)), "missing %s" % Moves.voice(id, take))


func test_steps_are_tagged_from_the_map() -> void:
	var q := _question()
	var sol: Dictionary = q.solutions[0]
	var list: Array = Moves.list_for(VIEW.type, VIEW.unknown, VIEW.rep, sol.angle, sol.steps.size())[1]
	check_eq(list.size(), sol.steps.size(), "the map knows this step count")
	for i in sol.steps.size():
		check_eq(Step.move(sol.steps[i]), "" if list[i] == null else list[i], "step %d" % i)
	# A step count the map doesn't have leaves the steps plain.
	check_eq(Moves.tag(VIEW.type, VIEW.unknown, VIEW.rep, sol.angle, ["only one step"]), ["only one step"])
	check_eq(Moves.tag("no-such-type", "x", "equation", "any", ["a", "b"]), ["a", "b"])


## How many built methods end up with a tagged step: one question per cell, every
## solution it shows. Every method in the map that is built must come out tagged; the
## rest wait for the map (curriculum/moves-map.json). The numbers go in the PR (FAL-429).
func test_every_mapped_method_has_a_tagged_step() -> void:
	var methods := {}
	for c in QuestionEngine.cells():
		var q := QuestionEngine.make({"type": c.type, "unknown": c.unknown, "rep": c.rep, "angle": c.angle, "format": "value", "seed": 1})
		if q.has("error"):
			continue
		for sol in q.solutions:
			var key := "%s/%s/%s" % [c.type, c.unknown, sol.angle]
			methods[key] = methods.get(key, false) or Moves.any_tagged(sol.steps)
	var tagged := methods.values().count(true)
	var mapped := methods.keys().filter(func(k): return Moves.data().map.has(k))
	print("  explainer coverage: %d of %d built methods have a tagged step (%d of them in the move map)" % [tagged, methods.size(), mapped.size()])
	for k in mapped:
		check(methods[k], "%s is in the map but has no tagged step" % k)
	check(mapped.size() >= 400, "only %d mapped methods built" % mapped.size())


func test_the_player_plays_a_chapter_per_step() -> void:
	var q := _question()
	var e := Explainer.make(q, 0)
	tree.root.add_child(e)
	await tree.process_frame
	check_eq(e.chapters.size(), q.solutions[0].steps.size(), "a chapter per step")
	check(e.playing, "it starts playing")
	check(e.captions and e.caption_box.visible, "captions start on")
	e.pause()
	var i := -1
	for j in e.chapters.size():
		if e.chapters[j].move != "":
			i = j
			break
	check(i >= 0, "a tagged chapter")
	e.seek(e.chapters[i].start + 0.2)
	check_eq(e.current, i, "seek lands in the chapter")
	check_eq(e.caption.text, Moves.say(e.chapters[i].move), "the caption is the move's line")
	var line: Control = e.lines.get_child(i)
	check(float(line.get("visible_ratio")) > 0.0 and float(line.get("visible_ratio")) < 1.0, "the chalk is part way through the line")
	if i + 1 < e.chapters.size():
		check_eq(e.lines.get_child(i + 1).modulate.a, 0.0, "the next line isn't written yet")
	e.set_captions(false)
	check(not e.caption_box.visible, "CC turns the captions off")
	e.set_captions(true)
	check_eq(e.speed, 1.0)
	e.next_speed()
	check_eq(e.speed_button.text, "1.5×")
	e.next_speed()
	check_eq(e.speed_button.text, "0.75×")
	e.time = e.chapters[i].start + 1.0
	e.replay_step()
	check(e.playing and is_equal_approx(e.time, e.chapters[i].start), "replay goes back to the step's start")
	e.pause()
	e.seek(e.total)
	check(e.turn_button.visible, "Your turn shows at the end")
	check_eq(e.play_button.text, "Watch again")
	var seed: int = e.question.view.seed
	e.new_numbers()
	check(e.question.view.seed != seed, "new numbers come from a new seed")
	check(Explainer.can_play(e.question.solutions[e.solution]), "and still have a move to watch")
	e.free()


## The frame, with its title, captions, scrub bar and buttons, sits inside the screen on
## a phone and on a PC (a frame sized before the chalk lines had a width once grew to
## four screens tall, with only the slate showing).
func test_the_player_fits_the_screen() -> void:
	for window in [Vector2i(390, 844), Vector2i(1280, 800), Vector2i(1440, 900), Vector2i(1100, 1000)]:
		var base := Vector2(1080, 1920)
		var area := Vector2(window) / minf(window.x / base.x, window.y / base.y)
		var holder := Control.new()
		holder.size = area
		tree.root.add_child(holder)
		var e := Explainer.make(_question(), 0)
		holder.add_child(e)
		for i in 3:
			await tree.process_frame
		var screen := Rect2(Vector2.ZERO, area)
		for n in [e.frame, e.title, e.caption_box, e.scrub, e.play_button, e.cc_button]:
			var c: Control = n
			check(screen.encloses(c.get_global_rect()), "%s: %s is off the screen at %s" % [window, c.name, c.get_global_rect()])
		# FAL-970: the board grows to the window, on a PC as on a phone (it was a third of
		# a 1440 × 900 screen), and the frame keeps clear of the speaker and gear.
		var board: Rect2 = e.frame.find_child("BoardHolder", true, false).get_global_rect()
		check(board.size.y >= area.y * 0.45, "%s: the board is %.0f of %.0f tall" % [window, board.size.y, area.y])
		if area.x > area.y:
			check(e.frame.get_global_rect().end.x <= area.x - AudioHud.RESERVED_RIGHT + 1.0, "%s: the frame runs under the speaker" % window)
		holder.free()


func test_watch_it_on_the_worked_solution() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	var p: Control = (load(PRACTICE) as PackedScene).instantiate()
	p.save_path = SAVE
	tree.root.add_child(p)
	await tree.process_frame
	p.show_view(_question().view)
	p.autoplay(false)
	await tree.process_frame
	var watch := p.working.find_child("WatchIt", true, false) as Button
	check(watch != null, "the worked solution has Watch it")
	if watch != null:
		watch.pressed.emit()
		var e := p.find_child("Explainer", false, false) as Explainer
		check(e != null, "Watch it opens the player over the screen")
		if e != null:
			check(e.turn_enabled, "practice offers Your turn")
			var before: int = p.question.view.seed
			e._on_turn()
			check(p.question.view.seed != before, "Your turn asks the same view with new numbers")
	p.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func test_voice_bus_and_ducking() -> void:
	var audio := tree.root.get_node("Audio")
	check(AudioServer.get_bus_index("Voice") > 0, "a Voice bus")
	var stream := load(Moves.voice("substitute", 1)) as AudioStream
	check(not audio.play_voice(stream), "no voice while sound is off")
	audio.sound_enabled = true
	check(audio.play_voice(stream, 1.5), "a voice line plays with sound on")
	await tree.create_timer(0.4).timeout
	check(audio.ducked(), "the music is ducked under Spark")
	audio.stop_voice()
	await tree.create_timer(0.4).timeout
	check(not audio.ducked(), "and comes back after")
	audio.sound_enabled = false
	audio.reset_settings()
