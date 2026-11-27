class_name WorldLight
extends RefCounted
## Stylized device-local light for the artwork only. No geography, network,
## saved preference, or effect on a question, encounter seed or route.
## One cyclic set of keys shared by boards and battle scenery.

# Minute of day, flat-art grade, and intensity for small in-world light sources.
const KEYS := [
	[0.0, Color(0.47, 0.53, 0.72), 1.0],
	[300.0, Color(0.47, 0.53, 0.72), 1.0],
	[360.0, Color(0.82, 0.62, 0.65), 0.78],
	[420.0, Color(1.0, 0.82, 0.66), 0.39],
	[510.0, Color.WHITE, 0.10],
	[960.0, Color.WHITE, 0.10],
	[1080.0, Color(1.0, 0.74, 0.59), 0.41],
	[1140.0, Color(0.79, 0.53, 0.62), 0.76],
	[1230.0, Color(0.47, 0.53, 0.72), 1.0],
	[1440.0, Color(0.47, 0.53, 0.72), 1.0],
]


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