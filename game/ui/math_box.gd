class_name MathBox
extends RefCounted
## Maths laid out as on paper (FAL-797): a tree of boxes. A ROW holds boxes side by side,
## a TEXT box is a run of text, a FRACTION holds two rows (its top and its bottom) stacked
## over a bar, a POWER holds one row, raised and smaller, and a ROOT holds one row under a
## radical sign and its bar. MathLabel draws a tree cut from text by MathText; typed
## answers (FAL-812) and the calculator (FAL-813) build and edit one, so what is typed
## looks like what is shown.
##
## layout() sizes every box and places each child from its parent's baseline; drawn()
## then lists what to draw. to_text() gives the tree back in the syntax Expr and
## Answer.parse_number read: (n)/(d), ^(…) and √(…).
##
## A fraction's top and bottom are FRACTION_SCALE of the line's size, and a fraction in a
## fraction shrinks again, but never below a power's size, so the smallest numbers stay
## readable on a phone. In a power, a fraction keeps the power's size.

enum Kind { TEXT, ROW, FRACTION, POWER, ROOT }

## The line's size for a fraction's top and bottom.
const FRACTION_SCALE := 0.85
## The bar's height above the baseline, about the middle of a minus sign, as a share of
## the size. The bar's thickness and the gaps above and below it, likewise.
const AXIS := 0.3
const BAR := 0.06
const GAP := 0.1
## How far the bar runs past the wider of the top and bottom, and the space either side.
const OVERHANG := 0.08
const SIDE := 0.05
## The height of a number or letter above and below the baseline, as a share of the
## size. An empty row is this tall too, so an empty fraction part keeps its place.
const INK_ASCENT := 0.8
const INK_DESCENT := 0.24
## A radical sign's width, and the space between it and what is under it.
const RADICAL := 0.5
const RADICAL_GAP := 0.06

var kind := Kind.ROW
## A TEXT box's text.
var text := ""
## A ROW's boxes; a FRACTION's top and bottom rows; a POWER's or a ROOT's one row.
var children: Array = []

## Set by layout(): the width, the height above and below the baseline, the font size,
## and where this box's baseline starts in its parent's.
var w := 0.0
var asc := 0.0
var desc := 0.0
var font_size := 0
var at := Vector2.ZERO
## A FRACTION's bar, and a ROOT's sign and bar as one line, and that line's thickness.
var _bar := Rect2()
var _radical := PackedVector2Array()
var _line := 0.0


static func text_box(s: String) -> MathBox:
	var b := MathBox.new()
	b.kind = Kind.TEXT
	b.text = s
	return b


static func row(items: Array = []) -> MathBox:
	var b := MathBox.new()
	b.children = items
	return b


static func fraction(top: MathBox, bottom: MathBox) -> MathBox:
	return _with(Kind.FRACTION, [top, bottom])


static func power(inner: MathBox) -> MathBox:
	return _with(Kind.POWER, [inner])


static func root(inner: MathBox) -> MathBox:
	return _with(Kind.ROOT, [inner])


static func _with(k: Kind, rows: Array) -> MathBox:
	var b := MathBox.new()
	b.kind = k
	b.children = rows
	return b


## The tree for shown maths, with slashes, carets and roots as the questions write them.
static func parse(s: String) -> MathBox:
	return from_nodes(MathText.parse(s))


## A row from MathText.parse()'s nodes.
static func from_nodes(nodes: Array) -> MathBox:
	return row(nodes.map(from_node))


static func from_node(n) -> MathBox:
	if n is String:
		return text_box(n)
	if n.has("pow"):
		return power(from_nodes(n.pow))
	if n.has("root"):
		return root(from_nodes(n.root))
	return fraction(from_nodes(n.num), from_nodes(n.den))


## The tree in the syntax Expr reads: a fraction as (n)/(d), a power as ^(…), a root
## as √(…).
func to_text() -> String:
	match kind:
		Kind.TEXT:
			return text
		Kind.FRACTION:
			return "(%s)/(%s)" % [children[0].to_text(), children[1].to_text()]
		Kind.POWER:
			return "^(%s)" % children[0].to_text()
		Kind.ROOT:
			return "√(%s)" % children[0].to_text()
	var out := ""
	for c in children:
		out += c.to_text()
	return out


## The tree as one line to read, as RichTextLabel.get_parsed_text() would give: powers
## without their carets, and brackets only where a top, a bottom or a root needs them:
## "e^(2x) + 1/2" is "e2x + 1/2".
func plain() -> String:
	match kind:
		Kind.TEXT:
			return text
		Kind.FRACTION:
			return _bracketed(children[0].plain(), " ") + "/" + _bracketed(children[1].plain(), " ")
		Kind.POWER:
			return children[0].plain()
		Kind.ROOT:
			return "√" + _bracketed(children[0].plain(), " +−-×·/")
	var out := ""
	for c in children:
		out += c.plain()
	return out


static func _bracketed(s: String, breaks: String) -> String:
	for c in breaks:
		if s.contains(c):
			return "(%s)" % s
	return s


## Sizes this box and everything in it at font size s. base is the line's own size, for
## the smallest a fraction may get; in_power keeps a fraction at the power's size.
func layout(font: Font, s: int, base: int = -1, in_power := false) -> void:
	if base < 0:
		base = s
	font_size = s
	match kind:
		Kind.TEXT:
			w = font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, s).x
			asc = s * INK_ASCENT
			desc = s * INK_DESCENT
		Kind.ROW:
			w = 0.0
			asc = s * INK_ASCENT
			desc = s * INK_DESCENT
			for c in children:
				c.layout(font, s, base, in_power)
				c.at = Vector2(w, 0.0)
				w += c.w
				asc = maxf(asc, c.asc)
				desc = maxf(desc, c.desc)
		Kind.POWER:
			_layout_power(font, s, base)
		Kind.FRACTION:
			_layout_fraction(font, s, base, in_power)
		Kind.ROOT:
			_layout_root(font, s, base, in_power)


func _layout_power(font: Font, s: int, base: int) -> void:
	var ps := roundi(s * UiTheme.POWER_SCALE)
	var inner: MathBox = children[0]
	inner.layout(font, ps, base, true)
	# As UiTheme's raised font: up by a share of the power's own line height.
	var rise := -UiTheme.POWER_RAISE * font.get_height(ps)
	inner.at = Vector2(0.0, -rise)
	w = inner.w
	asc = maxf(s * INK_ASCENT, rise + inner.asc)
	desc = maxf(0.0, inner.desc - rise)


func _layout_fraction(font: Font, s: int, base: int, in_power: bool) -> void:
	var fs := s if in_power else maxi(roundi(s * FRACTION_SCALE), roundi(base * UiTheme.POWER_SCALE))
	var top: MathBox = children[0]
	var bottom: MathBox = children[1]
	top.layout(font, fs, base, in_power)
	bottom.layout(font, fs, base, in_power)
	var bar := maxf(2.0, roundf(s * BAR))
	var gap := s * GAP
	var side := s * SIDE
	var bar_w := maxf(top.w, bottom.w) + 2.0 * s * OVERHANG
	var bar_top := -s * AXIS - bar / 2.0
	_bar = Rect2(side, bar_top, bar_w, bar)
	top.at = Vector2(side + (bar_w - top.w) / 2.0, bar_top - gap - top.desc)
	bottom.at = Vector2(side + (bar_w - bottom.w) / 2.0, bar_top + bar + gap + bottom.asc)
	w = bar_w + 2.0 * side
	asc = top.asc - top.at.y
	desc = maxf(0.0, bottom.desc + bottom.at.y)


## A tick, a stroke down to the foot, a stroke up to the bar, and the bar over the row.
func _layout_root(font: Font, s: int, base: int, in_power: bool) -> void:
	var inner: MathBox = children[0]
	inner.layout(font, s, base, in_power)
	_line = maxf(2.0, roundf(s * BAR))
	var side := s * SIDE
	inner.at = Vector2(side + s * RADICAL + s * RADICAL_GAP, 0.0)
	var bar_y := -inner.asc - s * GAP - _line / 2.0
	# The foot sits as low as the row's ink: just under the baseline for a number, at the
	# bottom of a fraction under the sign.
	var foot := maxf(0.0, inner.desc - s * INK_DESCENT) + s * 0.05
	var h := foot - bar_y
	var tick := Vector2(side, foot - 0.45 * h)
	var end := inner.at.x + inner.w + s * OVERHANG
	_radical = PackedVector2Array([tick, tick + Vector2(s * RADICAL * 0.22, -s * 0.06),
		Vector2(side + s * RADICAL * 0.5, foot), Vector2(side + s * RADICAL, bar_y), Vector2(end, bar_y)])
	w = end + side
	asc = -bar_y + _line / 2.0
	desc = maxf(inner.desc, foot + _line / 2.0)


## What to draw, where, after layout(), with this box's baseline starting at origin:
## {"text", "at" (the baseline's left end), "size"} for each piece of text, {"bar": Rect2}
## for each fraction's bar and {"radical": the points, "width"} for each root's sign
## and bar.
func drawn(origin := Vector2.ZERO) -> Array:
	var out := []
	_drawn(origin, out)
	return out


func _drawn(origin: Vector2, out: Array) -> void:
	match kind:
		Kind.TEXT:
			out.append({"text": text, "at": origin, "size": font_size})
			return
		Kind.FRACTION:
			out.append({"bar": Rect2(origin + _bar.position, _bar.size)})
		Kind.ROOT:
			var pts := PackedVector2Array()
			for p in _radical:
				pts.append(origin + p)
			out.append({"radical": pts, "width": _line})
	for c in children:
		c._drawn(origin + c.at, out)


## Draws it on ci, as drawn() lists it.
func draw(ci: CanvasItem, font: Font, origin: Vector2, color: Color) -> void:
	for d in drawn(origin):
		draw_piece(ci, font, d, color)


static func draw_piece(ci: CanvasItem, font: Font, d: Dictionary, color: Color) -> void:
	if d.has("bar"):
		ci.draw_rect(d.bar, color)
	elif d.has("radical"):
		ci.draw_polyline(d.radical, color, d.width, true)
	else:
		ci.draw_string(font, d.at, d.text, HORIZONTAL_ALIGNMENT_LEFT, -1, d.size, color)
