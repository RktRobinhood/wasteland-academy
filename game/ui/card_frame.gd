class_name CardFrame
extends MarginContainer
## The question card's rusted metal frame (assets/ui/question-card.png), the reel's card
## (FAL-331): a 9-slice with a transparent centre, over the card's colour, as in the HTML
## game (css/combat.css). The child stays inside it and scrolls there, so the frame
## holds still. A StyleBoxTexture draws its slices at one size, so this draws one scaled:
## `art_scale` sets the frame's thickness, and the edges tile whole. The art's top edge
## isn't a whole number of stripes, so it would show a join at each tile: the top edge
## repeats only the STRIPE_SPAN that is (FAL-733), and its two ends meet the corners.

const ART := preload("res://assets/ui/question-card.png")
## The art's slices, in its own pixels.
const SLICE := 40
## Where the top edge repeats, in art pixels: 9 hazard stripes.
const STRIPE_FROM := 46
const STRIPE_SPAN := 252
## Between the frame's inner edge and the child, in base units.
const INSET := 10

## Base units per art pixel.
var art_scale := 1.0:
	set(value):
		art_scale = value
		for side in ["left", "top", "right", "bottom"]:
			add_theme_constant_override("margin_" + side, thickness() + INSET)
		queue_redraw()

var _style: StyleBoxTexture


func _init() -> void:
	name = "CardFrame"
	_style = StyleBoxTexture.new()
	_style.texture = ART
	_style.draw_center = false
	_style.set_texture_margin_all(SLICE)
	_style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	_style.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	art_scale = 1.0


func thickness() -> int:
	return roundi(SLICE * art_scale)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ONE * thickness() / 2.0, size - Vector2.ONE * thickness()), UiTheme.BG)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE * art_scale)
	draw_style_box(_style, Rect2(Vector2.ZERO, size / art_scale))
	var x := float(SLICE)
	for p in stripe_pieces(size.x / art_scale):
		draw_texture_rect_region(ART, Rect2(x, 0, p.width, SLICE), Rect2(p.from, 0, p.span, SLICE))
		x += p.width


## The top edge between the corners, left to right, for a frame `width` art pixels wide:
## the art's start, the stripes as often as fit, the art's end. Each piece is {from, span}
## in the art and `width` as drawn; together they stretch by the same amount.
static func stripe_pieces(width: float) -> Array:
	var edge := ART.get_width() - SLICE * 2
	var between := width - SLICE * 2
	var repeats := maxi(1, roundi((between - edge) / STRIPE_SPAN) + 1)
	var stretch: float = between / (edge + (repeats - 1) * STRIPE_SPAN)
	var spans: Array = [[SLICE, STRIPE_FROM - SLICE]]
	for i in repeats:
		spans.append([STRIPE_FROM, STRIPE_SPAN])
	spans.append([STRIPE_FROM + STRIPE_SPAN, ART.get_width() - SLICE - STRIPE_FROM - STRIPE_SPAN])
	return spans.map(func(a): return {"from": a[0], "span": a[1], "width": a[1] * stretch})
