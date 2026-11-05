class_name RegionPlot
extends RefCounted
## PlotView's `region` kind (FAL-739): a shape from t3-composite-circular-region, drawn to its real
## proportions with the region shaded. Each spec has a "shape":
##   segment  {"theta", "r_label", "angle_label", "circle", "parts"}: sector OAB with the segment
##            on chord AB shaded; `circle` draws the rest of the circle, `parts` writes P and Q
##   tether   {"theta", "r_label", "angle_label", "arc_label", "mark_a"}: walls meeting at A, O on
##            one of them, sector ODE and triangle OEA shaded; `mark_a` marks the angle at A
##   semi     {"theta", "r_label", "angle_label"}: a semicircle on PQ, with triangle POR and the
##            segment on RQ shaded
##   arch     {"theta", "r", "h", "r_label", "angle_label", "h_label"}: a rectangle with a segment
##            on top, shaded, with the arc's centre O and radii dashed
##   hatch    {"rho", "h", "w_label", "h_label"}: a rectangle with a semicircle on top, shaded
##   tangent  {"theta", "r_label", "angle_label"}: tangents from A touching a circle at D and E,
##            with the part between them and the minor arc shaded

const FILL := 0.32
const LINE := 5.0
const NEAR := 46.0


static func draw(v: PlotView) -> void:
	match v.spec.get("shape", ""):
		"segment":
			_segment(v)
		"tether":
			_tether(v)
		"semi":
			_semi(v)
		"arch":
			_arch(v)
		"hatch":
			_hatch(v)
		"tangent":
			_tangent(v)


static func _shade(v: PlotView, pts: PackedVector2Array) -> void:
	# Triangles from the first point: every shape here is star-shaped about it.
	var fill := Color(UiTheme.TEAL, FILL)
	for i in range(1, pts.size() - 1):
		v.draw_colored_polygon(PackedVector2Array([pts[0], pts[i], pts[i + 1]]), fill)


## The scale that fits a span into a box, and the point the span's low corner goes to.
static func _fit(box: Rect2, lo: Vector2, hi: Vector2) -> Dictionary:
	var span := (hi - lo).max(Vector2(0.2, 0.2))
	var k := minf(box.size.x / span.x, box.size.y / span.y)
	# y is up in the shape and down on screen: hi.y is the top of the box.
	var off := box.position + (box.size - span * k) / 2.0
	return {"k": k, "o": off + Vector2(-lo.x, hi.y) * k}


static func _angle_chip(v: PlotView, s: String, at: Vector2) -> void:
	v._chip(s, at, UiTheme.PINK if s in ["θ", "2α"] else UiTheme.SAND, PlotView.FONT_SIZE - 2)


static func _name(v: PlotView, s: String, at: Vector2) -> void:
	v._text(s, at + Vector2(0, 12), UiTheme.TEXT)


static func _length(v: PlotView, s: String, at: Vector2) -> void:
	v._chip(s, at, UiTheme.PINK if s == "r" else UiTheme.SAND)


static func _segment(v: PlotView) -> void:
	var th: float = v.spec.theta
	var circle: bool = v.spec.get("circle", false)
	var box := Rect2(Vector2(90, 56), v.size - Vector2(180, 112))
	# The chord is on the right, with the angle at O opening to it.
	var a0 := -th / 2.0
	var lo := Vector2(-1.0, -1.0) if circle else Vector2(-0.05, -sin(th / 2.0))
	var hi := Vector2(1.0, 1.0) if circle else Vector2(1.0, sin(th / 2.0))
	var f := _fit(box, lo, hi)
	var c: Vector2 = f.o
	var k: float = f.k
	var arc := v._arc_points(c, k, a0, th)
	if circle:
		v.draw_arc(c, k, 0.0, TAU, 96, UiTheme.DIM, 3.0, true)
	_shade(v, arc)
	v.draw_polyline(arc, UiTheme.TEAL, LINE, true)
	var p_a := v._on_circle(c, k, a0 + th)
	var p_b := v._on_circle(c, k, a0)
	v.draw_line(p_a, p_b, UiTheme.TEAL, LINE, true)
	v._dashes(c, p_a, UiTheme.SAND)
	v._dashes(c, p_b, UiTheme.SAND)
	v.draw_circle(c, PlotView.DOT * 0.6, UiTheme.TEXT)
	_name(v, "O", c + Vector2(-34, 0))
	_name(v, "A", v._on_circle(c, k + 32.0, a0 + th))
	_name(v, "B", v._on_circle(c, k + 32.0, a0))
	var near := minf(NEAR, k * cos(th / 2.0) * 0.6)
	near = maxf(near, 26.0)
	v.draw_polyline(v._arc_points(c, near, a0, th), UiTheme.SAND, 3.0, true)
	_angle_chip(v, v.spec.angle_label, c + Vector2(near + 34.0, 10.0))
	var mid := (c + p_a) / 2.0
	var out_dir := Vector2(-sin(th / 2.0), -cos(th / 2.0))
	_length(v, v.spec.r_label, mid + out_dir * 34.0 + Vector2(0, 10))
	if v.spec.get("parts", false):
		var chord_x := k * cos(th / 2.0)
		v._text("P", c + Vector2(chord_x + (k - chord_x) * 0.42, 12), UiTheme.TEXT)
		v._text("Q", c + Vector2(chord_x * 0.72, 54), UiTheme.TEXT)


static func _tether(v: PlotView) -> void:
	var th: float = v.spec.theta
	# In units of the rope: O at the origin, the wall through D and A along the x-axis.
	var o := Vector2.ZERO
	var d := Vector2(-1.0, 0.0)
	var a := Vector2(1.0, 0.0)
	var e := Vector2(-cos(th), -sin(th))
	var lo := Vector2(-1.15, minf(e.y * 1.12, -1.0 if th > PI / 2.0 else e.y))
	var hi := Vector2(1.0, 0.0)
	var f := _fit(Rect2(Vector2(90, 70), v.size - Vector2(180, 140)), lo, hi)
	var k: float = f.k
	var at := func(p: Vector2) -> Vector2: return f.o + Vector2(p.x, -p.y) * k
	var co: Vector2 = at.call(o)
	var ca: Vector2 = at.call(a)
	var cd: Vector2 = at.call(d)
	var ce: Vector2 = at.call(e)
	# Screen angles: D is at π, and the arc runs up to E through the sweep θ.
	var arc := v._arc_points(co, k, PI, th)
	var fan := PackedVector2Array([ca])
	fan.append_array(arc)
	_shade(v, fan)
	v.draw_polyline(arc, UiTheme.TEAL, LINE, true)
	v.draw_line(cd + (cd - ca).normalized() * 40.0, ca, UiTheme.TEXT, LINE, true)
	v.draw_line(ca, ca + (ce - ca) * 1.12, UiTheme.TEXT, LINE, true)
	v._dashes(co, ce, UiTheme.SAND)
	v.draw_circle(co, PlotView.DOT * 0.6, UiTheme.TEXT)
	_name(v, "O", co + Vector2(0, -34))
	_name(v, "A", ca + Vector2(30, -14))
	_name(v, "D", cd + Vector2(0, -32))
	_name(v, "E", ce + (ce - co).normalized() * 22.0 + Vector2(26, 8))
	v.draw_polyline(v._arc_points(co, NEAR, PI, th), UiTheme.SAND, 3.0, true)
	_angle_chip(v, v.spec.angle_label, v._on_circle(co, NEAR + 42.0, PI + th / 2.0) + Vector2(0, 10))
	_length(v, v.spec.r_label, (co + ca) / 2.0 + Vector2(0, -22))
	if v.spec.get("arc_label", "") != "":
		v._chip(v.spec.arc_label, v._on_circle(co, k + 40.0, PI + th * 0.4) + Vector2(-20, 10), UiTheme.SAND)
	if v.spec.get("mark_a", false):
		var ang := (ce - ca).angle()
		var mark := PackedVector2Array()
		for i in 17:
			var t := ang + (PI - ang) * i / 16.0
			mark.append(ca + Vector2(cos(t), sin(t)) * 70.0)
		v.draw_polyline(mark, UiTheme.PINK, 3.0, true)
		var mid := (ang + PI) / 2.0
		v._chip("?", ca + Vector2(cos(mid), sin(mid)) * 104.0 + Vector2(0, 10), UiTheme.PINK)


static func _semi(v: PlotView) -> void:
	var th: float = v.spec.theta
	var f := _fit(Rect2(Vector2(80, 70), v.size - Vector2(160, 140)), Vector2(-1, 0), Vector2(1, 1))
	var c: Vector2 = f.o
	var k: float = f.k
	var p := v._on_circle(c, k, PI)
	var q := v._on_circle(c, k, 0.0)
	var r := v._on_circle(c, k, th)
	_shade(v, PackedVector2Array([p, c, r]))
	_shade(v, v._arc_points(c, k, 0.0, th))
	v.draw_polyline(v._arc_points(c, k, 0.0, PI), UiTheme.TEAL, LINE, true)
	v.draw_line(p, q, UiTheme.TEAL, LINE, true)
	for e in [[p, r], [c, r], [r, q]]:
		v.draw_line(e[0], e[1], UiTheme.TEAL, 3.0, true)
	v.draw_circle(c, PlotView.DOT * 0.6, UiTheme.TEXT)
	_name(v, "O", c + Vector2(0, 30))
	_name(v, "P", p + Vector2(-8, 30))
	_name(v, "Q", q + Vector2(8, 30))
	_name(v, "R", v._on_circle(c, k + 30.0, th))
	v.draw_polyline(v._arc_points(c, NEAR, 0.0, th), UiTheme.SAND, 3.0, true)
	_angle_chip(v, v.spec.angle_label, v._on_circle(c, NEAR + 34.0, th / 2.0) + Vector2(0, 10))
	_length(v, v.spec.r_label, (c + q) / 2.0 + Vector2(0, 40))


static func _arch(v: PlotView) -> void:
	var th: float = v.spec.theta
	var r: float = v.spec.r
	var h: float = v.spec.h
	var half_w := r * sin(th / 2.0)
	var drop := r * cos(th / 2.0)
	var top := r
	var bottom := drop - h
	var f := _fit(Rect2(Vector2(110, 60), v.size - Vector2(260, 130)), Vector2(-half_w, bottom), Vector2(half_w, top))
	var k: float = f.k
	var c: Vector2 = f.o
	var a := v._on_circle(c, r * k, PI / 2.0 + th / 2.0)
	var b := v._on_circle(c, r * k, PI / 2.0 - th / 2.0)
	var a2 := a + Vector2(0, h * k)
	var b2 := b + Vector2(0, h * k)
	var arc := v._arc_points(c, r * k, PI / 2.0 - th / 2.0, th)
	var outline := PackedVector2Array([a2 + (b2 - a2) / 2.0, b2])
	outline.append_array(arc)
	outline.append(a2)
	_shade(v, outline)
	v.draw_polyline(arc, UiTheme.TEAL, LINE, true)
	v.draw_line(a, a2, UiTheme.TEAL, LINE, true)
	v.draw_line(b, b2, UiTheme.TEAL, LINE, true)
	v.draw_line(a2, b2, UiTheme.TEAL, LINE, true)
	v._dashes(c, a, UiTheme.SAND)
	v._dashes(c, b, UiTheme.SAND)
	v.draw_circle(c, PlotView.DOT * 0.6, UiTheme.TEXT)
	_name(v, "O", c + Vector2(0, 32))
	_name(v, "A", a + Vector2(-28, -8))
	_name(v, "B", b + Vector2(28, -8))
	v.draw_polyline(v._arc_points(c, NEAR, PI / 2.0 - th / 2.0, th), UiTheme.SAND, 3.0, true)
	_angle_chip(v, v.spec.angle_label, c + Vector2(0, -(NEAR + 16.0)))
	_length(v, v.spec.r_label, (c + b) / 2.0 + Vector2(0, 10))
	_length(v, v.spec.h_label, (b + b2) / 2.0 + Vector2(92, 10))


static func _hatch(v: PlotView) -> void:
	var rho: float = v.spec.rho
	var h: float = v.spec.h
	var f := _fit(Rect2(Vector2(110, 40), v.size - Vector2(240, 130)), Vector2(-rho, -h), Vector2(rho, rho))
	var k: float = f.k
	var c: Vector2 = f.o
	var arc := v._arc_points(c, rho * k, 0.0, PI)
	var low_l := c + Vector2(-rho, h) * k
	var low_r := c + Vector2(rho, h) * k
	var outline := PackedVector2Array([c + Vector2(0, h) * k, low_r])
	outline.append_array(arc)
	outline.append(low_l)
	_shade(v, outline)
	v.draw_polyline(arc, UiTheme.TEAL, LINE, true)
	v.draw_line(arc[0], low_r, UiTheme.TEAL, LINE, true)
	v.draw_line(arc[arc.size() - 1], low_l, UiTheme.TEAL, LINE, true)
	v.draw_line(low_l, low_r, UiTheme.TEAL, LINE, true)
	v._dashes(arc[0], arc[arc.size() - 1], UiTheme.DIM)
	v._chip(v.spec.w_label, (low_l + low_r) / 2.0 + Vector2(0, 46), UiTheme.SAND)
	v._chip(v.spec.h_label, (arc[0] + low_r) / 2.0 + Vector2(62, 10), UiTheme.SAND)


static func _tangent(v: PlotView) -> void:
	var th: float = v.spec.theta
	# O at the origin and A above it, at distance 1/sin(θ/2) in radii.
	var dist := 1.0 / sin(th / 2.0)
	var half := PI / 2.0 - th / 2.0
	var f := _fit(Rect2(Vector2(90, 66), v.size - Vector2(180, 120)), Vector2(-1, -1), Vector2(1, dist))
	var k: float = f.k
	var c: Vector2 = f.o
	var a := c + Vector2(0, -dist) * k
	var d := v._on_circle(c, k, PI / 2.0 - half)
	var e := v._on_circle(c, k, PI / 2.0 + half)
	# The region: A, then the minor arc from D to E.
	var arc := v._arc_points(c, k, PI / 2.0 - half, 2.0 * half)
	var fan := PackedVector2Array([a])
	fan.append_array(arc)
	_shade(v, fan)
	v.draw_arc(c, k, 0.0, TAU, 96, UiTheme.DIM, 3.0, true)
	v.draw_polyline(arc, UiTheme.TEAL, LINE, true)
	v.draw_line(a, d, UiTheme.TEAL, LINE, true)
	v.draw_line(a, e, UiTheme.TEAL, LINE, true)
	v._dashes(c, d, UiTheme.SAND)
	v._dashes(c, e, UiTheme.SAND)
	v.draw_circle(c, PlotView.DOT * 0.6, UiTheme.TEXT)
	_name(v, "O", c + Vector2(0, 32))
	_name(v, "A", a + Vector2(0, -32))
	_name(v, "D", d + (d - c).normalized() * 30.0)
	_name(v, "E", e + (e - c).normalized() * 30.0)
	var near := minf(NEAR + 12.0, (a.distance_to(d)) * 0.5)
	var down := PI * 1.5
	v.draw_polyline(v._arc_points(a, near, down - th / 2.0, th), UiTheme.SAND, 3.0, true)
	# Inside the region where it has room, else beside A.
	var room := (dist - 1.0) * k > near + 64.0
	_angle_chip(v, v.spec.angle_label, a + (Vector2(0, near + 36.0) if room else Vector2(96, 14)))
	_length(v, v.spec.r_label, (c + d) / 2.0 + Vector2(0, 44))
