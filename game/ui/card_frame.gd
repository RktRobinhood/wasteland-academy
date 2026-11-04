class_name CardFrame
extends MarginContainer
## The question card's rusted metal frame (assets/ui/question-card.png), the reel's card
## (FAL-331): a 9-slice with a transparent centre, over the card's colour, as in the HTML
## game (css/combat.css). The child stays inside it and scrolls there, so the frame
## holds still. A StyleBoxTexture draws its slices at one size, so this draws one scaled:
## `art_scale` sets the frame's thickness, and the edges tile whole, for the stripe.

const ART := preload("res://assets/ui/question-card.png")
## The art's slices, in its own pixels.
const SLICE := 40
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
