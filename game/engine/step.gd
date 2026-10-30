class_name Step
extends RefCounted
## One step of a worked solution (a view's methods[angle].steps). A step is either a
## String, or a Dictionary {"move": "<move id>", "board": "<text>"} once it carries a
## move tag for the explainers (FAL-426): the move is the general step, voiced once
## with no numbers (curriculum/moves.json), and the board is this question's text.
## Read steps through these, so no caller branches on the type:
##
##   Step.text(st)                    # what the card shows: the board, or the String
##   Step.move(st)                    # the move id, or "" for an untagged step
##   Step.tagged("substitute", "f(2) = 4 − 6 + 1")


## The step's text as shown: its board, or the String itself.
static func text(step: Variant) -> String:
	if step is Dictionary:
		return str(step.get("board", ""))
	return str(step)


## The step's move id, or "" when it has none.
static func move(step: Variant) -> String:
	if step is Dictionary:
		return str(step.get("move", ""))
	return ""


## A step carrying a move tag.
static func tagged(move_id: String, board: String) -> Dictionary:
	return {"move": move_id, "board": board}


## The texts of a list of steps, in order.
static func texts(steps: Array) -> Array:
	return steps.map(func(st): return text(st))


## The step with its text passed through f (String -> String), keeping its move.
static func map_text(step: Variant, f: Callable) -> Variant:
	if step is Dictionary:
		return tagged(move(step), f.call(text(step)))
	return f.call(step)
