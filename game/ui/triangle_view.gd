class_name TriangleView
extends Control
## Draws a question's triangle with Godot's own drawing: the three sides, the vertex
## letters outside the corners, each given side length beside its side, each given
## angle in its corner with an arc, and ? on the side or angle that is asked. Sized
## for a phone, like GraphView.
##
## spec is the "diagram" Dictionary of a question (triangle_views.gd diagram()).
##
## Two triangles (spec.second, the ambiguous case): the side from the top vertex lands
## on the base line in two places. Both are drawn, lettered Y₁ and Y₂, with the side's
## length on each; an asked angle gets its ? at both, and an asked third side a
## measuring line under the base for each.

const PAD := 70.0
const FONT_SIZE := 36
const ARC := 46.0
## Under the base: room for the two measuring lines of an asked third side.
const MEASURE_ROOM := 120.0
const MEASURE_GAP := 58.0

var spec: Dictionary = {}


func _init() -> void:
	custom_minimum_size = Vector2(0, 560)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_spec(s: Dictionary) -> void:
	spec = s
	queue_redraw()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		queue_redraw()


## The vertices in local pixels: the triangle scaled to fit, centred, y up.
func corners() -> Dictionary:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for L in spec.vertices:
		var p: Array = spec.vertices[L]
		lo = lo.min(Vector2(p[0], p[1]))
		hi = hi.max(Vector2(p[0], p[1]))
	var low := PAD + (MEASURE_ROOM if _measures_base() else 0.0)
	var box := size - Vector2(PAD * 2, PAD + low)
	var span := (hi - lo).max(Vector2(0.001, 0.001))
	var k := minf(box.x / span.x, box.y / span.y)
	var off := Vector2(PAD, low) + (box - span * k) / 2.0
	var out := {}
	for L in spec.vertices:
		var p: Array = spec.vertices[L]
		out[L] = Vector2(off.x + (p[0] - lo.x) * k, size.y - off.y - (p[1] - lo.y) * k)
	if spec.has("second"):
		var at: Array = spec.second.at
		out.second = Vector2(off.x + (at[0] - lo.x) * k, size.y - off.y - (at[1] - lo.y) * k)
	return out


## Whether the asked third side is measured under the base (two triangles).
func _measures_base() -> bool:
	if not spec.has("second"):
		return false
	# The base runs from the fixed vertex to the moved one, so it is the top vertex's side.
	return spec.sides.any(func(sd): return sd.label == "?" and spec.vertices[sd.side.to_upper()][1] != 0.0)


func _draw() -> void:
	if spec.is_empty():
		return
	var font := get_theme_default_font()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.1, 0.14))
	var c := corners()
	var mid: Vector2 = (c.A + c.B + c.C) / 3.0
	draw_polyline(PackedVector2Array([c.A, c.B, c.C, c.A]), UiTheme.TEAL, 6.0, true)
	var moved: String = spec.second.vertex if spec.has("second") else ""
	for L in ["A", "B", "C"]:
		var out: Vector2 = (c[L] - mid).normalized()
		_text(font, L + ("₁" if L == moved else ""), c[L] + out * 34.0 + Vector2(0, 12), UiTheme.TEXT, FONT_SIZE + 4)
	if moved != "":
		var top: String = ["A", "B", "C"].filter(func(L): return L != moved and spec.vertices[L][1] != 0.0)[0]
		draw_line(c[top], c.second, UiTheme.TEAL, 6.0, true)
		_text(font, moved + "₂", c.second + Vector2(0, 50), UiTheme.TEXT, FONT_SIZE + 4)
	for sd in spec.sides:
		if sd.label == "" or (sd.label == "?" and _measures_base()):
			continue
		var ends := ["A", "B", "C"].filter(func(x): return x != sd.side.to_upper())
		_side_label(font, sd.label, c[ends[0]], c[ends[1]], mid)
		if moved != "" and moved in ends:
			var far: String = ends[0] if ends[1] == moved else ends[1]
			_side_label(font, sd.label, c[far], c.second, c[moved])
	if _measures_base():
		_measure(font, c, c.second, MEASURE_GAP)
		_measure(font, c, c[moved], MEASURE_GAP * 2.0)
	for an in spec.angles:
		if an.label == "":
			continue
		var others := ["A", "B", "C"].filter(func(x): return x != an.at)
		_angle_label(font, an.label, c[an.at], c[others[0]], c[others[1]])
		if an.at == moved:
			_angle_label(font, an.label, c.second, c[others[0]], c[others[1]])


## A side's label beside the line from p to q, on the far side from `away`.
func _side_label(font: Font, label: String, p: Vector2, q: Vector2, away: Vector2) -> void:
	var m := (p + q) / 2.0
	var normal := (q - p).orthogonal().normalized()
	if normal.dot(m - away) < 0.0:
		normal = -normal
	# Far enough out that the whole label clears the side, however it slopes.
	var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	var gap := 22.0 + absf(normal.x) * w / 2.0 + absf(normal.y) * FONT_SIZE / 2.0
	_text(font, label, m + normal * gap + Vector2(0, 12), UiTheme.PINK if label == "?" else UiTheme.SAND, FONT_SIZE, true)


## The angle at `at` between the lines to p and q: its arc and label.
func _angle_label(font: Font, label: String, at: Vector2, p: Vector2, q: Vector2) -> void:
	var a0: float = (p - at).angle()
	var a1: float = (q - at).angle()
	var d := wrapf(a1 - a0, -PI, PI)
	draw_arc(at, ARC, a0, a0 + d, 24, UiTheme.SAND, 3.0, true)
	# Along the bisector, further in where the corner is narrow.
	var into := Vector2.from_angle(a0 + d / 2.0)
	var reach := ARC + 40.0 / maxf(sin(absf(d) / 2.0), 0.3)
	_text(font, label, at + into * reach + Vector2(0, 12), UiTheme.PINK if label == "?" else UiTheme.SAND, FONT_SIZE - 4, true)


## A measuring line `below` under the base, from its fixed end to `to`, marked ?.
func _measure(font: Font, c: Dictionary, to: Vector2, below: float) -> void:
	var fixed: String = ["A", "B", "C"].filter(func(L): return L != spec.second.vertex and spec.vertices[L][1] == 0.0)[0]
	var p: Vector2 = c[fixed] + Vector2(0, below + 36.0)
	var q := Vector2(to.x, p.y)
	draw_line(p, q, UiTheme.PINK, 3.0, true)
	draw_line(p + Vector2(0, -12), p + Vector2(0, 12), UiTheme.PINK, 3.0, true)
	draw_line(q + Vector2(0, -12), q + Vector2(0, 12), UiTheme.PINK, 3.0, true)
	_text(font, "?", (p + q) / 2.0 + Vector2(0, 12), UiTheme.PINK, FONT_SIZE, true)


func _text(font: Font, s: String, at: Vector2, col: Color, fs: int, backed: bool = false) -> void:
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var pos := at - Vector2(w / 2.0, 0)
	if backed:
		draw_rect(Rect2(pos + Vector2(-6, -fs + 2), Vector2(w + 12, fs + 10)), Color(0.08, 0.1, 0.14, 0.85))
	draw_string(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
