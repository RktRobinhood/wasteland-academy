extends "res://tests/test_case.gd"
## The fight screen (FAL-413, FAL-415): plays a run with the card, the HP bars, the timer
## and the lifelines, shows the worked solution after a miss and the summary at the end,
## the floor select, and a boss's parts with the value carried on, and fits a 360 px
## phone, a 390 px phone and a PC window.

const FIGHT := "res://scenes/fight.tscn"
const SAVE := "user://test_fight_save.json"


func _area(window: Vector2i) -> Vector2:
	var base := Vector2(1080, 1920)
	var scale := minf(window.x / base.x, window.y / base.y)
	return Vector2(window) / scale


func _screen(area: Vector2, seed_no: int = 3, select := false, save: Dictionary = {}, fight := 1,
		region := "quadratics") -> Array:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	if not save.is_empty():
		SaveData.store(save, SAVE)
	var frame := Control.new()
	frame.size = area
	tree.root.add_child(frame)
	var f: Control = (load(FIGHT) as PackedScene).instantiate()
	f.save_path = SAVE
	f.run_seed = seed_no
	f.select_first = select
	f.first_fight = fight
	f.region = region
	frame.add_child(f)
	await tree.process_frame
	return [frame, f]


func _done(made: Array) -> void:
	made[0].free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))


func test_a_wrong_answer_shows_its_worked_solution() -> void:
	var made: Array = await _screen(_area(Vector2i(390, 844)))
	var f: Control = made[1]
	check_eq(f.run.state, "question")
	check(f.card.get_node_or_null("Prompt") != null, "the question card")
	f.autoplay(false)
	await tree.process_frame
	check_eq(f.run.state, "result")
	check_eq(f.result.outcome, "wrong")
	check(f.working.visible, "the worked solution shows")
	check(f.feedback.text.begins_with("Missed"), f.feedback.text)
	check(f.next_button.visible)
	check_eq(int(f.player_bar.value), f.run.hp)
	f.next_question()
	await tree.process_frame
	check_eq(f.run.state, "question")
	f.autoplay(true)
	check(f.result.outcome in ["right", "late"], str(f.result.outcome))
	check(not f.working.visible, "no worked solution after a hit")
	check_eq(int(f.enemy_bar.value), int(f.run.enemy.hp))
	_done(made)


func test_the_timer_drains_into_a_timeout() -> void:
	var made: Array = await _screen(_area(Vector2i(390, 844)))
	var f: Control = made[1]
	f._process(f.run.time_total * 0.6)
	check_eq(f.timer_fill.bg_color, f.ORANGE, "orange past half")
	f._process(f.run.time_total * 0.3)
	check_eq(f.timer_fill.bg_color, f.RED, "red in the late zone")
	f._process(f.run.time_total)
	check_eq(f.result.outcome, "timeout")
	check(f.working.visible, "the worked solution shows after a timeout")
	_done(made)


func test_lifelines_on_the_screen() -> void:
	var made: Array = await _screen(_area(Vector2i(390, 844)))
	var f: Control = made[1]
	f.use_lifeline("hint")
	check(f.hint_label.visible and f.hint_label.text.begins_with("Hint: "), f.hint_label.text)
	check(f.lifeline_buttons.hint.disabled, "used up")
	f.use_lifeline("freeze")
	check(f.run.frozen_left > 0.0)
	var left: float = f.run.time_left
	f._process(5.0)
	check_eq(f.run.time_left, left, "frozen")
	_done(made)


func test_the_run_ends_in_a_summary() -> void:
	var made: Array = await _screen(_area(Vector2i(390, 844)))
	var f: Control = made[1]
	f.lose()
	await tree.process_frame
	check_eq(f.run.state, "ended")
	check(f.summary_box.visible and not f.scroll.visible, "the summary replaces the card")
	check(not f.timer_bar.is_visible_in_tree(), "no timer on the summary")
	check(f.summary_box.get_node_or_null("Missed") != null and f.summary_box.get_node("Missed").get_child_count() > 0, "skills missed")
	var saved := SaveData.load_from(SAVE)
	check_eq(saved.scrap, f.run.summary.scrap, "the Scrap is saved")
	check_eq(saved.runs.played, 1)
	_done(made)


func test_quit_shows_the_summary() -> void:
	var made: Array = await _screen(_area(Vector2i(390, 844)))
	var f: Control = made[1]
	f.autoplay(true)
	f.next_question()
	f.quit_button.pressed.emit()
	check_eq(f.run.summary.reason, "quit")
	check(f.summary_box.visible)
	_done(made)


func test_fits_a_360_phone() -> void:
	await _check_fits(Vector2i(360, 780))


func test_fits_a_390_phone() -> void:
	await _check_fits(Vector2i(390, 844))


func test_fits_a_pc_window() -> void:
	await _check_fits(Vector2i(1280, 800))


## Every region's title, the all-regions dungeon's too, leaves Quit on screen, clear
## of the title and of the speaker and gear's strip (FAL-506). A region with no
## questions yet can't start a run, so its title goes on a Quadratics run.
func test_quit_fits_beside_every_region_title() -> void:
	var regions: Array = [Dungeon.ALL]
	for r in QuestionEngine.catalogue().get("regions", []):
		regions.append(r.id)
	check(regions.has("exp-log") and Progress.is_built("exp-log"), "the longest title is in the list, and playable")
	for window in [Vector2i(360, 780), Vector2i(390, 844), Vector2i(1280, 800)]:
		var area := _area(window)
		var screen := Rect2(Vector2.ZERO, area)
		for region in regions:
			var built := Progress.is_built(region)
			var made: Array = await _screen(area, 3, false, {}, 1, region if built else "quadratics")
			var f: Control = made[1]
			if not built:
				f.region = region
				f._update_hud()
			for i in 3:
				await tree.process_frame
			var what := "%s %s" % [window, region]
			check(f.title.text.begins_with(Dungeon.region_name(region)), "%s: title %s" % [what, f.title.text])
			var quit: Rect2 = f.quit_button.get_global_rect()
			var title: Rect2 = f.title.get_global_rect()
			check(f.quit_button.is_visible_in_tree(), "%s: Quit shows" % what)
			check(screen.encloses(quit), "%s: Quit %s outside %s" % [what, quit, screen])
			check(quit.end.x <= area.x - AudioHud.RESERVED_RIGHT + 1, "%s: Quit %s under the speaker and gear" % [what, quit])
			check(title.end.x <= quit.position.x + 1, "%s: the title %s runs into Quit %s" % [what, title, quit])
			check(f.title.get_line_count() <= 2, "%s: the title takes %d lines" % [what, f.title.get_line_count()])
			_done(made)


## The column, the HUD and the card fit the width (the card scrolls down), with the
## question, a wrong answer's worked solution and the summary.
func _check_fits(window: Vector2i) -> void:
	var area := _area(window)
	var made: Array = await _screen(area, 5)
	var f: Control = made[1]
	for stage in ["question", "wrong", "summary"]:
		match stage:
			"wrong":
				f.autoplay(false)
			"summary":
				f.lose()
		for i in 3:
			await tree.process_frame
		var screen := Rect2(Vector2.ZERO, area)
		var col := f.get_node("Margin/Column") as Control
		check(screen.encloses(col.get_global_rect()), "%s %s: column %s outside %s" % [window, stage, col.get_global_rect(), screen])
		for c in col.find_children("*", "Control", true, false):
			if c.is_visible_in_tree() and not c is ScrollBar:
				var r: Rect2 = c.get_global_rect()
				check(r.end.x <= col.get_global_rect().end.x + 1 and r.position.x >= col.get_global_rect().position.x - 1,
						"%s %s: %s sticks out (%s)" % [window, stage, c.name, r])
		var scroll: ScrollContainer = f.scroll
		if stage != "summary":
			check(scroll.size.y >= 500, "%s %s: room for the card (%s)" % [window, stage, scroll.size.y])
	_done(made)


# ── The scroller is the fight screen (FAL-331) ───────────────

func test_an_answer_box_stays_on_the_card() -> void:
	# FAL-743: the fight's card is narrower than the practice screen's.
	var made: Array = await _screen(_area(Vector2i(360, 800)))
	var f: Control = made[1]
	f.question = QuestionEngine.make({"type": "t1-standard-form", "unknown": "to-ordinary-small", "rep": "equation", "angle": "place-shift", "format": "value", "seed": 1})
	f.render_question()
	await tree.process_frame
	var box: LineEdit = f.card.find_children("Slot_*", "LineEdit", true, false)[0]
	box.text = "8".repeat(40)
	await tree.process_frame
	await tree.process_frame
	check_eq(box.text.length(), f.SLOT_CHARS, "a box stops at its limit")
	check(box.get_global_rect().end.x <= f.card.get_global_rect().end.x + 0.5, "the box runs off the card")
	_done(made)


func test_the_scene_is_the_fight_screen() -> void:
	for spec in [[Vector2i(390, 844), 0.25, 1240], [Vector2i(360, 780), 0.25, 1240], [Vector2i(1280, 800), 0.3, 1400]]:
		var area := _area(spec[0])
		var made: Array = await _screen(area)
		var f: Control = made[1]
		for i in 3:
			await tree.process_frame
		var what := str(spec[0])
		var scene: Rect2 = f.scene_box.get_global_rect()
		check(scene.size.y / area.y >= spec[1] and scene.size.y / area.y <= 0.35, "%s: the scene takes %.2f of the height" % [what, scene.size.y / area.y])
		check(f.strip.is_visible_in_tree(), "%s: the strip shows" % what)
		check(f.strip._width() >= JourneyStage.MIN_W - 1.0, "%s: the party and monsters fit (%.0f units)" % [what, f.strip._width()])
		check(f.find_child("Status", true, false) == null, "%s: no enemy panel under the scene" % what)
		check(not f.enemy_art.visible, "%s: the enemy stands in the scene" % what)
		var tag: Rect2 = f.enemy_bar.get_parent().get_parent().get_global_rect()
		check(scene.encloses(tag), "%s: the enemy's name and HP are over the scene (%s)" % [what, tag])
		check(tag.size.y <= scene.size.y * 0.25, "%s: and small (%s)" % [what, tag])
		var head: Rect2 = f.title.get_parent().get_parent().get_global_rect()
		check(head.size.y <= 200, "%s: a slim header (%s)" % [what, head])
		check(f.player_bar.is_visible_in_tree() and f.scrap_label.is_visible_in_tree(), "%s: HP and Scrap" % what)
		check(f.scroll.size.y >= spec[2], "%s: room for the question (%.0f)" % [what, f.scroll.size.y])
		var floor_line: Rect2 = f.progress.get_parent().get_global_rect()
		check(scene.encloses(floor_line), "%s: the floor line is over the scene (%s)" % [what, floor_line])
		check(not floor_line.intersects(tag), "%s: and clear of the enemy's name (%s)" % [what, floor_line])
		_done(made)


## The first seed whose fight 1 is that kind of beat, on floor 1 of the journey's region.
func _seed_for(kinds: Array) -> Dictionary:
	var assets := JourneyStage.shared_assets()
	var roster := assets.roster("signal-tower")
	for s in range(1, 2000):
		var tier := Dungeon.tier_for(s, 1, 1)
		var e := JourneyBeats.encounter(s, 1, tier, roster, Tuning.ENEMIES[tier].hits)
		if e.kind in kinds:
			return {"seed": s, "encounter": e, "sheet": assets.sheets.get(e.prop, {})}
	return {}


## Every label on an Explore or Puzzle beat is the job the strip draws (FAL-733).
func test_a_job_talks_about_the_job() -> void:
	for kind in ["explore", "puzzle"]:
		var pick := _seed_for([kind])
		var made: Array = await _screen(_area(Vector2i(390, 844)), pick.seed)
		var f: Control = made[1]
		for i in 3:
			await tree.process_frame
		check_eq(f.strip.encounter.prop, pick.encounter.prop, "the strip draws this prop")
		check_eq(f.enemy_name.text, pick.sheet.label, "the overlay names the job")
		check(not f.enemy_name.text.contains("·"), "no tier tag")
		check_eq(f.check_button.text, pick.sheet.verb, "the button says the job")
		check(f.enemy_bar.is_visible_in_tree(), "the bar stays")
		f.autoplay(true)
		check(f.feedback.text.begins_with(pick.sheet.hit), f.feedback.text)
		check(f.feedback.text.contains("+%d Scrap" % f.result.scrap), f.feedback.text)
		check(not f.feedback.text.contains("enemy") and not f.feedback.text.contains("Hit!"), f.feedback.text)
		while f.run.state != "ended" and not f.result.get("defeated", false):
			f.next_question()
			f.autoplay(true)
		check(f.feedback.text.contains(pick.sheet.done), f.feedback.text)
		check(not f.feedback.text.contains("falls"), f.feedback.text)
		check_eq(f.next_button.text, "Walk on")
		_done(made)


## Fight after fight, the overlay names what the strip has come to, with no strip call
## read back.
func test_the_label_follows_the_strip_through_a_run() -> void:
	var made: Array = await _screen(_area(Vector2i(390, 844)), 11)
	var f: Control = made[1]
	var jobs := 0
	var monsters := 0
	for i in 60:
		if f.run.state == "ended":
			break
		await tree.process_frame
		await tree.process_frame
		var e: Dictionary = f.strip.encounter
		if e.kind in ["explore", "puzzle"]:
			jobs += 1
			check_eq(f.enemy_name.text, f.strip.assets.sheets[e.prop].label, "fight %d" % f.run.fight)
		else:
			monsters += 1
			check_eq(f.enemy_name.text, "%s · D%d" % [f.run.enemy.name, f.run.tier], "fight %d" % f.run.fight)
		f.autoplay(true)
		await tree.process_frame
		await tree.process_frame
		f.next_question()
	check(jobs > 0 and monsters > 0, "both kinds played: %d jobs, %d monsters" % [jobs, monsters])
	_done(made)


func test_a_part_hit_and_a_late_one_stay_on_the_job() -> void:
	var made: Array = await _screen(_area(Vector2i(390, 844)), _seed_for(["explore"]).seed)
	var f: Control = made[1]
	f.answered = false
	f._show_result({"outcome": "glancing", "note": "", "enemy_damage": 5, "player_damage": 0, "scrap": 5, "bonus": 0,
		"solution": [], "dead": false, "defeated": false})
	check(f.feedback.text.begins_with("It barely moves"), f.feedback.text)
	f._show_result({"outcome": "late", "note": "", "enemy_damage": 10, "player_damage": 5, "scrap": 5, "bonus": 0,
		"solution": [], "dead": false, "defeated": false})
	check(f.feedback.text.begins_with("Late, but it gives"), f.feedback.text)
	_done(made)


## A monster's beat reads as it always did.
func test_a_fight_reads_as_a_fight() -> void:
	var pick := _seed_for(["fight"])
	var made: Array = await _screen(_area(Vector2i(390, 844)), pick.seed)
	var f: Control = made[1]
	check_eq(f.check_button.text, "Attack")
	check_eq(f.enemy_name.text, "%s · D%d" % [f.run.enemy.name, f.run.tier])
	f.autoplay(true)
	check(f.feedback.text.begins_with("Hit!"), f.feedback.text)
	while f.run.state != "ended" and not f.result.get("defeated", false):
		f.next_question()
		f.autoplay(true)
	check(f.feedback.text.contains("The %s falls." % f.run.enemy.name), f.feedback.text)
	check_eq(f.next_button.text, "Next fight")
	_done(made)


## With no strip showing nothing names a job, and the run plays the same.
func test_no_strip_keeps_the_fight_labels() -> void:
	var pick := _seed_for(["explore"])
	var on: Array = await _screen(_area(Vector2i(390, 844)), pick.seed)
	var save := SaveData.blank()
	save.profile = {"avatar": "robot"}
	var off: Array = await _screen(_area(Vector2i(390, 844)), pick.seed, false, save)
	var g: Control = off[1]
	check_eq(g.check_button.text, "Attack")
	check_eq(g.enemy_name.text, "%s · D%d" % [g.run.enemy.name, g.run.tier])
	var f: Control = on[1]
	check_eq(f.run.question.view, g.run.question.view, "the same question")
	f.autoplay(true)
	g.autoplay(true)
	check_eq(g.next_button.text, "Next question")
	check(g.feedback.text.begins_with("Hit!"), g.feedback.text)
	for k in ["outcome", "scrap", "enemy_damage", "player_damage", "defeated"]:
		check_eq(g.result[k], f.result[k], k)
	check_eq(g.run.hp, f.run.hp, "the same HP")
	_done(on)
	_done(off)


func test_the_phone_scene_runs_edge_to_edge() -> void:
	var area := _area(Vector2i(390, 844))
	var made: Array = await _screen(area)
	var f: Control = made[1]
	for i in 3:
		await tree.process_frame
	check_eq(f.scene_box.size.x, area.x)
	_done(made)


func test_no_sheet_keeps_the_enemy_on_the_screen() -> void:
	var save := SaveData.blank()
	save.profile = {"avatar": "robot"}
	var area := _area(Vector2i(390, 844))
	var made: Array = await _screen(area, 3, false, save)
	var f: Control = made[1]
	for i in 3:
		await tree.process_frame
	check(not f.strip.visible, "no strip")
	check(f.enemy_art.is_visible_in_tree() and f.enemy_art.texture != null, "the portrait stands in")
	check(f.enemy_name.is_visible_in_tree(), "the name and HP stay")
	f.autoplay(true)
	check_eq(f.result.outcome in ["right", "late"], true, "the fight plays the same")
	_done(made)


## A long question scrolls in the card at the size students use.
func test_a_long_question_scrolls() -> void:
	var made: Array = await _screen(_area(Vector2i(390, 844)))
	var f: Control = made[1]
	var filler := Control.new()
	filler.custom_minimum_size.y = 3000
	f.card.add_child(filler)
	for i in 3:
		await tree.process_frame
	check(f.card.size.y > f.scroll.size.y, "taller than its room")
	check(f.scroll.get_v_scroll_bar().max_value >= 3000, "and it scrolls")
	_done(made)


## The top edge is one stripe at any width: only the whole stripes repeat (FAL-733).
func test_the_stripe_repeats_whole() -> void:
	for width in [100.0, 360.0, 500.0, 760.0, 1168.0]:
		var pieces: Array = CardFrame.stripe_pieces(width)
		check_eq(pieces[0].from, CardFrame.SLICE, "it leaves the left corner as the art does")
		check_eq(pieces[-1].from + pieces[-1].span, 360 - CardFrame.SLICE, "and meets the right corner")
		var drawn := 0.0
		for p in pieces:
			drawn += p.width
		check(absf(drawn - (width - CardFrame.SLICE * 2)) < 0.01, "%s: fills the edge (%s)" % [width, drawn])
		var middle := pieces.slice(1, -1)
		for p in middle:
			check_eq([p.from, p.span], [CardFrame.STRIPE_FROM, CardFrame.STRIPE_SPAN], "a whole run of stripes")
		if width >= 500.0:
			var stretch: float = pieces[0].width / pieces[0].span
			check(stretch >= 0.7 and stretch <= 1.3, "%s: not squashed (%.2f)" % [width, stretch])


## The reel's metal frame stays put around the card; the question scrolls inside it.
func test_the_card_has_its_frame() -> void:
	for spec in [[Vector2i(390, 844), 50], [Vector2i(360, 780), 50], [Vector2i(1280, 800), 80]]:
		var area := _area(spec[0])
		var made: Array = await _screen(area)
		var f: Control = made[1]
		for i in 3:
			await tree.process_frame
		var what := str(spec[0])
		var frame: CardFrame = f.card_frame
		check(frame.is_visible_in_tree(), "%s: the frame shows" % what)
		check_eq(frame.thickness(), spec[1], what)
		check(Rect2(Vector2.ZERO, area).encloses(frame.get_global_rect()), "%s: frame on the screen (%s)" % [what, frame.get_global_rect()])
		var inside := frame.get_global_rect().grow(-frame.thickness())
		check(inside.encloses(f.scroll.get_global_rect()), "%s: the card is inside the frame" % what)
		var filler := Control.new()
		filler.custom_minimum_size.y = 3000
		f.card.add_child(filler)
		for i in 3:
			await tree.process_frame
		f.scroll.scroll_vertical = 1000
		await tree.process_frame
		check(inside.encloses(f.scroll.get_global_rect()), "%s: the frame holds still as the card scrolls" % what)
		_done(made)


func test_only_the_question_has_the_frame() -> void:
	var made: Array = await _screen(_area(Vector2i(390, 844)), 3, true)
	var f: Control = made[1]
	check(not f.card_frame.visible, "not around the floor select")
	f.start_run()
	check(f.card_frame.visible, "around the question")
	f.lose()
	check(not f.card_frame.visible, "not around the summary")
	_done(made)


## The widest cards in the catalogue, in the fight's framed column on the smallest phone.
func test_wide_tables_and_long_answers_fit_the_frame() -> void:
	var made: Array = await _screen(_area(Vector2i(360, 780)))
	var f: Control = made[1]
	for i in 3:
		await tree.process_frame
	var seen := {"table": 0, "wrapped": 0}
	for c: Dictionary in QuestionEngine.cells(false, ["fn-sketch-gdc", "fn-gdc-features", "fn-concept-asymptote-meaning", "fn-ext-exp-graph"]):
		var v := c.duplicate()
		v.format = "value"
		v.seed = 1
		f.show_view(v)
		if f.question.has("error"):
			continue
		await tree.process_frame
		check(f.card.get_combined_minimum_size().x <= f.scroll.size.x, "%s %s: %s wide in %s" % [c.type, c.unknown, f.card.get_combined_minimum_size().x, f.scroll.size.x])
		var table: Node = f.card.find_child("TableScroll", true, false)
		if table != null and table.get_child(0).get_combined_minimum_size().x > table.size.x:
			seen.table += 1
			check(table.get_h_scroll_bar().max_value >= table.get_child(0).get_combined_minimum_size().x, "%s: the table scrolls sideways" % c.type)
		for b: Button in f.card.find_children("*", "Button", true, false):
			if b.autowrap_mode != TextServer.AUTOWRAP_OFF and b.get_parent().name == "Slots":
				seen.wrapped += 1
				check(b.size.x <= f.scroll.size.x and b.size.y >= UiTheme.BIG * 2, "%s: the answer wraps (%s)" % [c.type, b.size])
	check(seen.table > 0, "a table wider than the card was tried")
	check(seen.wrapped > 0, "a long word-choice answer was tried")
	_done(made)


# ── The dungeon (FAL-415) ────────────────────────────────────

func test_the_floor_select_offers_beaten_floors() -> void:
	var save := SaveData.blank()
	var made: Array = await _screen(_area(Vector2i(390, 844)), 3, true, save)
	var f: Control = made[1]
	check(f.floor_box.visible and f.run == null, "it opens on the floor select")
	check(not f.quit_button.visible, "nothing to quit yet")
	var floors: Node = f.floor_box.get_node("Floors")
	check(floors.get_node_or_null("Floor1") is Button, "floor 1")
	check(floors.get_node_or_null("Floor2") == null, "floor 2 is locked")
	check(floors.get_node("Locked").text.contains("Floor 2 · beat the floor 1 boss"), floors.get_node("Locked").text)
	_done(made)
	Dungeon.note_floor(save, "quadratics", 1, true)
	Dungeon.note_floor(save, "quadratics", 2, true)
	Dungeon.note_floor(save, "quadratics", 3, false)
	made = await _screen(_area(Vector2i(390, 844)), 3, true, save)
	f = made[1]
	floors = f.floor_box.get_node("Floors")
	for n in [1, 2, 3]:
		check(floors.get_node_or_null("Floor%d" % n) is Button, "floor %d is open" % n)
	check(floors.get_node_or_null("Floor4") == null, "floor 3's boss isn't beaten")
	check(floors.get_node("Locked").text.contains("Floor 4 · beat the floor 3 boss"), floors.get_node("Locked").text)
	(floors.get_node("Floor3") as Button).pressed.emit()
	await tree.process_frame
	check(f.run != null and f.run.start_floor == 3, "the run starts on floor 3")
	check(not f.floor_box.visible and f.scroll.visible)
	check(f.title.text.contains("Floor 3"), f.title.text)
	_done(made)


func test_a_boss_part_shows_the_value_carried_on() -> void:
	var made: Array = await _screen(_area(Vector2i(390, 844)), 3, false, {}, 10)
	var f: Control = made[1]
	check_eq(f.run.kind, "boss")
	check(f.card.get_node_or_null("BossPart") != null and f.card.get_node("BossPart").text.begins_with("Boss · part (a)"),
		"the part shows")
	check(f.card.get_node_or_null("Carried") == null, "part (a) carries nothing")
	var a: Dictionary = f.run.question
	f.autoplay(false)
	check(f.feedback.text.contains("carries on from " + a.answer_text), f.feedback.text)
	check_eq(f.next_button.text, "Next part")
	f.next_question()
	await tree.process_frame
	var carried: Node = f.card.get_node_or_null("Carried")
	check(carried != null, "part (b) shows the carried value")
	check(carried.get_child(0).text.contains(a.answer_text), carried.get_child(0).text)
	check(f.card.get_node("PartsDone").get_child(0).text.begins_with("(a) missed"), "part (a) is marked")
	check(f.progress.text.contains("part (b)"), f.progress.text)
	check_eq(f.enemy_hp.text, "%d/%d" % [f.run.boss.parts.size() - 1, f.run.boss.parts.size()], "parts left")
	check(not f.run.records, "a jumped run records nothing")
	_done(made)


func test_the_boss_screens_fit() -> void:
	for window in [Vector2i(360, 780), Vector2i(390, 844), Vector2i(1280, 800)]:
		var area := _area(window)
		var save := SaveData.blank()
		Dungeon.note_floor(save, "quadratics", 1, true)
		Dungeon.note_floor(save, "quadratics", 2, true)
		var made: Array = await _screen(area, 3, true, save)
		var f: Control = made[1]
		for i in 3:
			await tree.process_frame
		_check_inside(f, area, "%s floor select" % window)
		_done(made)
		made = await _screen(area, 3, false, {}, 5)
		f = made[1]
		f.autoplay(false)
		f.next_question()
		for i in 3:
			await tree.process_frame
		_check_inside(f, area, "%s mini-boss part (b)" % window)
		_done(made)


func _check_inside(f: Control, area: Vector2, what: String) -> void:
	var screen := Rect2(Vector2.ZERO, area)
	var col := f.get_node("Margin/Column") as Control
	check(screen.encloses(col.get_global_rect()), "%s: column %s outside %s" % [what, col.get_global_rect(), screen])
	for c in col.find_children("*", "Control", true, false):
		if c.is_visible_in_tree() and not c is ScrollBar:
			var r: Rect2 = c.get_global_rect()
			check(r.end.x <= col.get_global_rect().end.x + 1 and r.position.x >= col.get_global_rect().position.x - 1,
					"%s: %s sticks out (%s)" % [what, c.name, r])


func test_title_screen_has_play() -> void:
	var main := (load("res://scenes/main.tscn") as PackedScene).instantiate()
	check(main.get_node_or_null("Center/Column/Buttons/Play") is Button, "no Play button")
	main.free()
