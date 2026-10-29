class_name GraphView
extends Control
## Draws a question's parabola with Godot's own drawing: grid, axes with numbers, the
## curve, the points the view gives (dot and coordinates) and, if given, the axis of
## symmetry as a dashed line. Sized for a phone: the plot fills the column's width.
##
## spec is the "graph" Dictionary of a question (quadratic_views.gd graph()). A spec
## with "curves" (Plot.spec(), FAL-418) draws those sampled curves instead of the
## parabola, plus its dashed asymptotes ("hlines", "vlines": {"at", "label"}).

const PAD := 18.0
const DOT := 13.0
const FONT_SIZE := 34

## A pick-the-graph card (spec.card, FAL-420) is half the column wide, so it draws
## thinner, with its dots smaller and its numbers fewer: one labelled grid line in
## each 90 px.
func _card() -> bool:
	return spec.get("card", false)

var spec: Dictionary = {}


func _init() -> void:
	custom_minimum_size = Vector2(0, 760)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_spec(s: Dictionary) -> void:
	spec = s
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


## The plot area in local pixels.
func plot_rect() -> Rect2:
	return Rect2(Vector2(PAD, PAD), size - Vector2(PAD, PAD) * 2)


func to_px(p: Vector2) -> Vector2:
	var r := plot_rect()
	var x0 := float(spec.x0)
	var x1 := float(spec.x1)
	var y0 := float(spec.y0)
	var y1 := float(spec.y1)
	return Vector2(r.position.x + (p.x - x0) / (x1 - x0) * r.size.x, r.position.y + (y1 - p.y) / (y1 - y0) * r.size.y)


## Grid step in units so lines are at least min_px apart: 1, 2, 5, 10, ...
static func step_for(units: float, px: float, min_px: float) -> int:
	for s in [1, 2, 5, 10, 20, 50, 100, 200, 500, 1000, 2000, 5000]:
		if px / units * s >= min_px:
			return s
	return 10000


func _draw() -> void:
	if spec.is_empty():
		return
	var font := get_theme_default_font()
	var r := plot_rect()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.1, 0.14))
	var x0 := int(spec.x0)
	var x1 := int(spec.x1)
	var y0 := int(spec.y0)
	var y1 := int(spec.y1)
	var sx := step_for(x1 - x0, r.size.x, 22.0)
	var sy := step_for(y1 - y0, r.size.y, 22.0)
	var lx := step_for(x1 - x0, r.size.x, 90.0 if _card() else 70.0)
	var ly := step_for(y1 - y0, r.size.y, 90.0 if _card() else 56.0)
	# Grid: every unit (or step) faint, labelled steps brighter.
	for x in range(x0, x1 + 1):
		if x % sx == 0:
			draw_line(to_px(Vector2(x, y0)), to_px(Vector2(x, y1)), UiTheme.GRID_MAJOR if x % lx == 0 else UiTheme.GRID, 2.0)
	for y in range(y0, y1 + 1):
		if y % sy == 0:
			draw_line(to_px(Vector2(x0, y)), to_px(Vector2(x1, y)), UiTheme.GRID_MAJOR if y % ly == 0 else UiTheme.GRID, 2.0)
	# Axes.
	var axis_col := Color(UiTheme.DIM, 0.95)
	if y0 <= 0 and 0 <= y1:
		draw_line(to_px(Vector2(x0, 0)), to_px(Vector2(x1, 0)), axis_col, 4.0)
	if x0 <= 0 and 0 <= x1:
		draw_line(to_px(Vector2(0, y0)), to_px(Vector2(0, y1)), axis_col, 4.0)
	var origin := to_px(Vector2(clampi(0, x0, x1), clampi(0, y0, y1)))
	for x in range(x0 + 1, x1):
		if x % lx == 0 and x != 0:
			var p := to_px(Vector2(x, clampi(0, y0, y1))) + Vector2(0, 30)
			if not _near_point(p):
				_text(font, _n(x), p, UiTheme.DIM, FONT_SIZE - 6, true)
	for y in range(y0 + 1, y1):
		if y % ly == 0 and y != 0:
			var p := to_px(Vector2(clampi(0, x0, x1), y)) + Vector2(-34, 10)
			# A y-axis at the plot's left edge (a model from t = 0) keeps its labels inside.
			if p.x < r.position.x + 30:
				p.x += 68
			if not _near_point(p):
				_text(font, _n(y), p, UiTheme.DIM, FONT_SIZE - 6, true)
	_text(font, "x", Vector2(r.end.x - 14, origin.y - 12), UiTheme.DIM, FONT_SIZE, true)
	_text(font, "y", Vector2(origin.x + 22, r.position.y + 26), UiTheme.DIM, FONT_SIZE, true)
	# Axis of symmetry.
	if spec.get("axis") != null:
		var ax := float(spec.axis)
		var t := float(y0)
		while t < y1:
			draw_line(to_px(Vector2(ax, t)), to_px(Vector2(ax, minf(t + 0.5, y1))), UiTheme.SAND, 4.0)
			t += 1.0
		_text(font, spec.axis_label, to_px(Vector2(ax, y1)) + Vector2(14, 40), UiTheme.SAND, FONT_SIZE, false)
	if spec.has("curves"):
		_draw_curves(font)
	else:
		_draw_parabola()
	# Marked points with their coordinates.
	var dot := DOT * (0.75 if _card() else 1.0)
	for p in spec.points:
		# A point outside the window (a wrong card's endpoint carried off it) isn't drawn.
		if p.x < float(spec.x0) or p.x > float(spec.x1) or p.y < float(spec.y0) or p.y > float(spec.y1):
			continue
		var c := to_px(Vector2(p.x, p.y))
		draw_circle(c, dot, UiTheme.PINK)
		draw_circle(c, dot * 0.45, UiTheme.BG)
		if p.label == "":
			continue
		var w := font.get_string_size(p.label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
		var at := c + Vector2(20, -20)
		if at.x + w > r.end.x:
			at.x = c.x - 20 - w
		if at.y - FONT_SIZE < r.position.y:
			at.y = c.y + FONT_SIZE + 16
		_text(font, p.label, at, UiTheme.TEXT, FONT_SIZE, false, true)
	if spec.get("caption", "") != "":
		_text(font, spec.caption, r.position + Vector2(14, 44), UiTheme.SAND, FONT_SIZE, false, true)


## Sampled curves (each [[x, y], ...]) clipped to the plot, and dashed asymptotes.
func _draw_curves(font: Font) -> void:
	var x0 := float(spec.x0)
	var x1 := float(spec.x1)
	var y0 := float(spec.y0)
	var y1 := float(spec.y1)
	var cols := [UiTheme.TEAL, UiTheme.SAND]
	# A card's curves are one curve in pieces (a curve carried through its asymptote).
	if _card():
		cols = [UiTheme.TEAL]
	var width := 5.0 if _card() else 6.0
	for i in spec.curves.size():
		var seg := PackedVector2Array()
		for p in spec.curves[i]:
			if p[1] >= y0 and p[1] <= y1 and p[0] >= x0 and p[0] <= x1:
				seg.append(to_px(Vector2(p[0], p[1])))
			elif seg.size() > 0:
				if seg.size() > 1:
					draw_polyline(seg, cols[i % cols.size()], width, true)
				seg = PackedVector2Array()
		if seg.size() > 1:
			draw_polyline(seg, cols[i % cols.size()], width, true)
	for hl in spec.get("hlines", []):
		var y := float(hl.at)
		var x := x0
		var dash := (x1 - x0) / 40.0
		while x < x1:
			draw_line(to_px(Vector2(x, y)), to_px(Vector2(minf(x + dash * 0.5, x1), y)), UiTheme.SAND, 4.0)
			x += dash
		if hl.get("label", "") != "":
			_text(font, hl.label, to_px(Vector2(x1, y)) + Vector2(-190, -14), UiTheme.SAND, FONT_SIZE - 4, false, true)
	for vl in spec.get("vlines", []):
		var x := float(vl.at)
		var y := y0
		var dash := (y1 - y0) / 40.0
		while y < y1:
			draw_line(to_px(Vector2(x, y)), to_px(Vector2(x, minf(y + dash * 0.5, y1))), UiTheme.SAND, 4.0)
			y += dash
		if vl.get("label", "") != "":
			_text(font, vl.label, to_px(Vector2(x, y1)) + Vector2(14, 40), UiTheme.SAND, FONT_SIZE - 4, false, true)


func _draw_parabola() -> void:
	var x0 := int(spec.x0)
	var x1 := int(spec.x1)
	var y0 := int(spec.y0)
	var y1 := int(spec.y1)
	var font := get_theme_default_font()
	# The curve, clipped to the plot.
	var a := float(spec.a)
	var h := float(spec.h)
	var k := float(spec.k)
	var seg := PackedVector2Array()
	var n := 240
	for i in n + 1:
		var x := x0 + (x1 - x0) * float(i) / n
		var y := a * (x - h) * (x - h) + k
		if y >= y0 and y <= y1:
			seg.append(to_px(Vector2(x, y)))
		elif seg.size() > 0:
			if seg.size() > 1:
				draw_polyline(seg, UiTheme.TEAL, 6.0, true)
			seg = PackedVector2Array()
	if seg.size() > 1:
		draw_polyline(seg, UiTheme.TEAL, 6.0, true)
	# A straight line y = mx + n (a curve and a line that meet), clipped to the plot.
	if spec.get("line") != null:
		var m := float(spec.line.m)
		var c := float(spec.line.n)
		var ends := PackedVector2Array()
		for i in 241:
			var x := x0 + (x1 - x0) * float(i) / 240
			var y := m * x + c
			if y >= y0 and y <= y1:
				ends.append(to_px(Vector2(x, y)))
		if ends.size() > 1:
			draw_line(ends[0], ends[ends.size() - 1], UiTheme.SAND, 5.0, true)
		if spec.line.get("label", "") != "" and ends.size() > 1:
			_text(font, spec.line.label, ends[ends.size() - 1] + Vector2(-150, -18), UiTheme.SAND, FONT_SIZE - 4, false, true)


func _text(font: Font, s: String, at: Vector2, col: Color, fs: int, centred: bool, backed: bool = false) -> void:
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var pos := at - Vector2(w / 2.0, 0) if centred else at
	if backed:
		draw_rect(Rect2(pos + Vector2(-6, -fs + 2), Vector2(w + 12, fs + 10)), Color(0.08, 0.1, 0.14, 0.85))
	draw_string(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


## Whether a tick label at p would sit on a marked point or its curve label.
func _near_point(p: Vector2) -> bool:
	for m in spec.points:
		if to_px(Vector2(m.x, m.y)).distance_to(p) < 44.0:
			return true
	return false


static func _n(v: int) -> String:
	return ("−" if v < 0 else "") + str(absi(v))
