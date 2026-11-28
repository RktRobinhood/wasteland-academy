class_name WorldLight
extends RefCounted
## Stylized device-local light for the artwork only. No geography, network,
## saved preference, or effect on a question, encounter seed or route.
## One cyclic set of keys shared by boards and battle scenery.

# Minute of day, flat-art grade, and intensity for small in-world light sources.
const KEYS := [
	[0.0, Color(0.35, 0.46, 0.72), 1.0],
	[300.0, Color(0.35, 0.46, 0.72), 1.0],
	[360.0, Color(0.82, 0.62, 0.65), 0.78],
	[420.0, Color(1.0, 0.82, 0.66), 0.39],
	[510.0, Color.WHITE, 0.10],
	[960.0, Color.WHITE, 0.10],
	[1080.0, Color(1.0, 0.74, 0.59), 0.41],
	[1140.0, Color(0.79, 0.53, 0.62), 0.76],
	[1230.0, Color(0.35, 0.46, 0.72), 1.0],
	[1440.0, Color(0.35, 0.46, 0.72), 1.0],
]


## A scene-owned sampler: throttle wall-clock reads and ease across a clock jump.
## Ownership is visual only. A prompt can hold the last complete light state.
class SceneGrade:
	var clock: Callable = WorldLight.local_minute
	var grade := Color.WHITE
	var local_light := 0.10
	var _goal := Color.WHITE
	var _local_goal := 0.10
	var _sample_in := 0.0
	var _initialized := false

	func advance(delta: float, held: bool = false) -> void:
		if held and _initialized:
			return
		_sample_in -= delta
		if _sample_in <= 0.0:
			var now := WorldLight.palette(float(clock.call()))
			_goal = now.grade
			_local_goal = now.local_light
			_sample_in = 0.75
		if not _initialized:
			_initialized = true
			grade = _goal
			local_light = _local_goal
			return
		var step := 1.0 - exp(-clampf(delta, 0.0, 0.25) * 2.0)
		grade = grade.lerp(_goal, step)
		local_light = lerpf(local_light, _local_goal, step)


## Shared cheap 2-D light spill: no image asset, post-processing, or occluders.
static func radial_falloff() -> GradientTexture2D:
	var falloff := Gradient.new()
	falloff.offsets = PackedFloat32Array([0.0, 0.36, 1.0])
	falloff.colors = PackedColorArray([Color(1, 1, 1, 0.8), Color(1, 1, 1, 0.24), Color(1, 1, 1, 0.0)])
	var glow := GradientTexture2D.new()
	glow.width = 64
	glow.height = 64
	glow.gradient = falloff
	glow.fill = GradientTexture2D.FILL_RADIAL
	glow.fill_from = Vector2(0.5, 0.5)
	glow.fill_to = Vector2(1.0, 0.5)
	return glow


## The light's origin never moves. x is brightness, y is the receiving
## footprint's angle. Keep effects smooth and nonzero, never blink on/off.
static func fixture_motion(kind: String, seconds: float, phase: float = 0.0) -> Vector2:
	match kind:
		"heat":
			return Vector2(0.88 + 0.11 * sin(seconds * 4.7 + phase) + 0.07 * sin(seconds * 2.3 + phase), 0.0)
		"search":
			return Vector2(0.96 + 0.04 * cos(seconds * TAU / 12.0 + phase), 0.24 * sin(seconds * TAU / 12.0 + phase))
		"lantern":
			return Vector2(0.95 + 0.04 * sin(seconds * 2.1 + phase) + 0.028 * sin(seconds * 3.8 + phase), 0.0)
	return Vector2(1.0, 0.0)


static func local_minute() -> float:
	var t := Time.get_time_dict_from_system()
	return float(t.hour) * 60.0 + float(t.minute) + float(t.second) / 60.0


static func palette(minute_of_day: float) -> Dictionary:
	var minute := fposmod(minute_of_day, 1440.0)
	for i in range(KEYS.size() - 1):
		var a: Array = KEYS[i]
		var b: Array = KEYS[i + 1]
		if minute <= float(b[0]):
			var t := smoothstep(float(a[0]), float(b[0]), minute)
			var begin: Color = a[1]
			var end: Color = b[1]
			return {"grade": begin.lerp(end, t), "local_light": lerpf(a[2], b[2], t)}
	return {"grade": Color.WHITE, "local_light": 0.10}