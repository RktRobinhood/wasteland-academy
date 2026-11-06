class_name PlotView
extends Control
## Draws the graphs of the Quadratics extension types (FAL-459) that are not a
## parabola: a question's "graph" with a "kind" (GraphView draws the rest).
##
##   numberline  {"x0", "x1", "marks": [{"at", "open"}], "segment": {"from", "to"}}:
##               a number line with a thick segment (null at an end runs off as an
##               arrow) and open or closed circles
##   normal      {"mu", "sigma", "x0", "x1", "shade": [[from, to]], "marks": [{"at", "label"}]}:
##               a normal curve with its areas shaded (null is an open end); with "curves":
##               [{"mu", "sigma", "label"}], those curves on one pair of axes, each lettered at its
##               peak, instead of the one (FAL-740)
##   trig        {"fn": "sin" or "cos", "line", "points": [{"x", "y", "label"}]}: y = sin x
##               or cos x on [0, 2π] with π ticks, a level line and marked points
##   bars        {"xs", "ys", "hide": [index]}: one bar per x, its value on top (a row
##               of Pascal's triangle); hidden values show "?"
##   venn        {"names": [A, B], "a", "i", "b", "o"}: two circles in a box, with the text of
##               each region: A only, both, B only and outside
##   tree        {"first": [A, A′], "second": [B, B′], "p": [2 labels], "q": [[2 labels], [2 labels]]}:
##               a two-stage tree with the probability on every branch; with "heads": [2 stage
##               names], any 2 or 3 branches at a fork, and a label may be a letter for a missing branch
##   cumfreq     {"x1", "dx", "y1", "dy", "curve": [[x, y], ...], "x_name", "y_name"}: a cumulative
##               frequency curve on a grid of dx by dy squares, with every fifth line bold and labelled
##   sector      {"theta", "shade": "minor" or "major", "names": [O, A, B], "r_label", "angle_label",
##               "arc_label", "circle", "inner", "inner_label", "cone"}: a sector drawn to its real
##               angle, shaded; `circle` draws the rest of the circle, `inner` (a share of the
##               radius) makes it a curved strip of angle theta, and `cone` draws the cone it rolls up into
##   plate       {"w", "h", "rho", "theta", "w_label", "h_label", "rho_label", "angle_label"}: a
##               rectangle with a segment of a circle cut from each of two opposite edges
##   region      {"shape", ...}: a region built from a sector, a triangle, a rectangle and a
##               circle, shaded, drawn by RegionPlot (see ui/region_plot.gd)
##   spinners    {"items": [{"name", "shape", "labels", "shares"}]}: dice laid out flat and spinners
##               side by side, drawn by SpinnerPlot (see ui/spinner_plot.gd)
##   sketch      {"pts": {name: [x, y]}, "lines": [{"a", "b", "label", "dash"}],
##               "arcs": [{"at", "from", "to", "label"}], "north": [names], "right": [names], "note",
##               "circles": [{"at", "through"}]}:
##               points kept to their real shape (a name starting _ isn't written), with a north
##               line at each name in `north`; an arc's `from` is "N" (a bearing, clockwise) or a point
##   solid       {"shape", and the measures as text under r, d, h, l, c, big, a, b, t, e, theta}:
##               a sketch of a cone, pyramid, sphere, hemisphere, composite, hollow cylinder,
##               cylinder inside a sphere or flat sector, with only the given measures labelled;
##               also a cylinder, an open cylinder (no lid) and an open bin with a square base
##   bounce      {"peaks": [heights, each a share of the first], "h_label"}: a ball's height against
##               time, a parabola for each rebound, with the drop marked
##   squares     {"style": "shaded", "cut", "shaded", "area"}: a square cut into cut × cut, with
##               `shaded` of them shaded and the rest repeated in the top right corner, or
##               {"style": "nested", "t", "side"}: squares inside squares, each corner t along a side
##   box         {"x0", "x1", "tick", "every", "name", "boxes": [{"name", "min", "q1", "med", "q3", "max",
##               "out": [outliers, drawn as crosses]}]}: box plots to scale on one axis, a tick at every
##               `tick` and a number at every `every`-th. With "scale": false, one box with its
##               "labels" (five texts) under the five points and no axis: a sketch, not to scale
##   space       {"dim": 2 or 3, "axes", "pts": {name: coordinates}, "labels": {name: text}, "lines": [{"a", "b",
##               "dash", "asked"}], "ball": {"at", "through", "shape"}}: points on x, y and z axes, seen from
##               above as on an exam paper, or x and y flat (a name starting _ isn't drawn or written);
##               `asked` is the segment the question is about, and `ball` draws a sphere, hemisphere or
##               circle round `at` (FAL-751)

const PAD := 26.0
const FONT_SIZE := 32
const DOT := 13.0
const LABEL_GAP := 90.0
const TREE_TOP := 64.0
const TREE_LEAF := 84.0
const BOX_ROW := 150.0

var spec: Dictionary = {}


func _init() -> void:
	custom_minimum_size = Vector2(0, 520)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_spec(s: Dictionary) -> void:
	spec = s
	custom_minimum_size = Vector2(0, {"numberline": 260, "venn": 500, "tree": 620, "cumfreq": 900, "sketch": 660, "unit-circle": 640, "straight-angle": 420, "solid": 640, "bounce": 520, "squares": 660, "space": 640}.get(s.get("kind"), 560))
	if s.get("kind") == "box":
		custom_minimum_size.y = (BOX_ROW * s.boxes.size() + 170.0) if s.get("scale", true) else 300.0
	if s.get("kind") == "tree" and s.has("heads"):
		custom_minimum_size.y = maxf(620.0, TREE_TOP + 26.0 + s.first.size() * s.second.size() * TREE_LEAF)
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


func _draw() -> void:
	if spec.is_empty():
		return
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.1, 0.14))
	match spec.get("kind", ""):
		"numberline":
			_numberline()
		"normal":
			_normal()
		"trig":
			_trig()
		"bars":
			_bars()
		"venn":
			_venn()
		"tree":
			if spec.has("heads"):
				_tree_stages()
			else:
				_tree()
		"cumfreq":
			_cumfreq()
		"sector":
			_sector()
		"plate":
			_plate()
		"region":
			RegionPlot.draw(self)
		"spinners":
			SpinnerPlot.draw(self)
		"sketch":
			_sketch()
		"solid":
			_solid()
		"unit-circle":
			_unit_circle()
		"straight-angle":
			_straight_angle()
		"bounce":
			_bounce()
		"squares":
			_squares()
		"box":
			_box_plots()
		"space":
			_space()


## The screen direction of one unit along each axis of a `space` figure.
func _space_units() -> Array:
	return [Vector2(-0.62, 0.42), Vector2(1.0, 0.06), Vector2(0.0, -1.0)] if spec.dim == 3 else [Vector2(1, 0), Vector2(0, -1)]


func _space() -> void:
	var units := _space_units()
	var flat := func(p: Array) -> Vector2:
		var out := Vector2.ZERO
		for i in units.size():
			out += units[i] * float(p[i])
		return out
	# The axes run a little past the points on each side of the origin.
	var ends: Array = []
	var marks: Array = []
	for i in units.size():
		var lo := 0.0
		var hi := 0.0
		for n in spec.pts:
			lo = minf(lo, spec.pts[n][i])
			hi = maxf(hi, spec.pts[n][i])
		var pad := maxf(hi - lo, 1.0) * 0.14
		ends.append([units[i] * (lo - (pad if lo < 0.0 else 0.0)), units[i] * (hi + pad)])
	var spots: Array = spec.pts.values().map(func(p): return flat.call(p))
	if spec.get("ball") != null:
		var r: float = (flat.call(spec.pts[spec.ball.through]) as Vector2).distance_to(flat.call(spec.pts[spec.ball.at]))
		var c: Vector2 = flat.call(spec.pts[spec.ball.at])
		spots.append_array([c + Vector2(r, r), c - Vector2(r, r)])
	if spec.axes:
		for e in ends:
			spots.append_array(e)
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in spots:
		lo = lo.min(p)
		hi = hi.max(p)
	var box := Rect2(Vector2(70, 56), size - Vector2(140, 112))
	var span := (hi - lo).max(Vector2(0.01, 0.01))
	var k := minf(box.size.x / span.x, box.size.y / span.y)
	var place := func(v: Vector2) -> Vector2:
		return box.position + (box.size - span * k) / 2.0 + (v - lo) * k
	var at := {}
	var mid := Vector2.ZERO
	for n in spec.pts:
		at[n] = place.call(flat.call(spec.pts[n]))
		mid += at[n]
	mid /= spec.pts.size()
	var taken: Array = []
	if spec.axes:
		var origin: Vector2 = place.call(Vector2.ZERO)
		for i in units.size():
			var tip: Vector2 = place.call(ends[i][1])
			draw_line(place.call(ends[i][0]), tip, UiTheme.DIM, 3.0, true)
			var dir := (tip - origin).normalized()
			draw_colored_polygon(PackedVector2Array([tip + dir * 4.0, tip - dir * 16.0 + dir.orthogonal() * 7.0, tip - dir * 16.0 - dir.orthogonal() * 7.0]), UiTheme.DIM)
			var name_at: Vector2 = tip + dir * 26.0 + Vector2(0, 10) + dir.orthogonal() * 16.0
			_chip(["x", "y", "z"][i], name_at, UiTheme.DIM, FONT_SIZE - 4)
			taken.append(_label_box("x", name_at, FONT_SIZE - 4))
		if not spec.labels.has("O") and not spec.pts.has("O"):
			marks.append(["O", origin])
	if spec.get("ball") != null:
		_space_ball(at[spec.ball.at], at[spec.ball.at].distance_to(at[spec.ball.through]))
	for ln in spec.lines:
		if ln.dash:
			_dashes(at[ln.a], at[ln.b], UiTheme.DIM, 3.0)
		else:
			draw_line(at[ln.a], at[ln.b], UiTheme.PINK if ln.asked else UiTheme.TEAL, 6.0 if ln.asked else 4.0, true)
	for m in marks:
		var spot: Vector2 = m[1] + Vector2(-20, 34)
		_chip(m[0], spot, UiTheme.DIM, FONT_SIZE - 4)
		taken.append(_label_box(m[0], spot, FONT_SIZE - 4))
	for n in spec.pts:
		if not String(n).begins_with("_"):
			draw_circle(at[n], DOT * 0.55, UiTheme.TEXT)
	for n in spec.labels:
		var s: String = spec.labels[n]
		if s == "":
			continue
		var p: Vector2 = at[n]
		var away := (p - mid).normalized() if p.distance_to(mid) > 1.0 else Vector2(0, -1)
		var w := get_theme_default_font().get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE - 2).x
		var tries: Array = []
		for dir in [away, Vector2(0, -1), Vector2(0, 1), Vector2(1, 0), Vector2(-1, 0)]:
			tries.append(p + Vector2(dir.x * (w / 2.0 + 24.0), dir.y * 40.0 + 12.0))
		var spot := _clear_spot(tries, s, FONT_SIZE - 2, at, taken)
		_chip(s, spot, UiTheme.TEXT, FONT_SIZE - 2)
		taken.append(_label_box(s, spot, FONT_SIZE - 2))


## A sphere with its equator, a hemisphere with its flat face up, or a plain circle.
func _space_ball(c: Vector2, r: float) -> void:
	match spec.ball.shape:
		"sphere":
			draw_arc(c, r, 0.0, TAU, 96, UiTheme.SAND, 4.0, true)
			_rim(c, r, r * 0.28, 0.0, PI, UiTheme.DIM)
			_rim(c, r, r * 0.28, PI, TAU, UiTheme.DIM, true)
		"hemisphere":
			draw_arc(c, r, 0.0, PI, 64, UiTheme.SAND, 4.0, true)
			_rim(c, r, r * 0.28, 0.0, TAU, UiTheme.SAND)
		_:
			draw_arc(c, r, 0.0, TAU, 96, UiTheme.SAND, 4.0, true)


func _text(s: String, at: Vector2, col: Color, fs: int = FONT_SIZE, centred: bool = true) -> void:
	var font := get_theme_default_font()
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(font, at - Vector2(w / 2.0 if centred else 0.0, 0), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


static func _n(v: float) -> String:
	var r := roundi(v)
	if absf(v - r) < 1e-9:
		return ("−" if r < 0 else "") + str(absi(r))
	return ("−" if v < 0 else "") + str(snappedf(absf(v), 0.01))


# ── Number line ──────────────────────────────────────────────

func _numberline() -> void:
	var x0 := float(spec.x0)
	var x1 := float(spec.x1)
	var y := size.y * 0.45
	var left := PAD + 20.0
	var right := size.x - PAD - 20.0
	var px := func(v: float) -> float: return left + (v - x0) / (x1 - x0) * (right - left)
	draw_line(Vector2(PAD, y), Vector2(size.x - PAD, y), UiTheme.DIM, 4.0)
	for v in range(int(ceil(x0)), int(floor(x1)) + 1):
		var p: float = px.call(float(v))
		draw_line(Vector2(p, y - 14), Vector2(p, y + 14), UiTheme.DIM, 3.0)
		_text(_n(v), Vector2(p, y + 58), UiTheme.DIM, FONT_SIZE - 4)
	var seg: Dictionary = spec.get("segment", {})
	var a: float = px.call(float(seg.from)) if seg.get("from") != null else PAD
	var b: float = px.call(float(seg.to)) if seg.get("to") != null else size.x - PAD
	draw_line(Vector2(a, y - 30), Vector2(b, y - 30), UiTheme.TEAL, 10.0)
	if seg.get("from") == null:
		draw_colored_polygon(PackedVector2Array([Vector2(PAD - 6, y - 30), Vector2(PAD + 22, y - 46), Vector2(PAD + 22, y - 14)]), UiTheme.TEAL)
	if seg.get("to") == null:
		var e := size.x - PAD
		draw_colored_polygon(PackedVector2Array([Vector2(e + 6, y - 30), Vector2(e - 22, y - 46), Vector2(e - 22, y - 14)]), UiTheme.TEAL)
	for m in spec.get("marks", []):
		var c := Vector2(px.call(float(m.at)), y - 30)
		draw_circle(c, DOT + 4, UiTheme.TEAL)
		draw_circle(c, DOT - 1, UiTheme.BG if m.open else UiTheme.TEAL)


# ── Normal curve ─────────────────────────────────────────────

func _normal() -> void:
	var mu := float(spec.mu)
	var sigma := float(spec.sigma)
	var x0 := float(spec.x0)
	var x1 := float(spec.x1)
	var top := 1.0 / (sigma * sqrt(TAU))
	for c in spec.get("curves", []):
		top = maxf(top, 1.0 / (float(c.sigma) * sqrt(TAU)))
	var r := Rect2(Vector2(PAD, PAD + 20), size - Vector2(PAD * 2, PAD * 2 + 110))
	var to_px := func(x: float, yv: float) -> Vector2:
		return Vector2(r.position.x + (x - x0) / (x1 - x0) * r.size.x, r.end.y - yv / (top * 1.1) * r.size.y)
	var pdf := func(x: float) -> float: return top * exp(-0.5 * pow((x - mu) / sigma, 2))
	for sh in spec.get("shade", []):
		var a := float(sh[0]) if sh[0] != null else x0
		var b := float(sh[1]) if sh[1] != null else x1
		var poly := PackedVector2Array([to_px.call(a, 0.0)])
		for i in 81:
			var x := a + (b - a) * i / 80.0
			poly.append(to_px.call(x, pdf.call(x)))
		poly.append(to_px.call(b, 0.0))
		draw_colored_polygon(poly, Color(UiTheme.SAND, 0.45))
	var many: Array = spec.get("curves", [])
	var cols := [UiTheme.TEAL, UiTheme.SAND, UiTheme.PINK, UiTheme.TEXT]
	if many.is_empty():
		many = [{"mu": mu, "sigma": sigma, "label": ""}]
	var dash := r.size.y / 24.0
	var centres := {}
	for c in many:
		centres[float(c.mu)] = true
	for m in centres:
		var mx: Vector2 = to_px.call(m, 0.0)
		var t := 0.0
		while t < r.size.y:
			draw_line(mx - Vector2(0, t), mx - Vector2(0, minf(t + dash * 0.5, r.size.y)), UiTheme.DIM, 3.0)
			t += dash
	for j in many.size():
		var cm := float(many[j].mu)
		var cs := float(many[j].sigma)
		var height := 1.0 / (cs * sqrt(TAU))
		var line := PackedVector2Array()
		for i in 241:
			var x := x0 + (x1 - x0) * i / 240.0
			line.append(to_px.call(x, height * exp(-0.5 * pow((x - cm) / cs, 2))))
		draw_polyline(line, cols[j % cols.size()], 6.0, true)
		if many[j].label != "":
			_text(many[j].label, to_px.call(cm, height) + Vector2(30, -8), cols[j % cols.size()], FONT_SIZE)
	draw_line(to_px.call(x0, 0.0), to_px.call(x1, 0.0), UiTheme.DIM, 4.0)
	# Two values close together: the second label drops a row, so they don't run into each other.
	var placed: Array = []
	for m in spec.get("marks", []):
		var p: Vector2 = to_px.call(float(m.at), 0.0)
		var drop := 34.0 if placed.any(func(x): return absf(x - p.x) < LABEL_GAP) else 0.0
		placed.append(p.x)
		draw_line(p, p + Vector2(0, 16), UiTheme.TEXT, 3.0)
		_text(m.label, p + Vector2(0, 54 + drop), UiTheme.TEXT, FONT_SIZE - 4)


# ── sin x or cos x ───────────────────────────────────────────

func _trig() -> void:
	var r := Rect2(Vector2(PAD + 40, PAD + 10), size - Vector2(PAD * 2 + 50, PAD * 2 + 70))
	var to_px := func(x: float, yv: float) -> Vector2:
		return Vector2(r.position.x + x / TAU * r.size.x, r.position.y + (1.25 - yv) / 2.5 * r.size.y)
	for k in 13:
		var x := k * PI / 6.0
		var major := k % 3 == 0
		draw_line(to_px.call(x, -1.2), to_px.call(x, 1.2), UiTheme.GRID_MAJOR if major else UiTheme.GRID, 2.0)
	for yv in [-1.0, -0.5, 0.5, 1.0]:
		draw_line(to_px.call(0.0, yv), to_px.call(TAU, yv), UiTheme.GRID, 2.0)
	draw_line(to_px.call(0.0, 0.0), to_px.call(TAU, 0.0), UiTheme.DIM, 4.0)
	draw_line(to_px.call(0.0, -1.2), to_px.call(0.0, 1.2), UiTheme.DIM, 4.0)
	for lab in [[PI / 2, "π/2"], [PI, "π"], [1.5 * PI, "3π/2"], [TAU, "2π"]]:
		_text(lab[1], to_px.call(lab[0], 0.0) + Vector2(0, 40), UiTheme.DIM, FONT_SIZE - 6)
	_text("1", to_px.call(0.0, 1.0) + Vector2(-26, 10), UiTheme.DIM, FONT_SIZE - 6)
	_text("−1", to_px.call(0.0, -1.0) + Vector2(-30, 10), UiTheme.DIM, FONT_SIZE - 6)
	if spec.get("line") != null:
		var lv := float(spec.line)
		var x := 0.0
		while x < TAU:
			draw_line(to_px.call(x, lv), to_px.call(minf(x + 0.12, TAU), lv), UiTheme.SAND, 4.0)
			x += 0.24
	var curve := PackedVector2Array()
	for i in 241:
		var x := TAU * i / 240.0
		curve.append(to_px.call(x, sin(x) if spec.fn == "sin" else cos(x)))
	draw_polyline(curve, UiTheme.TEAL, 6.0, true)
	for p in spec.get("points", []):
		var c: Vector2 = to_px.call(float(p.x), float(p.y))
		draw_circle(c, DOT, UiTheme.PINK)
		draw_circle(c, DOT * 0.45, UiTheme.BG)
		_text(p.label, c + Vector2(0, -24 if float(p.y) >= 0.0 else 50), UiTheme.TEXT, FONT_SIZE - 4)


# ── Unit circle (FAL-727) ────────────────────────────────────

## x² + y² = 1 with its axes. spec: "points" [{x, y, label}], "angle" (drawn from the positive
## x-axis to the first point, with "angle_label"), "quadrant" (1 to 4, shaded), "level" and
## "level_x" (a dashed line y = level or x = level_x) and "radius" (the line from O to each point).
func _unit_circle() -> void:
	var c := size / 2.0
	var k := minf(size.x, size.y) / 2.0 - 96.0
	var px := func(x: float, y: float) -> Vector2: return c + Vector2(x, -y) * k
	var q: int = spec.get("quadrant", 0)
	if q > 0:
		var poly := PackedVector2Array()
		for p in quadrant_points(q):
			poly.append(px.call(p.x, p.y))
		draw_colored_polygon(poly, Color(UiTheme.TEAL, 0.22))
	draw_line(px.call(-1.25, 0.0), px.call(1.25, 0.0), UiTheme.DIM, 4.0)
	draw_line(px.call(0.0, -1.25), px.call(0.0, 1.25), UiTheme.DIM, 4.0)
	draw_arc(c, k, 0.0, TAU, 128, UiTheme.TEAL, 5.0, true)
	_text("x", px.call(1.25, 0.0) + Vector2(-8, -14), UiTheme.DIM, FONT_SIZE - 6)
	_text("y", px.call(0.0, 1.25) + Vector2(22, 10), UiTheme.DIM, FONT_SIZE - 6)
	var points: Array = spec.get("points", [])
	for lab in [[1.0, 0.0, "1"], [-1.0, 0.0, "−1"], [0.0, 1.0, "1"], [0.0, -1.0, "−1"]]:
		if not points.any(func(p): return Vector2(p.x, p.y).distance_to(Vector2(lab[0], lab[1])) < 0.2):
			_text(lab[2], px.call(lab[0], lab[1]) + Vector2(22 if lab[0] == 0.0 else -18, 34 if lab[0] != 0.0 else -8), UiTheme.DIM, FONT_SIZE - 8)
	if spec.get("level") != null:
		var lv := float(spec.level)
		var x := -1.2
		while x < 1.2:
			draw_line(px.call(x, lv), px.call(minf(x + 0.05, 1.2), lv), UiTheme.SAND, 4.0)
			x += 0.1
	if spec.get("level_x") != null:
		var lx := float(spec.level_x)
		var y := -1.2
		while y < 1.2:
			draw_line(px.call(lx, y), px.call(lx, minf(y + 0.05, 1.2)), UiTheme.SAND, 4.0)
			y += 0.1
	if spec.get("angle") != null and not points.is_empty():
		var th := float(spec.angle)
		var arc := PackedVector2Array()
		for i in 41:
			var a := th * i / 40.0
			arc.append(px.call(0.26 * cos(a), 0.26 * sin(a)))
		draw_polyline(arc, UiTheme.SAND, 4.0, true)
		var mid := th / 2.0
		_text(spec.get("angle_label", ""), px.call(0.44 * cos(mid), 0.44 * sin(mid)) + Vector2(0, 12), UiTheme.SAND, FONT_SIZE - 4)
	for p in points:
		var at: Vector2 = px.call(float(p.x), float(p.y))
		if spec.get("radius", false):
			draw_line(c, at, UiTheme.PINK, 4.0)
		draw_circle(at, DOT, UiTheme.PINK)
		draw_circle(at, DOT * 0.45, UiTheme.BG)
		var out: Vector2 = (at - c).normalized() * 46.0
		# A point on the x-axis has its letter above the axis, clear of the "x".
		_text(p.label, at + out + (Vector2(0, -32) if absf(float(p.y)) < 0.05 else Vector2(0, 12)), UiTheme.TEXT, FONT_SIZE - 4)


## The corners of quadrant q of the unit circle, with y up: the arc, then the origin.
static func quadrant_points(q: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in 33:
		var a := (q - 1 + i / 32.0) * PI / 2.0
		out.append(Vector2(cos(a), sin(a)))
	out.append(Vector2.ZERO)
	return out


## A straight line through A, with C above it: two angles that add up to π. spec: "theta" (the
## angle at A on the right), "names" [left end, A, right end, C], "right_label", "left_label".
func _straight_angle() -> void:
	var th := float(spec.theta)
	var a := Vector2(size.x / 2.0, size.y - 90.0)
	var run := size.x / 2.0 - 90.0
	var names: Array = spec.names
	var top: Vector2 = a + Vector2(cos(th), -sin(th)) * minf(run, size.y - 170.0)
	draw_line(a - Vector2(run, 0), a + Vector2(run, 0), UiTheme.TEAL, 5.0)
	draw_line(a, top, UiTheme.TEAL, 5.0)
	for i in names.size():
		var at: Vector2 = [a - Vector2(run, 0), a, a + Vector2(run, 0), top][i]
		var off: Vector2 = Vector2(0, -22) if i == 3 else Vector2(0, 46)
		draw_circle(at, DOT * 0.6, UiTheme.PINK)
		_text(names[i], at + off, UiTheme.TEXT)
	var r := 62.0
	var r2 := 92.0
	draw_arc(a, r, -th, 0.0, 32, UiTheme.SAND, 4.0, true)
	draw_arc(a, r2, -PI, -th, 48, UiTheme.PINK, 4.0, true)
	_text(spec.get("right_label", ""), a + Vector2(cos(th / 2.0), -sin(th / 2.0)) * (r + 50.0) + Vector2(0, 10), UiTheme.SAND)
	var mid := (PI + th) / 2.0
	_text(spec.get("left_label", ""), a + Vector2(cos(mid), -sin(mid)) * (r2 + 40.0) + Vector2(0, 10), UiTheme.PINK)


# ── Bars ─────────────────────────────────────────────────────

func _bars() -> void:
	var xs: Array = spec.xs
	var ys: Array = spec.ys
	var hide: Array = spec.get("hide", [])
	var top := 0.0
	for v in ys:
		top = maxf(top, float(v))
	var r := Rect2(Vector2(PAD, PAD + 46), size - Vector2(PAD * 2, PAD * 2 + 100))
	var w := r.size.x / xs.size()
	for i in xs.size():
		var h := float(ys[i]) / top * r.size.y
		var rect := Rect2(Vector2(r.position.x + i * w + w * 0.15, r.end.y - h), Vector2(w * 0.7, h))
		draw_rect(rect, Color(UiTheme.TEAL, 0.35 if i in hide else 0.85))
		_text("?" if i in hide else _n(float(ys[i])), Vector2(rect.get_center().x, rect.position.y - 10), UiTheme.TEXT, FONT_SIZE - 8)
		_text(_n(float(xs[i])), Vector2(rect.get_center().x, r.end.y + 40), UiTheme.DIM, FONT_SIZE - 6)
	draw_line(Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.end.y), UiTheme.DIM, 4.0)


# ── Venn diagram ─────────────────────────────────────────────

func _venn() -> void:
	var box := Rect2(Vector2(PAD, PAD), size - Vector2(PAD, PAD) * 2.0)
	draw_rect(box, UiTheme.DIM, false, 4.0)
	var mid := box.position + box.size / 2.0
	var r := minf(box.size.x * 0.27, box.size.y * 0.4)
	var left := mid - Vector2(r * 0.62, 0)
	var right := mid + Vector2(r * 0.62, 0)
	draw_circle(left, r, Color(UiTheme.TEAL, 0.14))
	draw_circle(right, r, Color(UiTheme.SAND, 0.14))
	draw_arc(left, r, 0.0, TAU, 96, UiTheme.TEAL, 5.0, true)
	draw_arc(right, r, 0.0, TAU, 96, UiTheme.SAND, 5.0, true)
	var names: Array = spec.get("names", ["A", "B"])
	_text(names[0], left + Vector2(-r * 0.72, -r * 0.82), UiTheme.TEAL)
	_text(names[1], right + Vector2(r * 0.72, -r * 0.82), UiTheme.SAND)
	var base := Vector2(0, FONT_SIZE * 0.35)
	_text(spec.a, left + Vector2(-r * 0.42, 0) + base, UiTheme.TEXT, FONT_SIZE - 2)
	_text(spec.i, mid + base, UiTheme.TEXT, FONT_SIZE - 2)
	_text(spec.b, right + Vector2(r * 0.42, 0) + base, UiTheme.TEXT, FONT_SIZE - 2)
	_text(spec.o, box.end - Vector2(96, 26), UiTheme.TEXT, FONT_SIZE - 2)


# ── Tree diagram ─────────────────────────────────────────────

func _tree() -> void:
	var w := size.x
	var h := size.y
	var root := Vector2(PAD + 10, h / 2.0)
	var mids: Array = [Vector2(w * 0.42, h * 0.26), Vector2(w * 0.42, h * 0.74)]
	var ends: Array = [[Vector2(w * 0.86, h * 0.1), Vector2(w * 0.86, h * 0.38)], [Vector2(w * 0.86, h * 0.62), Vector2(w * 0.86, h * 0.9)]]
	var first: Array = spec.first
	var second: Array = spec.second
	for i in 2:
		var m: Vector2 = mids[i]
		draw_line(root, m - Vector2(30, 0), UiTheme.TEAL, 4.0, true)
		var lift := -30.0 if i == 0 else 42.0
		_text(spec.p[i], (root + m) / 2.0 + Vector2(-16, lift), UiTheme.SAND, FONT_SIZE - 2)
		_text(first[i], m + Vector2(0, 12), UiTheme.TEXT)
		for j in 2:
			var e: Vector2 = ends[i][j]
			draw_line(m + Vector2(30, 0), e - Vector2(30, 0), UiTheme.TEAL, 4.0, true)
			var up := -28.0 if j == 0 else 40.0
			_text(spec.q[i][j], (m + e) / 2.0 + Vector2(-10, up), UiTheme.SAND, FONT_SIZE - 2)
			_text(second[j], e + Vector2(10, 12), UiTheme.TEXT)


## A tree with named stages and 2 or 3 branches at a fork, its leaves evenly spaced, and each
## probability on a patch on its branch. A branch's letter (x, y, ?) stands out from the numbers.
func _tree_stages() -> void:
	var first: Array = spec.first
	var second: Array = spec.second
	var font := get_theme_default_font()
	var half := func(t: String) -> float: return font.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE - 2).x / 2.0
	var step := (size.y - TREE_TOP - 16.0) / (first.size() * second.size())
	var mid_x := size.x * 0.42
	var end_x := size.x * 0.74
	var root := Vector2(PAD, 0)
	var ys: Array = []
	for i in first.size():
		ys.append(TREE_TOP + step * second.size() * (i + 0.5))
	root.y = (ys[0] + ys[-1]) / 2.0
	_text(spec.heads[0], Vector2(mid_x * 0.72, 40), UiTheme.DIM, FONT_SIZE - 6)
	_text(spec.heads[1], Vector2(size.x * 0.76, 40), UiTheme.DIM, FONT_SIZE - 6)
	for i in first.size():
		var m := Vector2(mid_x, ys[i])
		var gap: float = half.call(first[i]) + 8.0
		draw_line(root, m - Vector2(gap, 0), UiTheme.TEAL, 4.0, true)
		_tree_label(spec.p[i], root.lerp(m - Vector2(gap, 0), 0.6))
		_text(first[i], m + Vector2(0, 11), UiTheme.TEXT, FONT_SIZE - 2)
		for j in second.size():
			var e := Vector2(end_x, TREE_TOP + step * (i * second.size() + j + 0.5))
			draw_line(m + Vector2(gap, 0), e, UiTheme.TEAL, 4.0, true)
			_tree_label(spec.q[i][j], (m + Vector2(gap, 0)).lerp(e, 0.62))
			_text(second[j], e + Vector2(10, 11), UiTheme.TEXT, FONT_SIZE - 2, false)


func _tree_label(s: String, at: Vector2) -> void:
	var letter := s.is_valid_identifier() or s == "?"
	_chip(s, at + Vector2(0, 11), UiTheme.TEXT if letter else UiTheme.SAND, FONT_SIZE + 4 if letter else FONT_SIZE - 2)


# ── Cumulative frequency curve ───────────────────────────────

func _cumfreq() -> void:
	var x1 := float(spec.x1)
	var y1 := float(spec.y1)
	var dx := float(spec.dx)
	var dy := float(spec.dy)
	var r := Rect2(Vector2(PAD + 96, PAD + 10), size - Vector2(PAD * 2 + 138, PAD + 116))
	var to_px := func(x: float, yv: float) -> Vector2:
		return Vector2(r.position.x + x / x1 * r.size.x, r.end.y - yv / y1 * r.size.y)
	# The squares are read, so they are drawn stronger than a grid that is only a backdrop.
	var fine := Color(1, 1, 1, 0.17)
	var bold := Color(1, 1, 1, 0.42)
	var across := roundi(x1 / dx)
	var up := roundi(y1 / dy)
	for k in across + 1:
		draw_line(to_px.call(k * dx, 0.0), to_px.call(k * dx, y1), bold if k % 5 == 0 else fine, 2.0)
		if k % 5 == 0 and k > 0:
			_text(_n(k * dx), to_px.call(k * dx, 0.0) + Vector2(0, 42), UiTheme.DIM, FONT_SIZE - 6)
	for k in up + 1:
		draw_line(to_px.call(0.0, k * dy), to_px.call(x1, k * dy), bold if k % 5 == 0 else fine, 2.0)
		if k % 5 == 0 and k > 0:
			var label := _n(k * dy)
			var w := get_theme_default_font().get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE - 6).x
			_text(label, to_px.call(0.0, k * dy) + Vector2(-w - 10, 9), UiTheme.DIM, FONT_SIZE - 6, false)
	_text("0", to_px.call(0.0, 0.0) + Vector2(-20, 34), UiTheme.DIM, FONT_SIZE - 6)
	draw_line(to_px.call(0.0, 0.0), to_px.call(x1, 0.0), UiTheme.DIM, 4.0)
	draw_line(to_px.call(0.0, 0.0), to_px.call(0.0, y1), UiTheme.DIM, 4.0)
	var line := PackedVector2Array()
	for p in spec.curve:
		line.append(to_px.call(float(p[0]), float(p[1])))
	draw_polyline(line, UiTheme.TEAL, 5.0, true)
	_text(spec.x_name, Vector2(r.get_center().x, size.y - 12), UiTheme.TEXT, FONT_SIZE - 4)
	draw_set_transform(Vector2(PAD + 8, r.get_center().y), -PI / 2.0)
	_text(spec.y_name, Vector2.ZERO, UiTheme.TEXT, FONT_SIZE - 4)
	draw_set_transform(Vector2.ZERO)
# ── Sector ───────────────────────────────────────────────────

## A label on a dark patch, so it reads over a line or a shaded area.
func _chip(s: String, at: Vector2, col: Color, fs: int = FONT_SIZE) -> void:
	if s == "":
		return
	var font := get_theme_default_font()
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var x := clampf(at.x, w / 2.0 + 8.0, size.x - w / 2.0 - 8.0)
	draw_rect(Rect2(Vector2(x - w / 2.0 - 5.0, at.y - fs * 0.8), Vector2(w + 10.0, fs * 1.1)), Color(0.08, 0.1, 0.14, 0.85))
	draw_string(font, Vector2(x - w / 2.0, at.y + fs * 0.1), s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)


func _on_circle(c: Vector2, r: float, a: float) -> Vector2:
	return c + Vector2(cos(a), -sin(a)) * r


func _arc_points(c: Vector2, r: float, a0: float, sweep: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := maxi(8, ceili(absf(sweep) * 24.0))
	for i in n + 1:
		out.append(_on_circle(c, r, a0 + sweep * i / n))
	return out


func _fan(c: Vector2, r0: float, r1: float, a0: float, sweep: float, col: Color) -> void:
	var outer := _arc_points(c, r1, a0, sweep)
	var inner := _arc_points(c, r0, a0, sweep)
	for i in outer.size() - 1:
		if r0 <= 0.0:
			draw_colored_polygon(PackedVector2Array([c, outer[i], outer[i + 1]]), col)
		else:
			draw_colored_polygon(PackedVector2Array([inner[i], outer[i], outer[i + 1], inner[i + 1]]), col)


func _dashes(p: Vector2, q: Vector2, col: Color, w: float = 3.0) -> void:
	draw_dashed_line(p, q, col, w, 14.0, true, true)


func _sector() -> void:
	var th: float = spec.theta
	var major: bool = spec.shade == "major"
	var ring: float = spec.get("inner", 0.0)
	var circle: bool = spec.get("circle", false)
	var cone: bool = spec.get("cone", false)
	var box := Rect2(Vector2(70, 56), Vector2(size.x * (0.62 if cone else 1.0) - 140, size.y - 112))
	# a0 and sweep: the shaded part. l0 and ls: the angle that is labelled.
	var a0 := 0.0
	var sweep := th
	if ring > 0.0:
		a0 = PI - th / 2.0
	elif major:
		a0 = th / 2.0
		sweep = TAU - th
	elif th > PI:
		a0 = PI / 2.0 - th / 2.0
	var l0 := -th / 2.0 if major and ring == 0.0 else a0
	# The shape's box on a unit circle, then scaled to fit.
	var pts := _arc_points(Vector2.ZERO, 1.0, 0.0, TAU) if circle else _arc_points(Vector2.ZERO, 1.0, a0, sweep)
	pts.append(Vector2.ZERO)
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for p in pts:
		lo = lo.min(p)
		hi = hi.max(p)
	var span := (hi - lo).max(Vector2(0.2, 0.2))
	var k := minf(box.size.x / span.x, box.size.y / span.y)
	var c := box.position + (box.size - span * k) / 2.0 - lo * k
	if circle:
		draw_arc(c, k, 0.0, TAU, 96, UiTheme.DIM if ring > 0.0 else UiTheme.TEAL, 3.0, true)
	_fan(c, ring * k, k, a0, sweep, Color(UiTheme.TEAL, 0.32))
	draw_polyline(_arc_points(c, k, a0, sweep), UiTheme.TEAL, 5.0, true)
	var inner_r := ring * k
	var p_a := _on_circle(c, k, a0)
	var p_b := _on_circle(c, k, a0 + sweep)
	if ring > 0.0:
		draw_arc(c, inner_r, 0.0, TAU, 96, UiTheme.DIM, 3.0, true)
		draw_polyline(_arc_points(c, inner_r, a0, sweep), UiTheme.TEAL, 5.0, true)
		draw_line(_on_circle(c, inner_r, a0), p_a, UiTheme.TEAL, 5.0, true)
		draw_line(_on_circle(c, inner_r, a0 + sweep), p_b, UiTheme.TEAL, 5.0, true)
		_dashes(c, _on_circle(c, inner_r, a0), UiTheme.DIM)
		_dashes(c, _on_circle(c, inner_r, a0 + sweep), UiTheme.DIM)
	else:
		draw_line(c, p_a, UiTheme.TEAL, 5.0, true)
		draw_line(c, p_b, UiTheme.TEAL, 5.0, true)
	draw_circle(c, DOT * 0.6, UiTheme.TEXT)
	var mid := l0 + th / 2.0
	var near := minf(46.0, k * 0.2)
	draw_polyline(_arc_points(c, near, l0, th), UiTheme.SAND, 3.0, true)
	var reach := clampf(near + 36.0 / maxf(sin(minf(th, PI) / 2.0), 0.15), near + 34.0, k * 0.62)
	if ring > 0.0:
		reach = minf(reach, inner_r * 0.72)
	_chip(spec.angle_label, _on_circle(c, reach, mid), UiTheme.PINK if spec.angle_label == "θ" else UiTheme.SAND, FONT_SIZE - 2)
	var names: Array = spec.names
	if ring == 0.0:
		_text(names[0], _on_circle(c, 34.0, mid + PI) + Vector2(0, 12), UiTheme.TEXT)
		_text(names[1], _on_circle(c, k + 30.0, a0) + Vector2(0, 12), UiTheme.TEXT)
		_text(names[2], _on_circle(c, k + 30.0, a0 + sweep) + Vector2(0, 12), UiTheme.TEXT)
	# The radius beside OA, on the side away from the labelled angle unless it is shaded there.
	var edge := l0 if major and ring == 0.0 else a0 + sweep
	var along := _on_circle(c, k * 0.62, edge)
	var out_dir := Vector2(cos(edge + PI / 2.0), -sin(edge + PI / 2.0))
	if major and ring == 0.0:
		out_dir = -out_dir
	var r_w := get_theme_default_font().get_string_size(spec.r_label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	var r_gap := 18.0 + absf(out_dir.x) * r_w / 2.0 + absf(out_dir.y) * FONT_SIZE / 2.0
	_chip(spec.r_label, along + out_dir * r_gap + Vector2(0, 10), UiTheme.PINK if spec.r_label == "r" else UiTheme.SAND)
	if ring > 0.0:
		_chip(spec.get("inner_label", ""), _on_circle(c, inner_r * 0.62, a0) - Vector2(0, 26), UiTheme.PINK if spec.get("inner_label", "") == "r" else UiTheme.SAND)
	_chip(spec.arc_label, _on_circle(c, k + 34.0, a0 + sweep / 2.0) + Vector2(0, 10), UiTheme.SAND)
	if cone:
		_cone(Rect2(Vector2(size.x * 0.64, 90), Vector2(size.x * 0.32, size.y - 180)))


## The cone a sector rolls into: its apex, its slant and the rim.
func _cone(box: Rect2) -> void:
	var top := box.position + Vector2(box.size.x / 2.0, 30)
	var base := box.position + Vector2(box.size.x / 2.0, box.size.y - 40)
	var rx := box.size.x * 0.44
	var ry := rx * 0.26
	var rim := PackedVector2Array()
	for i in 49:
		rim.append(base + Vector2(cos(TAU * i / 48.0) * rx, sin(TAU * i / 48.0) * ry))
	draw_polyline(rim, UiTheme.TEAL, 4.0, true)
	draw_line(top, base - Vector2(rx, 0), UiTheme.TEAL, 4.0, true)
	draw_line(top, base + Vector2(rx, 0), UiTheme.TEAL, 4.0, true)
	_text("O", top - Vector2(0, 14), UiTheme.TEXT)
	_text("A, B", base + Vector2(rx - 30, -ry - 22), UiTheme.TEXT, FONT_SIZE - 6)
	_text("rim", base + Vector2(0, ry + 38), UiTheme.PINK, FONT_SIZE - 4)


# ── Plate with two segments cut away ─────────────────────────

func _plate() -> void:
	var w := float(spec.w)
	var h := float(spec.h)
	var rho := float(spec.rho)
	var th: float = spec.theta
	var dist := rho * cos(th / 2.0)
	var box := Rect2(Vector2(46, 76), size - Vector2(150, 150))
	var k := minf(box.size.x / (w + dist), box.size.y / h)
	var left := box.position.x + (box.size.x - (w + dist) * k) / 2.0 + dist * k
	var top := box.position.y + (box.size.y - h * k) / 2.0
	var rect := Rect2(Vector2(left, top), Vector2(w, h) * k)
	draw_rect(rect, Color(UiTheme.TEAL, 0.32))
	draw_rect(rect, UiTheme.TEAL, false, 4.0)
	var dark := Color(0.08, 0.1, 0.14)
	var mid_y := top + h * k / 2.0
	var o_l := Vector2(left - dist * k, mid_y)
	var o_r := Vector2(rect.end.x + dist * k, mid_y)
	for pair in [[o_l, -th / 2.0], [o_r, PI - th / 2.0]]:
		var o: Vector2 = pair[0]
		var cut := _arc_points(o, rho * k, pair[1], th)
		var poly := cut.duplicate()
		if poly.size() >= 3:
			draw_colored_polygon(poly, dark)
		draw_line(cut[0], cut[cut.size() - 1], dark, 7.0)
		draw_polyline(cut, UiTheme.TEAL, 5.0, true)
	var a := _on_circle(o_l, rho * k, th / 2.0)
	var b := _on_circle(o_l, rho * k, -th / 2.0)
	_dashes(o_l, a, UiTheme.SAND)
	_dashes(o_l, b, UiTheme.SAND)
	_dashes(a, b, UiTheme.DIM)
	draw_circle(o_l, DOT * 0.6, UiTheme.TEXT)
	_text("O", o_l + Vector2(-26, 12), UiTheme.TEXT)
	draw_polyline(_arc_points(o_l, 34.0, -th / 2.0, th), UiTheme.SAND, 3.0, true)
	_chip(spec.angle_label, o_l + Vector2(62, 10), UiTheme.PINK, FONT_SIZE - 2)
	_chip(spec.rho_label, (o_l + b) / 2.0 + Vector2(-10, 40), UiTheme.SAND, FONT_SIZE - 2)
	_chip(spec.w_label, Vector2(rect.get_center().x, top - 18), UiTheme.SAND)
	_chip(spec.h_label, Vector2(rect.end.x + 60, top + 34), UiTheme.SAND)


# ── Sketch: points in their real shape ───────────────────────

const NORTH_LEN := 112.0
const SKETCH_ARC := 54.0


func _sketch() -> void:
	var names: Array = spec.pts.keys()
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for n in names:
		var p := Vector2(spec.pts[n][0], spec.pts[n][1])
		lo = lo.min(p)
		hi = hi.max(p)
	var top := 60.0 + (NORTH_LEN if not spec.north.is_empty() else 0.0)
	var box := Rect2(Vector2(92, top), size - Vector2(184, top + 70))
	var span := (hi - lo).max(Vector2(0.01, 0.01))
	var k := minf(box.size.x / span.x, box.size.y / span.y)
	var off := box.position + (box.size - span * k) / 2.0
	var at := {}
	var mid := Vector2.ZERO
	for n in names:
		var p := Vector2(spec.pts[n][0], spec.pts[n][1])
		at[n] = Vector2(off.x + (p.x - lo.x) * k, off.y + (hi.y - p.y) * k)
		mid += at[n]
	mid /= names.size()
	for n in spec.north:
		var p: Vector2 = at[n]
		var tip := p - Vector2(0, NORTH_LEN)
		_dashes(p, tip, UiTheme.DIM)
		draw_colored_polygon(PackedVector2Array([tip - Vector2(0, 10), tip + Vector2(-8, 8), tip + Vector2(8, 8)]), UiTheme.DIM)
		_text("N", tip + Vector2(26, 8), UiTheme.DIM, FONT_SIZE - 6)
	for c in spec.get("circles", []):
		draw_arc(at[c.at], at[c.at].distance_to(at[c.through]), 0.0, TAU, 96, UiTheme.DIM, 3.0, true)
	for ln in spec.lines:
		var p: Vector2 = at[ln.a]
		var q: Vector2 = at[ln.b]
		if ln.dash:
			_dashes(p, q, UiTheme.SAND, 4.0)
		else:
			draw_line(p, q, UiTheme.TEAL, 5.0, true)
	for n in spec.get("right", []):
		_right_mark(n, at)
	# Names first, then angles, then lengths: each label takes a place clear of those before it.
	var taken: Array = []
	for n in spec.north:
		taken.append(_label_box("N", at[n] - Vector2(-26, NORTH_LEN - 8), FONT_SIZE - 6))
	for n in names:
		if String(n).begins_with("_"):
			continue
		var p: Vector2 = at[n]
		draw_circle(p, DOT * 0.55, UiTheme.TEXT)
		var away := (p - mid).normalized()
		if n in spec.north and away.y < 0.0:
			away = Vector2(signf(away.x) if away.x != 0.0 else 1.0, 0.3).normalized()
		var spot := p + away * 36.0 + Vector2(0, 12)
		_chip(n, spot, UiTheme.TEXT)
		taken.append(_label_box(n, spot, FONT_SIZE))
	var used := {}
	for a in spec.arcs:
		_sketch_arc(a, at, used, taken)
	for ln in spec.lines:
		if ln.label == "":
			continue
		var p: Vector2 = at[ln.a]
		var q: Vector2 = at[ln.b]
		var normal := (q - p).orthogonal().normalized()
		if normal.dot((p + q) / 2.0 - mid) < 0.0:
			normal = -normal
		var w := get_theme_default_font().get_string_size(ln.label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE - 2).x
		var gap := 20.0 + absf(normal.x) * w / 2.0 + absf(normal.y) * FONT_SIZE / 2.0
		var tries: Array = []
		for t in [0.5, 0.35, 0.65, 0.22, 0.78]:
			tries.append(p.lerp(q, t) + normal * gap + Vector2(0, 10))
		for t in [0.5, 0.35, 0.65]:
			tries.append(p.lerp(q, t) - normal * gap + Vector2(0, 10))
		var spot := _clear_spot(tries, ln.label, FONT_SIZE - 2, at, taken, ln)
		_chip(ln.label, spot, UiTheme.PINK if ln.label == "?" else UiTheme.SAND, FONT_SIZE - 2)
		taken.append(_label_box(ln.label, spot, FONT_SIZE - 2))
	if spec.has("note"):
		_chip(spec.note, Vector2(size.x - 120, 34), UiTheme.DIM, FONT_SIZE - 8)


## The box a chip takes up at `at`, with a little room around it.
func _label_box(s: String, at: Vector2, fs: int) -> Rect2:
	var w := get_theme_default_font().get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	return Rect2(Vector2(at.x - w / 2.0 - 8.0, at.y - fs * 0.85), Vector2(w + 16.0, fs * 1.2))


## The first of `tries` clear of every label and line but `own`, or else the first.
func _clear_spot(tries: Array, s: String, fs: int, at: Dictionary, taken: Array, own: Variant = null) -> Vector2:
	for spot in tries:
		var box := _label_box(s, spot, fs)
		if box.position.x < 4.0 or box.end.x > size.x - 4.0 or box.position.y < 4.0 or box.end.y > size.y - 4.0:
			continue
		if taken.any(func(r): return r.intersects(box)):
			continue
		var hit := false
		for ln in spec.lines:
			if ln == own:
				continue
			for i in 41:
				if box.has_point(at[ln.a].lerp(at[ln.b], i / 40.0)):
					hit = true
					break
		if not hit:
			return spot
	return tries[0]


## A small square in the corner at point n, between the two lines that meet there.
func _right_mark(n: String, at: Dictionary) -> void:
	var dirs: Array = []
	for ln in spec.lines:
		if ln.a == n:
			dirs.append((at[ln.b] - at[n]).normalized())
		elif ln.b == n:
			dirs.append((at[ln.a] - at[n]).normalized())
	if dirs.size() < 2:
		return
	var p: Vector2 = at[n]
	var u: Vector2 = dirs[0] * 24.0
	var v: Vector2 = dirs[1] * 24.0
	draw_polyline(PackedVector2Array([p + u, p + u + v, p + v]), UiTheme.SAND, 3.0, true)


## An angle at a point: a bearing clockwise from north, or the shorter way between two points.
func _sketch_arc(a: Dictionary, at: Dictionary, used: Dictionary, taken: Array) -> void:
	var p: Vector2 = at[a.at]
	var r: float = SKETCH_ARC + 34.0 * used.get(a.at, 0)
	used[a.at] = used.get(a.at, 0) + 1
	var to: Vector2 = at[a.to] - p
	var a1 := atan2(-to.y, to.x)
	var a0 := PI / 2.0
	var sweep := -fposmod(a0 - a1, TAU)
	if a.from != "N":
		var f: Vector2 = at[a.from] - p
		a0 = atan2(-f.y, f.x)
		sweep = wrapf(a1 - a0, -PI, PI)
	draw_polyline(_arc_points(p, r, a0, sweep), UiTheme.SAND, 3.0, true)
	var half := minf(absf(sweep), PI) / 2.0
	var reach: float = r + 38.0 + 10.0 / maxf(sin(half), 0.12)
	var tries: Array = []
	for pair in [[0.5, 0.0], [0.5, 34.0], [0.35, 0.0], [0.65, 0.0], [0.5, 70.0], [0.25, 20.0], [0.75, 20.0]]:
		tries.append(_on_circle(p, reach + pair[1], a0 + sweep * pair[0]) + Vector2(0, 10))
	var spot := _clear_spot(tries, a.label, FONT_SIZE - 4, at, taken)
	_chip(a.label, spot, UiTheme.PINK if a.label == "?" else UiTheme.SAND, FONT_SIZE - 4)
	taken.append(_label_box(a.label, spot, FONT_SIZE - 4))
# ── Solids ───────────────────────────────────────────────────

## Part of an ellipse from angle a to b, solid or dashed. Angles run clockwise from the right
## on screen, so 0 to PI is the near side of a circle seen from above.
func _rim(c: Vector2, rx: float, ry: float, a: float, b: float, col: Color, dashed: bool = false) -> void:
	var n := 48
	for i in n:
		if dashed and i % 2 == 1:
			continue
		var t0 := a + (b - a) * i / n
		var t1 := a + (b - a) * (i + 1) / n
		draw_line(c + Vector2(cos(t0) * rx, sin(t0) * ry), c + Vector2(cos(t1) * rx, sin(t1) * ry), col, 4.0 if not dashed else 3.0, true)


func _solid_dashes(a: Vector2, b: Vector2, col: Color = UiTheme.DIM) -> void:
	var n := maxi(2, int(a.distance_to(b) / 18.0))
	for i in n:
		if i % 2 == 0:
			draw_line(a.lerp(b, float(i) / n), a.lerp(b, float(i + 1) / n), col, 3.0)


func _edge(a: Vector2, b: Vector2) -> void:
	draw_line(a, b, UiTheme.TEAL, 4.0, true)


## A corner square at c, along the unit directions u and v.
func _square(c: Vector2, u: Vector2, v: Vector2) -> void:
	var s := 20.0
	draw_polyline(PackedVector2Array([c + u * s, c + u * s + v * s, c + v * s]), UiTheme.DIM, 2.0)


## spec[key] at a point: centred, or starting there or ending there (align -1, 0, 1).
func _mark(key: String, at: Vector2, align: int = 0) -> void:
	if not spec.has(key):
		return
	var s: String = spec[key]
	var w := get_theme_default_font().get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE - 4).x
	var x := at.x - w / 2.0 if align == 0 else (at.x if align < 0 else at.x - w)
	var spot := Vector2(clampf(x, 4.0, size.x - w - 4.0), at.y + 10.0)
	# A plate of the background, so a line behind the label doesn't run through it.
	draw_rect(Rect2(spot + Vector2(-4, -FONT_SIZE + 2), Vector2(w + 8, FONT_SIZE + 6)), Color(0.08, 0.1, 0.14))
	_text(s, spot, UiTheme.SAND, FONT_SIZE - 4, false)


## A measuring line from a to b with arrow ends, and spec[key] beside it.
func _measure(key: String, a: Vector2, b: Vector2, at: Vector2, align: int = -1) -> void:
	if not spec.has(key):
		return
	draw_line(a, b, UiTheme.DIM, 3.0)
	var u := (b - a).normalized()
	var n := Vector2(-u.y, u.x)
	for end in [[a, u], [b, -u]]:
		var tip: Vector2 = end[0]
		var dir: Vector2 = end[1]
		draw_colored_polygon(PackedVector2Array([tip, tip + dir * 16 + n * 7, tip + dir * 16 - n * 7]), UiTheme.DIM)
	_mark(key, at, align)


func _solid() -> void:
	var w := size.x
	var h := size.y
	var r := minf(w * 0.3, h * 0.3)
	var mid := Vector2(w * 0.45, h * 0.5)
	match spec.shape:
		"cone":
			_cone_top(Vector2(mid.x, h * 0.74), r * 1.15, h * 0.62, true)
			_rim(Vector2(mid.x, h * 0.74), r * 1.15, r * 0.3, 0.0, PI, UiTheme.TEAL)
			_circle_marks(Vector2(mid.x, h * 0.74), r * 1.15, r * 0.3, true)
		"pyramid":
			_pyramid()
		"sphere":
			draw_arc(mid, r * 1.2, 0.0, TAU, 96, UiTheme.TEAL, 4.0, true)
			_rim(mid, r * 1.2, r * 0.3, 0.0, PI, UiTheme.DIM)
			_rim(mid, r * 1.2, r * 0.3, PI, TAU, UiTheme.DIM, true)
			_circle_marks(mid, r * 1.2, r * 0.3, false)
		"hemisphere":
			var c := Vector2(mid.x, h * 0.68)
			_dome(c, r * 1.3, r * 0.34)
			_rim(c, r * 1.3, r * 0.34, 0.0, PI, UiTheme.TEAL)
			_circle_marks(c, r * 1.3, r * 0.34, false)
		"cone-hemisphere":
			var c := Vector2(mid.x, h * 0.54)
			_cone_top(c, r, h * 0.46, false)
			_rim(c, r, r, 0.0, PI, UiTheme.TEAL)
			_rim(c, r, r * 0.26, 0.0, PI, UiTheme.DIM)
			_circle_marks(c, r, r * 0.26, false)
		"cone-cylinder":
			var c := Vector2(mid.x, h * 0.46)
			_cone_top(c, r, h * 0.38, false)
			_drum(c, r, r * 0.26, h * 0.4, "c")
			_circle_marks(c, r, r * 0.26, false)
		"hemisphere-cylinder":
			var c := Vector2(mid.x, h * 0.42)
			_dome(c, r, r * 0.26)
			_drum(c, r, r * 0.26, h * 0.42, "c")
			_circle_marks(c, r, r * 0.26, false)
		"cylinder-minus-hemisphere":
			_scooped(mid, r * 1.2)
		"capsule":
			_capsule(mid, r * 0.8)
		"hollow":
			_hollow(mid, r)
		"inscribed":
			_inscribed(Vector2(w * 0.56, mid.y), r * 1.3)
		"sector":
			_solid_sector(mid, r * 1.3)
		"cylinder", "open-cylinder":
			_cylinder(mid, r * 1.05, spec.shape == "cylinder")
		"open-bin":
			_open_bin(mid, r * 1.05)


## The slant sides of a cone over a base centred at c, with its back edge dashed. `plain` draws
## the height from the apex and the slant label; a composite does too, but keeps its base.
func _cone_top(c: Vector2, rx: float, tall: float, plain: bool) -> void:
	var top := c - Vector2(0, tall)
	_edge(top, c + Vector2(rx, 0))
	_edge(top, c - Vector2(rx, 0))
	var ry := rx * (0.3 if plain else 0.26)
	_rim(c, rx, ry, PI, TAU, UiTheme.DIM, true)
	if spec.has("h"):
		_solid_dashes(top, c)
		_square(c, Vector2.UP, Vector2.RIGHT)
		_mark("h", c + Vector2(14, -tall * 0.26), -1)
	_mark("l", (top + c + Vector2(rx, 0)) / 2.0 + Vector2(18, -8), -1)


## A dome over a base centred at c, with its flat circle's back edge dashed.
func _dome(c: Vector2, rx: float, ry: float) -> void:
	_rim(c, rx, rx, PI, TAU, UiTheme.TEAL)
	_rim(c, rx, ry, PI, TAU, UiTheme.DIM, true)


## A cylinder hanging below a circle at c, and its height label.
func _drum(c: Vector2, rx: float, ry: float, tall: float, key: String) -> void:
	var low := c + Vector2(0, tall)
	_edge(c + Vector2(rx, 0), low + Vector2(rx, 0))
	_edge(c - Vector2(rx, 0), low - Vector2(rx, 0))
	_rim(c, rx, ry, 0.0, PI, UiTheme.DIM)
	_rim(low, rx, ry, 0.0, PI, UiTheme.TEAL)
	_rim(low, rx, ry, PI, TAU, UiTheme.DIM, true)
	var x := rx + 28.0
	_measure(key, c + Vector2(x, 0), low + Vector2(x, 0), (c + low) / 2.0 + Vector2(x + 12.0, 0))


## The radius or diameter drawn across a circle, with its label. `outside` puts a diameter's
## label below the rim.
func _circle_marks(c: Vector2, rx: float, ry: float, outside: bool) -> void:
	if spec.has("d"):
		_solid_dashes(c - Vector2(rx, 0), c + Vector2(rx, 0), UiTheme.SAND)
		_mark("d", c + Vector2(0, ry + 34.0) if outside else c + Vector2(0, 30.0))
	elif spec.has("r"):
		_solid_dashes(c, c + Vector2(rx, 0), UiTheme.SAND)
		_mark("r", c + Vector2(rx * 0.42, ry + 30.0))


func _pyramid() -> void:
	var w := size.x
	var h := size.y
	var bl := Vector2(w * 0.12, h * 0.78)
	var br := Vector2(w * 0.62, h * 0.86)
	var tr := Vector2(w * 0.84, h * 0.66)
	var tl := bl + tr - br
	var centre := (bl + tr) / 2.0
	var top := Vector2(centre.x, h * 0.06)
	_edge(bl, br)
	_edge(br, tr)
	_edge(top, bl)
	_edge(top, br)
	_edge(top, tr)
	_solid_dashes(bl, tl)
	_solid_dashes(tl, tr)
	_solid_dashes(top, tl)
	_mark("a", (bl + br) / 2.0 + Vector2(-10, 38))
	_mark("b", (br + tr) / 2.0 + Vector2(20, 26), -1)
	if spec.has("h"):
		_solid_dashes(top, centre)
		_square(centre, Vector2.UP, Vector2.LEFT)
		_mark("h", (top + centre) / 2.0 + Vector2(12, 40), -1)
	if spec.has("t"):
		var foot := (bl + br) / 2.0
		_solid_dashes(top, foot, UiTheme.SAND)
		_mark("t", top.lerp(foot, 0.5) + Vector2(-12, 0), 1)
	_mark("e", (top + tr) / 2.0 + Vector2(18, -6), -1)


## A cylinder with a bowl in its top.
func _scooped(c: Vector2, rx: float) -> void:
	var ry := rx * 0.26
	var tall := size.y * 0.56
	var top := c - Vector2(0, tall * 0.5)
	var low := top + Vector2(0, tall)
	_edge(top + Vector2(rx, 0), low + Vector2(rx, 0))
	_edge(top - Vector2(rx, 0), low - Vector2(rx, 0))
	_rim(top, rx, ry, 0.0, TAU, UiTheme.TEAL)
	_rim(low, rx, ry, 0.0, PI, UiTheme.TEAL)
	_rim(low, rx, ry, PI, TAU, UiTheme.DIM, true)
	var inner := rx * 0.62
	_rim(top, inner, inner * 0.26, 0.0, TAU, UiTheme.TEAL)
	_rim(top, inner, inner, 0.0, PI, UiTheme.DIM, true)
	_solid_dashes(top, top + Vector2(inner, 0), UiTheme.SAND)
	_mark("r", top + Vector2(inner * 0.5, -ry - 28.0))
	_solid_dashes(low, low + Vector2(rx, 0), UiTheme.SAND)
	_mark("big", low + Vector2(rx * 0.5, ry + 30.0))
	var x := rx + 28.0
	_measure("c", top + Vector2(x, 0), low + Vector2(x, 0), c + Vector2(x + 12.0, 0))


## A cylinder lying down with a hemisphere on each end.
func _capsule(c: Vector2, rx: float) -> void:
	var len := minf(rx * 1.5, size.x * 0.34)
	var a := c - Vector2(len / 2.0, 0)
	var b := c + Vector2(len / 2.0, 0)
	draw_arc(a, rx, PI * 0.5, PI * 1.5, 48, UiTheme.TEAL, 4.0, true)
	draw_arc(b, rx, -PI * 0.5, PI * 0.5, 48, UiTheme.TEAL, 4.0, true)
	_edge(a - Vector2(0, rx), b - Vector2(0, rx))
	_edge(a + Vector2(0, rx), b + Vector2(0, rx))
	_rim(a, rx * 0.26, rx, -PI * 0.5, PI * 0.5, UiTheme.DIM, true)
	_rim(b, rx * 0.26, rx, PI * 0.5, PI * 1.5, UiTheme.DIM, true)
	_rim(a, rx * 0.26, rx, PI * 0.5, PI * 1.5, UiTheme.DIM)
	_rim(b, rx * 0.26, rx, -PI * 0.5, PI * 0.5, UiTheme.DIM)
	var y := rx + 28.0
	_measure("c", a + Vector2(0, y), b + Vector2(0, y), c + Vector2(0, y + 40.0), 0)
	_solid_dashes(b, b - Vector2(0, rx), UiTheme.SAND)
	_mark("r", b + Vector2(16, -rx * 0.5), -1)


## A cylinder with a smaller one taken out of its centre.
func _hollow(c: Vector2, rx: float) -> void:
	var ry := rx * 0.28
	var tall := size.y * 0.4
	var top := c - Vector2(0, tall * 0.56)
	var low := top + Vector2(0, tall)
	var inner := rx * 0.42
	_edge(top + Vector2(rx, 0), low + Vector2(rx, 0))
	_edge(top - Vector2(rx, 0), low - Vector2(rx, 0))
	_rim(top, rx, ry, 0.0, TAU, UiTheme.TEAL)
	_rim(low, rx, ry, 0.0, PI, UiTheme.TEAL)
	_rim(low, rx, ry, PI, TAU, UiTheme.DIM, true)
	_rim(top, inner, inner * 0.3, 0.0, TAU, UiTheme.TEAL)
	_solid_dashes(top + Vector2(inner, 0), low + Vector2(inner, 0))
	_solid_dashes(top - Vector2(inner, 0), low - Vector2(inner, 0))
	var up := top - Vector2(0, ry + 16.0)
	_measure("r", up, up + Vector2(inner, 0), up + Vector2(inner * 0.5, -32.0), 0)
	draw_line(top, up, UiTheme.DIM, 2.0)
	var under := low + Vector2(0, ry + 22.0)
	_measure("big", under, under + Vector2(rx, 0), under + Vector2(rx * 0.5, 36.0), 0)
	draw_line(low, under, UiTheme.DIM, 2.0)
	var x := rx + 28.0
	_measure("h", top + Vector2(x, 0), low + Vector2(x, 0), c + Vector2(x + 12.0, 0))


## A cylinder, closed or with no lid: an open one shows the back of its rim and its inside.
func _cylinder(c: Vector2, rx: float, closed: bool) -> void:
	var ry := rx * 0.28
	var tall := size.y * 0.46
	var top := c - Vector2(0, tall * 0.5)
	var low := top + Vector2(0, tall)
	_edge(top + Vector2(rx, 0), low + Vector2(rx, 0))
	_edge(top - Vector2(rx, 0), low - Vector2(rx, 0))
	_rim(top, rx, ry, 0.0, TAU, UiTheme.TEAL)
	_rim(low, rx, ry, 0.0, PI, UiTheme.TEAL)
	_rim(low, rx, ry, PI, TAU, UiTheme.DIM, true)
	if not closed:
		_chip("no lid", low + Vector2(0, ry + 44.0), UiTheme.DIM, FONT_SIZE - 8)
	_solid_dashes(top, top + Vector2(rx, 0), UiTheme.SAND)
	_mark("r", top + Vector2(rx * 0.5, -40.0), 0)
	var x := rx + 28.0
	_measure("h", top + Vector2(x, 0), low + Vector2(x, 0), c + Vector2(x + 12.0, 0))


## An open box with a square base, seen from above and to one side.
func _open_bin(c: Vector2, rx: float) -> void:
	var u := Vector2(rx * 0.95, rx * 0.26)
	var v := Vector2(rx * 0.75, -rx * 0.34)
	var tall := Vector2(0, size.y * 0.32)
	var front := c + Vector2(-rx * 0.85, -tall.y * 0.2)
	var a := front
	var b := a + u
	var d := a + v
	var e := b + v
	for p in [a, b, e]:
		_edge(p, p + tall)
	_edge(a, b)
	_edge(b, e)
	_edge(e, d)
	_edge(d, a)
	_edge(a + tall, b + tall)
	_edge(b + tall, e + tall)
	_solid_dashes(d, d + tall)
	_solid_dashes(a + tall, d + tall)
	_solid_dashes(d + tall, e + tall)
	var under := Vector2(-10, 26)
	_measure("a", a + tall + under, b + tall + under, (a + b) / 2.0 + tall + Vector2(-34, 58), 0)
	var x := Vector2(36, 0)
	_measure("h", e + x, e + tall + x, e + tall * 0.5 + x + Vector2(12, 0))
	if spec.has("a2"):
		_mark("a2", (b + e) / 2.0 + tall + Vector2(40, 34), 0)


## A cylinder that fits exactly inside a sphere.
func _inscribed(c: Vector2, rx: float) -> void:
	draw_arc(c, rx, 0.0, TAU, 96, UiTheme.TEAL, 4.0, true)
	var half := rx * 0.62
	var wide := sqrt(rx * rx - half * half)
	var ry := wide * 0.24
	var top := c - Vector2(0, half)
	var low := c + Vector2(0, half)
	_edge(top + Vector2(wide, 0), low + Vector2(wide, 0))
	_edge(top - Vector2(wide, 0), low - Vector2(wide, 0))
	_rim(top, wide, ry, 0.0, TAU, UiTheme.DIM)
	_rim(low, wide, ry, 0.0, PI, UiTheme.DIM)
	_rim(low, wide, ry, PI, TAU, UiTheme.DIM, true)
	var x := rx + 26.0
	_measure("h", c - Vector2(x, half), c - Vector2(x, -half), c - Vector2(x + 12.0, 0), 1)
	_solid_dashes(c, c + Vector2(rx, 0).rotated(-0.32), UiTheme.SAND)
	_mark("r", c + Vector2(rx * 0.5, -rx * 0.28))


## A flat sector. The angle is drawn to size when the label gives it.
func _solid_sector(c: Vector2, rad: float) -> void:
	var text: String = spec.get("theta", "")
	var deg := text.to_float()
	if deg <= 0.0:
		deg = 216.0
	var sweep := deg_to_rad(deg)
	var start := -PI / 2.0 - sweep / 2.0
	var o := c + Vector2(0, rad * 0.14)
	var a := o + Vector2(cos(start), sin(start)) * rad
	var b := o + Vector2(cos(start + sweep), sin(start + sweep)) * rad
	_edge(o, a)
	_edge(o, b)
	draw_arc(o, rad, start, start + sweep, 96, UiTheme.TEAL, 4.0, true)
	draw_arc(o, rad * 0.2, start, start + sweep, 32, UiTheme.SAND, 3.0, true)
	var up := o + Vector2(0, -rad * 0.34)
	_mark("theta", up)
	_mark("l", (o + b) / 2.0)


# ── Sequences ────────────────────────────────────────────────

## A ball's path: half a parabola for the drop, then a whole one for each rebound. A flight takes
## time in step with the square root of its height, so the arcs narrow as they should.
func _bounce() -> void:
	var box := Rect2(Vector2(96, 56), size - Vector2(140, 124))
	var ground := box.end.y
	draw_line(Vector2(box.position.x, box.position.y - 24), Vector2(box.position.x, ground + 16), UiTheme.DIM, 4.0)
	draw_line(Vector2(box.position.x - 16, ground), Vector2(box.end.x + 16, ground), UiTheme.DIM, 4.0)
	_text("h", Vector2(box.position.x - 34, box.position.y + 2), UiTheme.DIM, FONT_SIZE - 4)
	_text("t", Vector2(box.end.x + 12, ground + 42), UiTheme.DIM, FONT_SIZE - 4)
	var peaks: Array = spec.peaks
	var span := 1.0
	for i in range(1, peaks.size()):
		span += 2.0 * sqrt(float(peaks[i]))
	var unit := box.size.x / span
	var at := box.position.x
	for i in peaks.size():
		var top: float = float(peaks[i]) * box.size.y
		var half := sqrt(float(peaks[i])) * unit
		var pts := PackedVector2Array()
		for j in 25:
			var u := float(j) / 24.0
			var x := u if i == 0 else 2.0 * u - 1.0
			var dx := at + (half * x if i == 0 else half * (x + 1.0))
			pts.append(Vector2(dx, ground - top * (1.0 - x * x)))
		draw_polyline(pts, UiTheme.TEAL, 5.0, true)
		at += half if i == 0 else 2.0 * half
	_dashes(Vector2(box.position.x, box.position.y), Vector2(box.position.x + 110, box.position.y), UiTheme.SAND, 3.0)
	_chip(spec.h_label, Vector2(box.position.x + 190, box.position.y + 12), UiTheme.SAND)


func _squares() -> void:
	var side := minf(size.x - 120.0, size.y - 110.0)
	var box := Rect2(Vector2((size.x - side) / 2.0, 54.0), Vector2(side, side))
	if spec.style == "nested":
		_nested(box)
		_text(spec.side, Vector2(box.get_center().x, box.end.y + 44), UiTheme.SAND, FONT_SIZE - 4)
		return
	_cut(box, int(spec.cut), int(spec.shaded), 3)
	_text("Area %s" % spec.area, Vector2(box.get_center().x, box.end.y + 44), UiTheme.SAND, FONT_SIZE - 4)


## One grid: the bottom left cells shaded first, the top right cell always left to cut again.
func _cut(box: Rect2, cut: int, shaded: int, depth: int) -> void:
	var cell := box.size.x / cut
	var done := 0
	for row in range(cut - 1, -1, -1):
		for col in cut:
			var r := Rect2(box.position + Vector2(col, row) * cell, Vector2(cell, cell))
			if row == 0 and col == cut - 1:
				if depth > 0:
					_cut(r, cut, shaded, depth - 1)
				draw_rect(r, UiTheme.DIM, false, 2.0)
				continue
			if done < shaded:
				draw_rect(r, Color(UiTheme.TEAL, 0.55))
				done += 1
			draw_rect(r, UiTheme.DIM, false, 2.0)


func _nested(box: Rect2) -> void:
	var t: float = spec.t
	var corners := PackedVector2Array([box.position, Vector2(box.end.x, box.position.y), box.end, Vector2(box.position.x, box.end.y)])
	for k in 6:
		var loop := corners.duplicate()
		loop.append(corners[0])
		draw_polyline(loop, UiTheme.TEAL if k == 0 else Color(UiTheme.TEAL, 0.75), 4.0 if k == 0 else 3.0, true)
		var inner := PackedVector2Array()
		for i in 4:
			inner.append(corners[i].lerp(corners[(i + 1) % 4], t))
		corners = inner


# ── Box plots ────────────────────────────────────────────────

func _box_plots() -> void:
	var left := PAD + 30.0
	var right := size.x - PAD - 30.0
	var scaled: bool = spec.get("scale", true)
	var rows: Array = spec.boxes
	if not scaled:
		_box_sketch(left, right)
		return
	var x0 := float(spec.x0)
	var x1 := float(spec.x1)
	var px := func(v: float) -> float: return left + (v - x0) / (x1 - x0) * (right - left)
	var base := BOX_ROW * rows.size() + 40.0
	var tick := float(spec.tick)
	var count := roundi((x1 - x0) / tick)
	# The ticks run up the figure, so a value is read straight down to its number.
	for k in count + 1:
		var p: float = px.call(x0 + k * tick)
		var bold: bool = k % int(spec.every) == 0
		draw_line(Vector2(p, 16), Vector2(p, base), Color(1, 1, 1, 0.34 if bold else 0.15), 2.0)
		draw_line(Vector2(p, base), Vector2(p, base + (20.0 if bold else 12.0)), UiTheme.DIM, 3.0)
		if bold:
			_text(_n(x0 + k * tick), Vector2(p, base + 58.0), UiTheme.DIM, FONT_SIZE - 6)
	draw_line(Vector2(left, base), Vector2(right, base), UiTheme.DIM, 4.0)
	_text(spec.name, Vector2(size.x / 2.0, base + 108.0), UiTheme.TEXT, FONT_SIZE - 4)
	for i in rows.size():
		_one_box(rows[i], 28.0 + BOX_ROW * i, px)


func _one_box(b: Dictionary, top: float, px: Callable) -> void:
	var named: bool = b.name != ""
	var y0 := top + (34.0 if named else 8.0)
	var h := BOX_ROW - (70.0 if named else 44.0)
	var y := y0 + h / 2.0
	var at := func(key: String) -> float: return px.call(float(b[key]))
	var box := Rect2(Vector2(at.call("q1"), y0), Vector2(at.call("q3") - at.call("q1"), h))
	draw_rect(box, Color(UiTheme.TEAL, 0.28))
	draw_rect(box, UiTheme.TEAL, false, 4.0)
	draw_line(Vector2(at.call("med"), y0), Vector2(at.call("med"), y0 + h), UiTheme.SAND, 6.0)
	draw_line(Vector2(at.call("min"), y), Vector2(at.call("q1"), y), UiTheme.TEAL, 4.0)
	draw_line(Vector2(at.call("q3"), y), Vector2(at.call("max"), y), UiTheme.TEAL, 4.0)
	for key in ["min", "max"]:
		draw_line(Vector2(at.call(key), y - 20.0), Vector2(at.call(key), y + 20.0), UiTheme.TEAL, 4.0)
	for v in b.out:
		var c := Vector2(px.call(float(v)), y)
		draw_line(c + Vector2(-13, -13), c + Vector2(13, 13), UiTheme.SAND, 5.0)
		draw_line(c + Vector2(-13, 13), c + Vector2(13, -13), UiTheme.SAND, 5.0)
	if named:
		_chip(b.name, Vector2(px.call(float(b.min)) + 30.0 if b.name.length() > 1 else 26.0, top + 22.0), UiTheme.TEXT, FONT_SIZE - 6)


## Not to scale: the shape of the box and five labels under its points.
func _box_sketch(left: float, right: float) -> void:
	var b: Dictionary = spec.boxes[0]
	var lo := float(b.min)
	var hi := float(b.max)
	var px := func(v: float) -> float: return left + 40.0 + (v - lo) / (hi - lo) * (right - left - 80.0)
	_text(spec.name, Vector2(size.x / 2.0, 44.0), UiTheme.TEXT, FONT_SIZE - 4)
	_one_box(b, 70.0, px)
	for i in spec.labels.size():
		var key: String = ["min", "q1", "med", "q3", "max"][i]
		_text(spec.labels[i], Vector2(px.call(float(b[key])), 262.0), UiTheme.TEXT, FONT_SIZE - 2)
