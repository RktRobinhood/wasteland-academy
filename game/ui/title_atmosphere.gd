extends Control
## A quiet, asset-free title motion layer registered to the cover-fitted key art.
## Keep logos, characters, controls and the camera still. The same coordinates
## survive resizing, even when the painting crops beyond the viewport.

const STEP := 1.0 / 30.0
const TOWER_WIDE := Vector2(0.775, 0.326)
const TOWER_TALL := Vector2(0.747, 0.437)

var source := Vector2.ZERO
var landscape := false
var reduced := false
var clock := 0.0
var _drawn_at := 0.0
var _crow: Array[Texture2D] = []
var _glow: GradientTexture2D


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crow = AmbientLayer.frames("crow")
	var falloff := Gradient.new()
	falloff.offsets = PackedFloat32Array([0.0, 0.36, 1.0])
	falloff.colors = PackedColorArray([Color(1, 1, 1, 0.8), Color(1, 1, 1, 0.24), Color(1, 1, 1, 0.0)])
	_glow = GradientTexture2D.new()
	_glow.width = 64
	_glow.height = 64
	_glow.gradient = falloff
	_glow.fill = GradientTexture2D.FILL_RADIAL
	_glow.fill_from = Vector2(0.5, 0.5)
	_glow.fill_to = Vector2(1.0, 0.5)
	set_process(false)


func configure(art_size: Vector2, wide: bool, reduce_motion: bool) -> void:
	source = art_size
	landscape = wide
	reduced = reduce_motion
	visible = source.x > 0.0 and source.y > 0.0
	set_process(visible and not reduced)
	queue_redraw()


func _process(delta: float) -> void:
	clock += delta
	if clock - _drawn_at >= STEP:
		_drawn_at = clock
		queue_redraw()


## Matches TextureRect.STRETCH_KEEP_ASPECT_COVERED.
static func cover_rect(viewport_size: Vector2, art_size: Vector2) -> Rect2:
	if art_size.x <= 0.0 or art_size.y <= 0.0:
		return Rect2()
	var factor := maxf(viewport_size.x / art_size.x, viewport_size.y / art_size.y)
	var cover := art_size * factor
	return Rect2((viewport_size - cover) * 0.5, cover)


func _draw() -> void:
	if reduced or not is_instance_valid(_glow) or source.x <= 0.0:
		return
	var painting := cover_rect(size, source)
	var tower_uv := TOWER_WIDE if landscape else TOWER_TALL
	var t := clock
	var scale_art := painting.size.x / source.x
	var tower := painting.position + tower_uv * painting.size
	var halo := Vector2(125, 110) * scale_art
	var pulse := 0.26 + 0.12 * sin(TAU * t / 4.8)
	draw_texture_rect(_glow, Rect2(tower - halo * 0.5, halo), false, Color(1.0, 0.11, 0.48, pulse))
	# A crow crosses the open sky, with several seconds of quiet between passes.
	var flight := fposmod(t + 3.0, 19.0) / 13.5
	if flight < 1.0 and not _crow.is_empty():
		var u := lerpf(0.19, 0.89, flight)
		var y := (0.384 if landscape else 0.475) - sin(PI * flight) * 0.048
		y += sin(t * 2.6) * 0.0035
		var at := painting.position + Vector2(u, y) * painting.size
		var wing := _crow[int(t * 10.0) % _crow.size()]
		var span := wing.get_size() * scale_art * (0.65 if landscape else 0.62)
		var fade := minf(1.0, minf(flight, 1.0 - flight) * 10.0)
		draw_texture_rect(wing, Rect2(at - span * 0.5, span), false, Color(0.55, 0.48, 0.50, fade * 0.83))
	# A few sparse windblown grains at road level, not a full-screen overlay.
	for n in 9:
		var life := fposmod(t * (0.085 + 0.004 * float(n % 3)) + 0.271 * n, 1.0)
		var x := 0.10 + 0.80 * life
		var y := (0.83 if landscape else 0.72) + 0.065 * fposmod(0.43 * n, 1.0) - life * 0.012
		var at := painting.position + Vector2(x, y) * painting.size
		var amount := sin(PI * life) * (0.15 + 0.035 * (n % 3))
		draw_line(at, at + Vector2(5.0, -1.0) * scale_art, Color(1.0, 0.72, 0.45, amount), maxf(1.0, 1.75 * scale_art), true)
