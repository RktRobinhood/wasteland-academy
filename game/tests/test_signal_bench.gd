extends "res://tests/test_case.gd"

func test_signal_bench_controls_change_the_wave_and_mark_only_on_transmit() -> void:
	var toy: LessonToy = Toys.make({"toy": "signal-bench", "amplitude": 1.0, "period": 8.0})
	check(toy != null, "shared lesson registry builds a signal bench")
	if toy == null:
		return
	var frame := Control.new()
	frame.size = Vector2(1080, 1500)
	tree.root.add_child(frame)
	frame.add_child(toy)
	toy.size = frame.size
	toy.start({"kind": "match", "amplitude": 2.5, "period": 6.0})
	await tree.process_frame
	var amp := toy.find_child("Amplitude", true, false) as HSlider
	var period := toy.find_child("Period", true, false) as HSlider
	var transmit := toy.find_child("Transmit", true, false) as Button
	var feedback := toy.find_child("BenchFeedback", true, false) as Label
	check(amp.custom_minimum_size.y >= 135.0 and period.custom_minimum_size.y >= 135.0, "big touch targets")
	var reports: Array = []
	var finishes: Array = []
	toy.acted.connect(func(r: Dictionary): reports.append(r))
	toy.task_done.connect(func(r: Dictionary): finishes.append(r))
	var initial: float = toy.sample(1.5)
	amp.value = 2.5
	check(toy.sample(1.5) > initial, "Amplitude changes the actual plotted model")
	check_eq(reports.size(), 0, "exploration is not marked")
	transmit.pressed.emit()
	check_eq(reports.size(), 1)
	check_eq(reports[0].hit, false)
	check(feedback.text.contains("period"), "wrong-period hint names the quantity, not the answer")
	check_eq(finishes.size(), 0)
	period.value = 6
	check(absf(toy.sample(1.5) - 2.5) < 0.00001, "quarter of a period is the peak")
	check(absf(toy.sample(7.5) - toy.sample(1.5)) < 0.00001, "period controls spacing")
	transmit.pressed.emit()
	check_eq(finishes.size(), 1)
	check_eq(finishes[0].misses, 1)
	check(feedback.text.contains("Signal locked"), "affirmative status is not colour only")
	check(not amp.editable and not period.editable, "completed signal locks both dials")
	var locked: float = toy.sample(1.5)
	toy.perform({"amplitude": 1.0, "period": 9.0})
	check_eq(toy.sample(1.5), locked, "a locked scope cannot redraw a mismatched signal")
	transmit.pressed.emit()
	check_eq(finishes.size(), 1, "no completion event can repeat")
	toy.start({"kind": "match", "amplitude": 1.5, "period": 5.0})
	check(amp.editable and period.editable and not transmit.disabled, "a new channel re-enables both dials")
	amp.value = 1.5
	period.value = 5.0
	transmit.pressed.emit()
	check_eq(finishes.size(), 2, "a new channel can complete once")
	frame.free()


func test_signal_bench_transfer_task_and_bounds() -> void:
	check(Toys.make({"toy": "signal-bench", "amplitude": 1, "period": 0}) == null, "zero period cannot render")
	check(Toys.make({"toy": "signal-bench", "amplitude": 0.3, "period": 5}) == null, "authored values fit the real dial")
	var toy: LessonToy = Toys.make({"toy": "signal-bench"})
	if toy == null:
		fail("signal bench missing")
		return
	tree.root.add_child(toy)
	var done: Array = []
	toy.task_done.connect(func(r: Dictionary): done.append(r))
	toy.start({"kind": "match", "amplitude": 0.0, "period": 6.0})
	check_eq(toy.task, {}, "a flat reference does not encode an identifiable period")
	var task := {"kind": "match", "amplitude": 1.5, "period": 5.0}
	toy.start(task)
	for input in toy.script_for(task, true):
		toy.perform(input)
	check_eq(done.size(), 1)
	if not done.is_empty():
		check_eq(done[0].amplitude, 1.5)
		check_eq(done[0].period, 5.0)
		check_eq(done[0].misses, 1)
	toy.free()