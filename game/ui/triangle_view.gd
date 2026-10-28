class_name TriangleView
extends Control
## Draws a question's triangle with Godot's own drawing: the three sides, the vertex
## letters outside the corners, each given side length beside its side, each given
## angle in its corner with an arc, and ? on the side or angle that is asked. Sized
## for a phone, like GraphView.
##
## spec is the "diagram" Dictionary of a question (triangle_views.gd diagram()).

const PAD := 70.0
const FONT_SIZE := 36
const ARC := 46.0

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
	var box := size - Vector2(PAD, PAD) * 2
	var span := (hi - lo).max(Vector2(0.001, 0.001))
	var k := minf(box.x / span.x, box.y / span.y)
	var off := Vector2(PAD, PAD) + (box - span * k) / 2.0
	var out := {}
	for L in spec.vertices:
		var p: Array = spec.vertices[L]
		out[L] = Vector2(off.x + (p[0] - lo.x) * k, size.y - off.y - (p[1] - lo.y) * k)
	return out


func _draw() -> void:
	if spec.is_empty():
		return
	var font := get_theme_default_font()
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.08, 0.1, 0.14))
	var c := corners()
	var mid: Vector2 = (c.A + c.B + c.C) / 3.0
	draw_polyline(PackedVector2Array([c.A, c.B, c.C, c.A]), UiTheme.TEAL, 6.0, true)
	for L in ["A", "B", "C"]:
		var out: Vector2 = (c[L] - mid).normalized()
		_text(font, L, c[L] + out * 34.0 + Vector2(0, 12), UiTheme.TEXT, FONT_SIZE + 4)
	for sd in spec.sides:
		if sd.label == "":
			continue
		var ends := ["A", "B", "C"].filter(func(x): return x != sd.side.to_upper())
		var m: Vector2 = (c[ends[0]] + c[ends[1]]) / 2.0
		var normal: Vector2 = (c[ends[1]] - c[ends[0]]).orthogonal().normalized()
		if normal.dot(m - mid) < 0.0:
			normal = -normal
		# Far enough out that the whole label clears the side, however it slopes.
		var w := font.get_string_size(sd.label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
		var gap := 22.0 + absf(normal.x) * w / 2.0 + absf(normal.y) * FONT_SIZE / 2.0
		_text(font, sd.label, m + normal * gap + Vector2(0, 12), UiTheme.PINK if sd.label == "?" else UiTheme.SAND, FONT_SIZE, true)
	for an in spec.angles:
		if an.label == "":
			continue
		var at: Vector2 = c[an.at]
		var others := ["A", "B", "C"].filter(func(x): return x != an.at)
		var a0: float = (c[others[0]] - at).angle()
		var a1: float = (c[others[1]] - at).angle()
		var d := wrapf(a1 - a0, -PI, PI)
		draw_arc(at, ARC, a0, a0 + d, 24, UiTheme.SAND, 3.0, true)
		# Along the bisector, further in where the corner is narrow.
		var into := Vector2.from_angle(a0 + d / 2.0)
		var reach := ARC + 40.0 / maxf(sin(absf(d) / 2.0), 0.3)
		_text(font, an.label, at + into * reach + Vector2(0, 12), UiTheme.PINK if an.label == "?" else UiTheme.SAND, FONT_SIZE - 4, true)


func _text(font: Font, s: String, at: Vector2, col: Color, fs: int, backed: bool = false) -> void:
	var w := font.get_string_size(s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var pos := at - Vector2(w / 2.0, 0)
	if backed:
		draw_rect(Rect2(pos + Vector2(-6, -fs + 2), Vector2(w + 12, fs + 10)), Color(0.08, 0.1, 0.14, 0.85))
	draw_string(font, pos, s, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
