class_name FitBox
extends Container
## Holds the fight's question card inside its ScrollContainer and shrinks it, down to
## MIN_SCALE, until the whole card fits its room: the question, a wide table, the
## answers and Attack show at once, with no scroll bar at the side (FAL-331, Matt on
## 2026-11-06). Only a card still too tall at MIN_SCALE (a long worked solution) needs a
## swipe, and the scroll bar stays hidden then too. Before that, a control in the card
## with a LEAST meta (a graph) gives up height down to it, when that lets the whole card
## fit: a 4-option graph question on a phone kept Attack half under the frame (FAL-970).
##
## The card's height depends on its width (text wraps), and a container lays out a frame
## late, so the scale is found over a few frames: one measure at full size, a first guess
## that fits, then a few halvings towards the largest scale that fits. A new question's
## card stays hidden until then, so it never shows at the wrong size.

## The smallest the card is drawn: BODY text at about 12 px on a 390 px phone.
const MIN_SCALE := 0.7
## Halvings after the first guess: within 2% of the best scale.
const STEPS := 4
## The meta on a control in the card that may shrink: the least height it takes.
const LEAST := "fit_least"
## The meta that keeps its own height, to give it back on reset().
const FULL := "fit_full"

## The card's scale now.
var fit := 1.0
## True while the scale is being found.
var fitting := false

var _lo := MIN_SCALE
var _hi := 1.0
var _step := 0


func _init() -> void:
	name = "FitBox"
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	set_process(false)


## Starts again at full size: a new question, or a new window size.
func reset() -> void:
	modulate.a = 0.0
	var c := _child()
	if c != null:
		for g in _givers(c):
			if g.has_meta(FULL):
				g.custom_minimum_size.y = g.get_meta(FULL)
				g.remove_meta(FULL)
	_start(1.0)


func _start(hi: float) -> void:
	fit = hi
	_lo = MIN_SCALE
	_hi = hi
	_step = 0
	fitting = true
	set_process(true)
	_apply()


func _child() -> Control:
	return get_child(0) as Control if get_child_count() > 0 else null


## The height the card has to fit in: its scroller's.
func _room() -> float:
	var p := get_parent() as Control
	return p.size.y if p != null else size.y


## True when the card, laid out at the scale it has now, fits its room: its height, and
## each table's own width, which scrolls sideways when it doesn't.
func fits() -> bool:
	var c := _child()
	if c == null:
		return true
	if c.get_combined_minimum_size().y * fit > _room() + 0.5:
		return false
	for t: Control in c.find_children("TableScroll", "ScrollContainer", true, false):
		if t.get_child_count() > 0 and (t.get_child(0) as Control).get_combined_minimum_size().x > t.size.x + 0.5:
			return false
	return true


func _process(_delta: float) -> void:
	var c := _child()
	if c == null or _room() <= 0.0:
		_finish(fit)
		return
	var ok := fits()
	if _step == 0:
		# Full size first; if it fits there's nothing to find.
		if ok or fit <= MIN_SCALE:
			_finish(fit)
			return
		_hi = fit
		# Wider, the text wraps less, so this guess fits unless the card holds a table.
		var guess := _room() / c.get_combined_minimum_size().y
		for t: Control in c.find_children("TableScroll", "ScrollContainer", true, false):
			if t.get_child_count() > 0:
				guess = minf(guess, fit * t.size.x / (t.get_child(0) as Control).get_combined_minimum_size().x)
		fit = clampf(guess, MIN_SCALE, _hi)
	else:
		if ok:
			_lo = fit
		else:
			_hi = fit
			if fit <= MIN_SCALE:
				_finish(MIN_SCALE)
				return
		if _step > STEPS:
			_finish(_lo)
			return
		fit = _lo if _step == 1 and not ok else (_lo + _hi) / 2.0
	_step += 1
	_apply()


func _finish(scale_to: float) -> void:
	fit = scale_to
	if fit <= MIN_SCALE:
		_give()
	fitting = false
	set_process(false)
	modulate.a = 1.0
	_apply()


## The card's controls that may give height (LEAST).
func _givers(c: Control) -> Array:
	return c.find_children("*", "Control", true, false).filter(func(n: Control): return n.has_meta(LEAST) and n.is_visible_in_tree())


## At MIN_SCALE and still too tall: shrinks the givers, each in proportion to what it can
## give, when together they can take the whole overflow. Otherwise the card scrolls.
func _give() -> void:
	var c := _child()
	if c == null:
		return
	var over := c.get_combined_minimum_size().y - _room() / fit
	if over <= 0.5:
		return
	var givers := _givers(c)
	var can := 0.0
	for g: Control in givers:
		can += maxf(0.0, g.custom_minimum_size.y - float(g.get_meta(LEAST)))
	if can < over:
		return
	for g: Control in givers:
		if not g.has_meta(FULL):
			g.set_meta(FULL, g.custom_minimum_size.y)
		var spare := maxf(0.0, g.custom_minimum_size.y - float(g.get_meta(LEAST)))
		g.custom_minimum_size.y -= ceilf(over * spare / can)


func _apply() -> void:
	queue_sort()
	update_minimum_size()


func _get_minimum_size() -> Vector2:
	var c := _child()
	return Vector2(0, c.get_combined_minimum_size().y * fit) if c != null else Vector2.ZERO


func _notification(what: int) -> void:
	if what != NOTIFICATION_SORT_CHILDREN:
		return
	var c := _child()
	if c == null:
		return
	# A container would set the scale back to 1, so the card is placed by hand.
	c.scale = Vector2.ONE * fit
	c.position = Vector2.ZERO
	c.size = Vector2(size.x / fit, c.get_combined_minimum_size().y)
	# The card grew (a result, a hint): find a smaller scale, from this one down.
	if not fitting and not fits() and fit > MIN_SCALE:
		_start.call_deferred(fit)
