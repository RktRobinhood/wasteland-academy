extends "res://tests/test_case.gd"
## Worked-solution steps (FAL-426): a step is a String, or {"move", "board"} with a
## move tag. Display always uses the board, and every reader goes through Step.

const PRACTICE := "res://scenes/practice.tscn"
const SAVE := "user://test_step_save.json"
const EXPORT := "res://tools/export_questions.gd"
const VIEW := {"type": "fn-quadratic-features", "unknown": "vertex-form-from-general", "rep": "equation", "angle": "complete-square", "format": "value", "seed": 2}


func test_reads_both_kinds_of_step() -> void:
	var tagged := Step.tagged("substitute", "f(2) = 4 − 6 + 1")
	check_eq(tagged, {"move": "substitute", "board": "f(2) = 4 − 6 + 1"})
	check_eq(Step.text(tagged), "f(2) = 4 − 6 + 1")
	check_eq(Step.move(tagged), "substitute")
	check_eq(Step.text("x = 3"), "x = 3")
	check_eq(Step.move("x = 3"), "", "a String step has no move")
	check_eq(Step.texts(["a", tagged, "c"]), ["a", "f(2) = 4 − 6 + 1", "c"])


func test_map_text_keeps_the_move() -> void:
	var up := func(t: String) -> String: return t.to_upper()
	check_eq(Step.map_text("x = a", up), "X = A")
	check_eq(Step.map_text(Step.tagged("isolate", "x = a"), up), Step.tagged("isolate", "X = A"))


## A worked solution with a tagged step shows that step's board, on the practice
## screen (and so the fight screen, which draws the same card) and in Hint.
func test_worked_solution_shows_the_board() -> void:
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))
	var p: Control = (load(PRACTICE) as PackedScene).instantiate()
	p.save_path = SAVE
	tree.root.add_child(p)
	await tree.process_frame
	p.show_view(VIEW)
	var plain: Array = p.question.solutions[0].steps.duplicate()
	var steps: Array = plain.duplicate()
	steps[0] = Step.tagged("substitute", plain[0])
	p.question.solutions[0].steps = steps
	p.autoplay(false)
	await tree.process_frame
	var box: Node = p.working.find_child("Steps", true, false)
	check(box != null, "the worked solution has its steps")
	if box != null:
		var shown: Array = box.get_children().slice(1).map(func(l): return l.text)
		check_eq(shown, plain, "a tagged step shows as its board, the others as before")
	p.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE))

	var r := Run.new(SaveData.blank(), "quadratics", 1, 42)
	r.start()
	var first: String = r.question.solutions[0].steps[0]
	r.question.solutions[0].steps[0] = Step.tagged("substitute", first)
	check_eq(r.use_hint(), first, "Hint shows the tagged first step's board")


## The checker's export writes steps as text, with each step's move (or null) beside it.
func test_export_writes_text_and_moves() -> void:
	var q := QuestionEngine.make(VIEW)
	var plain: Array = q.solutions[0].steps.duplicate()
	q.solutions[0].steps = [Step.tagged("substitute", plain[0])] + plain.slice(1)
	var e: Dictionary = load(EXPORT).exported(q)
	check_eq(e.solutions[0].steps, plain)
	var moves: Array = ["substitute"]
	moves.resize(plain.size())
	check_eq(e.solutions[0].moves, moves)
	check(e.solutions.slice(1).all(func(sol): return sol.moves.all(func(m): return m == null)), "untagged steps export a null move")
