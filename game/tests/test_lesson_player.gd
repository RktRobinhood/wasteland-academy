extends "res://tests/test_case.gd"
## The lesson player (#218): the rules it plays by (ui/lesson/lesson.gd), a full scripted
## run of the exemplar (writing/explainers/ex.functions.function-machine.json) at a
## 390 px phone, the engine's real touch events on the call, a build tile and a board
## line, the part controls, both recall versions, and every other script played to its end.

const EXEMPLAR := "ex.functions.function-machine"
const SAVE := "user://test_lesson_save.json"
const FRAMES := 4000


func _phone() -> Control:
	Input.emulate_touch_from_mouse = true
	var base := Vector2(1080, 1920)
	var window := Vector2(390, 844)
	var frame := Control.new()
	frame.size = window / minf(window.x / base.x, window.y / base.y)
	frame.theme = UiTheme.make()
	tree.root.add_child(frame)
	return frame


func _player(id := EXEMPLAR, run: ScriptedRun = null, recall := "") -> Array:
	var frame := _phone()
	var p := LessonPlayer.make(Lesson.load_id(id), SaveData.blank())
	p.save_path = SAVE
	p.recall = recall
	p.driver = run
	# The test moves time on itself, so the run doesn't wait on the clock.
	p.paused = true
	var heard: Array = []
	p.line_started.connect(func(l: Dictionary) -> void: heard.append(l))
	frame.add_child(p)
	await _settle()
	return [frame, p, heard]


func _done(made: Array) -> void:
	made[0].free()
	Input.emulate_touch_from_mouse = false
	if FileAccess.file_exists(SAVE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func _settle() -> void:
	for i in 3:
		await tree.process_frame


## Plays until the lesson ends, or until stop(p) is true. Returns whether it got there.
func _run(p: LessonPlayer, stop: Callable = Callable()) -> bool:
	for i in FRAMES:
		if p.state == "done" or (stop.is_valid() and stop.call(p)):
			return true
		p.advance(1000.0)
		await tree.process_frame
	return false


func _ids(heard: Array) -> Array:
	return heard.map(func(l): return str(l.get("line", "")))


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
	await _touch(at, false)
	await _settle()


func _skip_to(p: LessonPlayer, id: String) -> void:
	while p.section().get("id", "") != id and p.state != "done":
		p.skip_section()
	await _settle()


# ── The rules ────────────────────────────────────────────────

func test_the_game_has_a_copy_of_the_exemplar_and_its_shared_lines() -> void:
	var l := Lesson.load_id(EXEMPLAR)
	check(l != null, "no res://data/explainers/%s.json: run node tools/game-explainers.mjs --write" % EXEMPLAR)
	if l == null:
		return
	check_eq(int(l.data.format), 3)
	check(l.predicts.has("call"))
	check(not Lesson.shared("reactions").get("tutors", {}).get("rook-dead-air", {}).is_empty())
	check(not Lesson.shared("callbacks").get("tutors", {}).is_empty())
	check(Lesson.ids().size() >= 12, "only %d lessons" % Lesson.ids().size())


func test_the_call_picks_its_back_to_group() -> void:
	var l := Lesson.load_id(EXEMPLAR)
	var recap: Dictionary = {}
	for b in l.sections()[-1].beats:
		if b.has("back_to"):
			recap = b.back_to
	var first := func(lines: Array) -> String: return str(lines[0].line) if not lines.is_empty() else ""
	check_eq(first.call(l.back_to_lines(recap, "5")), "fuqb8v", "a call of 5 matches")
	check_eq(first.call(l.back_to_lines(recap, " 5.0 ")), "fuqb8v", "as a number")
	check_eq(first.call(l.back_to_lines(recap, "−13")), "tdtylw", "the squaring slip")
	check_eq(first.call(l.back_to_lines(recap, "-13")), "tdtylw", "with a hyphen")
	check_eq(first.call(l.back_to_lines(recap, "7")), "4xrt6n", "anything else")
	check_eq(first.call(l.back_to_lines(recap, null)), "4xrt6n", "a skipped call")
	# The play section's back_to has no value groups: −13 is "other" there.
	var play: Dictionary = l.sections()[1].beats[1].tasks[1].then[1].back_to
	check_eq(first.call(l.back_to_lines(play, "−13")), "iyz9tu")
	check_eq(first.call(l.back_to_lines(play, "5")), "9ns3id")


func test_typed_answers_and_not_yet_lines() -> void:
	var item := {"answer": "80", "accept": ["80%"], "wrong": [{"answer": "92", "misconception": "m#1"}]}
	check(Lesson.mark_typed(item, "80").right)
	check(Lesson.mark_typed(item, "80%").right)
	check(Lesson.mark_typed(item, " 80.0").right)
	check(not Lesson.mark_typed(item, "81").right)
	check_eq(Lesson.mark_typed(item, "92").misconception, "m#1")
	check(Lesson.mark_typed(item, "").get("empty", false), "an empty box isn't a miss")
	var lines := [{"line": "a", "say": "Neutral."}, {"line": "b", "say": "Keyed.", "misconception": "m#1"}]
	check_eq(Lesson.not_yet_for(lines, "m#1")[0].line, "b")
	check_eq(Lesson.not_yet_for(lines, "m#2")[0].line, "a")
	check_eq(Lesson.not_yet_for(lines, "")[0].line, "a")
	check_eq(Lesson.leading_number("300; the tank holds 300 litres"), "300")
	check_eq(Lesson.leading_number("20 minutes"), "20")
	check_eq(Lesson.leading_number("−4.5"), "−4.5")


func test_reactions_never_repeat_and_a_slip_plays_once_per_item() -> void:
	Lesson.Reactions.new_session()
	var r := Lesson.Reactions.new("rook-dead-air", Lesson.shared("reactions"), 1)
	var last := ""
	for i in 30:
		var l := r.slip(0)
		check(not l.is_empty())
		check(str(l.line) != last, "the same reaction twice running")
		last = str(l.line)
	check(r.slip(1).is_empty(), "a second miss on the same item gets no reaction")
	var acks := 0
	for i in 10:
		if not r.ack().is_empty():
			acks += 1
	check(acks > 0 and acks < 10, "an ack plays on some sends, not every one: %d of 10" % acks)
	check(Lesson.Reactions.new("nobody", Lesson.shared("reactions")).slip(0).is_empty(), "a tutor with no set plays none")


## A set of n lines of one kind, for the bag tests.
func _set_of(n: int) -> Dictionary:
	var slips: Array = []
	for i in n:
		slips.append({"line": "s%d" % i, "speaker": "rook-dead-air", "say": "Slip %d." % i})
	return {"tutors": {"rook-dead-air": {"ack": [], "slip": slips}}}


func test_the_bag_plays_every_reaction_before_any_repeats() -> void:
	for seed in 40:
		Lesson.Reactions.new_session()
		var r := Lesson.Reactions.new("rook-dead-air", _set_of(12), seed)
		var played: Array = []
		for round in 5:
			var seen := {}
			for i in 12:
				var id := str(r.slip(0).line)
				check(not seen.has(id), "seed %d: %s again before the set was used up" % [seed, id])
				seen[id] = true
				played.append(id)
			check_eq(seen.size(), 12, "every line once a round")
		for i in range(1, played.size()):
			check(played[i] != played[i - 1], "seed %d: %s twice running across a refill" % [seed, played[i]])


func test_the_bag_lasts_the_session_across_lessons() -> void:
	Lesson.Reactions.new_session()
	var seen := {}
	# A new lesson makes a new picker; the bag is the session's, so it carries on.
	for i in 6:
		var r := Lesson.Reactions.new("rook-dead-air", _set_of(6), i)
		var id := str(r.slip(0).line)
		check(not seen.has(id), "%s again in the same session" % id)
		seen[id] = true
	# Each tutor and kind has its own bag.
	var other := Lesson.Reactions.new("rook-dead-air", Lesson.shared("reactions"), 3)
	check(not other.ack().is_empty(), "acks draw from their own bag")
	Lesson.Reactions.new_session()


func test_the_shipped_set_is_read_and_its_takes_found() -> void:
	Lesson.Reactions.new_session()
	var table := Lesson.shared("reactions")
	var r := Lesson.Reactions.new("rook-dead-air", table, 5)
	var ids: Array = table.tutors["rook-dead-air"].slip.map(func(l): return str(l.line))
	var l := r.slip(0)
	check(str(l.line) in ids, "a slip from reactions.json")
	check(Lesson.Reactions.take(l) != null, "Rook's slips are recorded (FAL-1110)")
	check(Lesson.Reactions.take({"line": "nope00"}) == null, "a line with no take is captioned only")
	Lesson.Reactions.new_session()


func test_a_recall_section_picks_its_version_from_the_watched_record() -> void:
	var l := Lesson.load_id("ex.algebra.arithmetic-sequence")
	var recall: Dictionary = {}
	for s in l.sections():
		if Lesson.has_versions(s):
			recall = s
	check(not recall.is_empty())
	check_eq(l.recall_of(recall), "ex.foundations.pre-substitute")
	check_eq(l.beats_of(recall, ["ex.foundations.pre-substitute"]), recall.watched)
	check_eq(l.beats_of(recall, []), recall.not_watched)
	check_eq(l.beats_of(recall, [], "watched"), recall.watched)
	check_eq(l.beats_of(recall, ["ex.foundations.pre-substitute"], "not_watched"), recall.not_watched)


# ── Playing it ───────────────────────────────────────────────

func test_a_scripted_player_plays_the_exemplar_start_to_finish_at_phone_width() -> void:
	var run := ScriptedRun.new()
	run.call_value = "−13"
	var made: Array = await _player(EXEMPLAR, run)
	var p: LessonPlayer = made[1]
	var heard: Array = made[2]
	var sections_seen := {}
	p.waiting.connect(func(_w): sections_seen[p.section().get("id", "")] = true)
	check(await _run(p), "the lesson didn't end; stuck in %s (%s), log %s" % [p.section().get("id"), p.state, run.done])
	var ids := _ids(heard)
	# Every kind of action the exemplar has was met and done.
	for kind in ["predict", "toy", "optional", "ask", "build", "typed", "turn", "tap-line"]:
		check(kind in run.met, "never waited for a %s" % kind)
	check_eq(p.calls.get("call"), "-13", "the call is kept")
	# The call came back: "other" in the toy, the squaring slip's line in the recap.
	check(ids.has("iyz9tu"), "the toy's back_to")
	check(ids.has("tdtylw"), "the recap's back_to line for −13")
	check(not ids.has("fuqb8v"), "not the match line")
	# Each slip played a reaction, then its not-yet line, and the player went again.
	var from := heard.map(func(l): return str(l.get("_from", "")))
	check(from.count("reactions") >= 3, "reactions on the toy, the build and the typed part: %s" % from.count("reactions"))
	check(ids.has("xquulc") and ids.has("q1vsxs"), "both build steps' not-yet lines: %s / %s" % [run.done, ids])
	check(ids.has("exxlak"), "the typed part's not-yet line")
	check(ids.has("u6isa0") and ids.has("taxdom"), "tap-line: not yet, then right")
	check(ids.has("vnrkur") and ids.has("mnghoh"), "a tap question: not yet, then right")
	check(ids.has("st498u"), "the typed part's right line")
	check(ids.has("rwww0h") and ids.has("xqw813"), "both turns' intros")
	for i in range(1, ids.size()):
		if from[i] == "reactions" and from[i - 1] == "reactions":
			check(ids[i] != ids[i - 1], "the same reaction twice running")
	# Every section played, through to the last line.
	check_eq(ids[-1], "pqbbvg")
	# The board ends on the recap's, and the spot-the-slip line was struck out on the way.
	check(p.board.any(func(b): return b.text.begins_with("f(a)")))
	# The watched record is written at the end.
	check(SaveData.load_from(SAVE).get("watched", []).has(EXEMPLAR), "not in the watched record")
	_done(made)


func test_a_call_that_matches_plays_the_match_lines() -> void:
	var run := ScriptedRun.new()
	run.misses = false
	run.take_optional = false
	var made: Array = await _player(EXEMPLAR, run)
	var p: LessonPlayer = made[1]
	check(await _run(p), "stuck in %s" % p.section().get("id"))
	var ids := _ids(made[2])
	check(ids.has("9ns3id") and ids.has("fuqb8v"), "the match lines")
	check(not ids.has("tdtylw"))
	check(not made[2].any(func(l): return l.get("_from", "") == "reactions" and l.line in ["i2jaqx", "8oguve", "daxuz2", "5ena6n", "z1xu8j"]), "no slips, no slip reactions")
	check("optional" in run.done[run.done.size() - 1] or run.done.has("optional skip"), "the optional toy was skipped")
	_done(made)


func test_the_call_a_build_tile_and_a_board_line_by_touch() -> void:
	var made: Array = await _player()
	var p: LessonPlayer = made[1]
	await _run(p, func(pl): return pl.state == "input")
	check_eq(p.section().get("id"), "opener")
	var pad := p.actions.get_node("Keypad") as Keypad
	for k in ["−", "1", "3"]:
		await _tap(pad.buttons[k])
	await _tap(p.actions.get_node("Entry/Send"))
	check_eq(Lesson.norm(str(p.calls.get("call", ""))), "-13", "the call by touch")
	# Every control a finger uses is a finger tall.
	await _skip_to(p, "example-2")
	await _run(p, func(pl): return pl.state == "input" and pl.actions.has_node("Tiles"))
	var tiles := p.actions.get_node("Tiles")
	for t: Control in tiles.get_children():
		check(t.size.y >= LessonPlayer.TOUCH - 1, "a tile is %d tall" % t.size.y)
	var before := p.board.size()
	await _tap(tiles.get_node("Tile0"))
	check_eq(p.board.size(), before + 1, "the right tile goes on the board")
	check_eq(p.board[-1].text, "h(−2) = 5 − (−2)²")
	await _skip_to(p, "spot-the-slip")
	await _run(p, func(pl): return pl.state == "input")
	var row := p.row_for("s1")
	check(row != null and row.tappable, "the slip's line can be tapped")
	var heard: Array = made[2]
	var n := heard.size()
	await _tap(row)
	await _run(p, func(pl): return heard.size() > n)
	check(_ids(heard.slice(n)).has("taxdom"), "a tap on the board line answers it")
	_done(made)


func test_parts_replay_and_skip_and_the_speed_and_captions_change() -> void:
	var made: Array = await _player()
	var p: LessonPlayer = made[1]
	await _run(p, func(pl): return pl.state == "input")
	p.skip_section()
	await _settle()
	check_eq(p.section().get("id"), "play", "skipped the opener")
	check(p.calls.is_empty(), "a skipped call is not made")
	p.skip_section()
	await _settle()
	check_eq(p.section().get("id"), "the-name")
	var with_play := p.board.size()
	# The next part wipes the board, so the skipped part's is checked where it ended.
	check(p._snapshots[2].any(func(b): return b.text.begins_with("function:")), "the skipped part's board is written")
	await _run(p, func(pl): return pl.state == "input")
	p.replay_section()
	await _settle()
	check_eq(p.section().get("id"), "the-name", "replay stays on the part")
	check_eq(p.board.size(), with_play, "and puts its board back as it started")
	p.next_speed()
	check_eq(p.speed, 1.5)
	p.next_speed()
	check_eq(p.speed, 0.75)
	await _settle()
	var board_size := p.board_panel.size
	p.set_captions(false)
	await _settle()
	check_eq(p.caption_box.modulate.a, 0.0)
	check_eq(p.board_panel.size, board_size, "hiding CC must not resize the board")
	p.set_captions(true)
	check_eq(p.caption_box.modulate.a, 1.0)
	# Skip the rest: the lesson ends and is recorded.
	while p.state != "done":
		p.skip_section()
	check(SaveData.load_from(SAVE).get("watched", []).has(EXEMPLAR))
	_done(made)


func test_both_recall_versions_play() -> void:
	for version in ["watched", "not_watched"]:
		var run := ScriptedRun.new()
		run.misses = false
		var made: Array = await _player("ex.algebra.arithmetic-sequence", run, version)
		var p: LessonPlayer = made[1]
		var recall_at := -1
		for i in p.lesson.sections().size():
			if Lesson.has_versions(p.lesson.sections()[i]):
				recall_at = i
		check(await _run(p, func(pl): return pl.seg > recall_at), "stuck in the recall")
		var want: Array = p.lesson.sections()[recall_at][version]
		var resolved: Dictionary = p._resolve(want[0])
		check(_ids(made[2]).has(str(resolved.line)), "%s: its first line %s" % [version, resolved.line])
		_done(made)


func test_every_script_plays_to_its_end() -> void:
	for id in Lesson.ids():
		var run := ScriptedRun.new()
		var made: Array = await _player(id, run)
		var p: LessonPlayer = made[1]
		check(await _run(p), "%s: stuck in %s (%s); last actions %s" % [id, p.section().get("id"), p.state, run.done.slice(-4)])
		_done(made)


func test_opt_in_preview_reuses_two_separate_parts_and_verified_recordings() -> void:
	var frame := _phone()
	var scene := load("res://scenes/lesson.tscn") as PackedScene
	var screen := scene.instantiate()
	var script: GDScript = screen.get_script()
	script.open_preview = true
	frame.add_child(screen)
	await _settle()
	var snapshot := SaveData.load_from().duplicate(true)
	check(screen.watch_button.visible and screen.try_button.visible, "explicit preview offers both choices")
	check_eq(tree.root.gui_get_focus_owner(), screen.watch_button, "watch starts with keyboard focus")
	await _tap(screen.watch_button)
	var p: LessonPlayer = screen.player
	p.paused = true
	check_eq(p.section().get("id"), "example-1")
	check_eq(p.lesson.sections().size(), 1)
	check(not p.skip_button.visible)
	check(p.clip_for(p.section().beats[0]) != null, "real recorded audio resolves")
	var stale: Dictionary = p.section().beats[0].duplicate()
	stale.say = "Not the approved line."
	check(p.clip_for(stale) == null, "reject unchanged id with different speech")
	var caption_edit: Dictionary = p.section().beats[0].duplicate()
	caption_edit.caption = "Notation updated"
	check(p.clip_for(caption_edit) != null, "accept a caption-only edit")
	check_eq(p.save_path, "", "preview does not write the classroom save")
	await _run(p, func(pl): return pl.state == "input")
	check_eq(p.state, "input", "watch stops to ask why the brackets matter")
	await _settle()
	var choices := p.actions.get_node("Choices")
	var target := choices.get_node("Choice0") as Button
	var bounds := target.get_global_rect()
	var unopened := p.actions.find_child("ExplainWhy", true, false) as Button
	check(not unopened.is_visible_in_tree() and unopened.disabled, "helper is unavailable before a miss")
	await _tap(choices.get_node("Choice1"))
	await _settle()
	check_eq(p.state, "line", "authored feedback plays")
	check(target.disabled and target.is_visible_in_tree(), "feedback locks but does not remove the choice")
	check_eq(target.get_global_rect(), bounds, "wrong feedback keeps the hit area")
	check(p.actions.find_child("WhyFeedback", true, false).text.begins_with("Not quite"), "non-voice feedback")
	target.pressed.emit()
	check_eq(p.state, "line", "no second answer while feedback is playing")
	await _run(p, func(pl): return pl.state == "input")
	await _settle()
	check(p.actions.get_node("Choices") == choices and not target.disabled, "retry re-arms the same buttons")
	check_eq(target.get_global_rect(), bounds, "showing help keeps the retry target")
	var help := p.actions.find_child("ExplainWhy", true, false) as Button
	check(help != null and help.is_visible_in_tree(), "a slip offers a route out of the check")
	await _tap(help)
	check(await _run(p), "watch finishes with an explanation after a slip")
	check(p.board.any(func(row): return str(row.text).contains("g(−4) = 14")), "shows and checks the result")
	p.replay_section()
	check_eq(p.section().get("id"), "example-1")
	p.close()
	await _settle()
	check_eq(tree.root.gui_get_focus_owner(), screen.watch_button, "focus restored to Watch")
	await _tap(screen.try_button)
	p = screen.player
	p.paused = true
	check_eq(p.section().get("id"), "turn-1")
	await _run(p, func(pl): return pl.state == "input")
	check_eq(p.state, "input", "Try asks for a fresh response")
	check_eq(p.section().turn.serve, "fallback", "the curated practice is an exact negative linear twin")
	check(str(p.prompt.text).contains("f(−2)"), "the twin asks for a negative input")
	check(p.board.is_empty(), "the practice board starts blank")
	var console := p.find_child("ActivityStatus", true, false) as Label
	check(console != null, "practice has an in-world relay, separately from the maths board")
	if console != null:
		check_eq(console.text, "Awaiting output")
	await _tap(p.actions.get_node("Keypad").buttons["4"])
	await _tap(p.actions.get_node("Entry/Send"))
	await _run(p, func(pl): return pl.state == "input")
	check_eq(p.state, "input", "a sign slip allows another attempt")
	check(p.actions.has_node("ShowMe"), "a sign slip exposes the help route")
	if console != null:
		check_eq(console.text, "Static · try again", "incorrect maths does not power the relay")
	var entry = p.actions.get_node("Entry/Box")
	entry.text = "16"
	entry.text_submitted.emit("16")
	check(await _run(p), "a correct response completes the transmission")
	if console != null:
		check_eq(console.text, "Signal transmitted", "correct maths powers the relay")
	check(p.board.any(func(row): return str(row.text).contains("= 16")), "working appears only after the attempt")
	check(not p.board.any(func(row): return str(row.text).contains("g(−4) = 14")), "Watch does not leak into Try")
	p.replay_section()
	await _run(p, func(pl): return pl.state == "input")
	check(p.board.is_empty(), "replaying clears the board again")
	if console != null:
		check_eq(console.text, "Awaiting output", "replay resets the relay")
	await _tap(p.actions.get_node("Keypad").buttons["4"])
	await _tap(p.actions.get_node("Entry/Send"))
	await _run(p, func(pl): return pl.state == "input")
	await _tap(p.actions.get_node("ShowMe"))
	check(await _run(p), "help still lets a student finish")
	if console != null:
		check_eq(console.text, "Practice signal · working shown", "help does not pretend the learner sent a correct signal")
	p.close()
	await _settle()
	check_eq(tree.root.gui_get_focus_owner(), screen.try_button, "focus restored to Try")
	check_eq(SaveData.load_from(), snapshot, "native preview leaves the save unchanged")
	frame.free()
	Input.emulate_touch_from_mouse = false
