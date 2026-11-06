class_name SpinnerPlot
extends RefCounted
## PlotView's `spinners` kind (FAL-752): the two objects of a sample space question, side by side.
## spec.items is [{"name", "shape", "labels", "shares"}]: a "spinner" is a circle cut into sectors
## by `shares` (they add to 1), each with its label, and a "die" is its faces laid out flat.

const LINE := 3.0
const TOP := 62.0
const TINTS := [Color(0.16, 0.3, 0.34), Color(0.2, 0.2, 0.3)]


static func draw(v: PlotView) -> void:
	var items: Array = v.spec.items
	var w: float = v.size.x / items.size()
	for i in items.size():
		var box := Rect2(Vector2(w * i + 12.0, TOP), Vector2(w - 24.0, v.size.y - TOP - 16.0))
		v._text(items[i].name, Vector2(w * (i + 0.5), 44.0), UiTheme.SAND)
		if items[i].shape == "spinner":
			_spinner(v, box, items[i])
		else:
			_die(v, box, items[i])


static func _spinner(v: PlotView, box: Rect2, item: Dictionary) -> void:
	var c := box.get_center()
	var r := minf(box.size.x, box.size.y) / 2.0 - 10.0
	var at := -PI / 2.0
	for i in item.labels.size():
		var sweep: float = TAU * float(item.shares[i])
		var pts := PackedVector2Array([c])
		var steps := maxi(4, ceili(sweep * 12.0))
		for j in steps + 1:
			pts.append(c + Vector2.from_angle(at + sweep * j / steps) * r)
		v.draw_colored_polygon(pts, TINTS[i % 2] if item.labels.size() % 2 == 0 or i < item.labels.size() - 1 else TINTS[0].darkened(0.3))
		v.draw_line(c, pts[1], UiTheme.TEXT, LINE, true)
		var mid := c + Vector2.from_angle(at + sweep / 2.0) * r * 0.66
		v._text(item.labels[i], mid + Vector2(0, 11), UiTheme.TEXT)
		at += sweep
	v.draw_arc(c, r, 0.0, TAU, 64, UiTheme.TEXT, LINE, true)
	# The pointer, at the top.
	v.draw_colored_polygon(PackedVector2Array([c + Vector2(-12, -r - 12), c + Vector2(12, -r - 12), c + Vector2(0, -r + 12)]), UiTheme.SAND)


static func _die(v: PlotView, box: Rect2, item: Dictionary) -> void:
	var n: int = item.labels.size()
	var cols := ceili(n / 2.0)
	var side := minf(minf(box.size.x / cols, box.size.y / 2.0), 130.0)
	var corner := box.get_center() - Vector2(side * cols, side * 2.0) / 2.0
	for i in n:
		var cell := Rect2(corner + Vector2(side * (i % cols), side * (i / cols)), Vector2(side, side)).grow(-4.0)
		v.draw_rect(cell, TINTS[0])
		v.draw_rect(cell, UiTheme.TEXT, false, LINE)
		v._text(item.labels[i], cell.get_center() + Vector2(0, 11), UiTheme.TEXT)
