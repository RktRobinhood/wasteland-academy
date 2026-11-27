class_name AmbientLayer
extends Control
## The moving things on a board (FAL-1075): crows, a beacon, smoke, neon, dust. Ported
## from The Unruly Atlas's ambient_sprites.gd, with only the parts this game's pack uses.
## map.gd puts one on the world board, between the painting and the zone buttons; it
## takes no taps (mouse_filter ignore), so every press reaches the button under it.
## build() takes a list of entries (data/ambient.json's "map"). Each entry:
##
##   {"id": "crow", "sheet": "crow", "position": [-50, 235], "anchor": [36, 22],
##    "scale": 1.0, "fps": 10, "frames": "cycle", "motion": "path",
##    "path": [[300, 175], [700, 215]], "seconds": 14, "loop": false, "face": "flip"}
##
##   id        unique on its board; also the node's name
##   sheet     assets/ambient/<sheet>-sheet.png, cut by the <sheet>-sheet.json beside it
##             (TexturePacker frames, played in name order)
##   position  board pixels; the anchor sits here
##   anchor    the point in a cell (cell pixels) that sits on position (default [0, 0])
##   scale     of a cell (default 1.0: the cells are drawn at board pixels)
##   fps       frames a second (default: from the sheet's frame durations)
##   frames    still, cycle or blink (hold frame 0 for 2-4 s, show frame 1 for 0.15 s).
##             Default cycle
##   motion    none, bob (6 px up and down), sway (amount deg, period s), drift (to
##             "to" and back over seconds), path (a loop through position and path
##             over seconds; "loop": false goes there and back), pulse (scale 0.6-1 and
##             fade over period), rise (up by amount px over seconds, growing and
##             fading, like steam)
##   bob       px of bobbing at bob_period s (default 2.5), on top of any motion
##   face      flip: flip_h when moving left
##   phase     0-1, shifts the timing so pieces don't restart together
##   alpha     opacity (default 1)
##   still     with reduced motion, the frame (0-based) held still; without it the
##             piece is hidden
##   stir      true to let pointer movement past this piece gently turn its anchored
##             sprite. The position and anchor must meet at the painted emitter.
##
## With reduced motion (set before build()) nothing moves: each piece holds its still
## frame at its position, or is hidden. check() validates a list; the tests run it.

const SHEETS := "res://assets/ambient/"
const MOTIONS: Array[String] = ["none", "bob", "sway", "drift", "path", "pulse", "rise"]
const FRAME_MODES: Array[String] = ["still", "cycle", "blink"]
## How far past the board's edge a position may sit (a crow flies in from off-screen).
const EDGE := 200.0
const STIR_REACH := 18.0 # Cell pixels just beyond the sprite.
const STIR_LIMIT := 0.20944 # About 12 degrees, never applied to the scenery.
const STIR_PULSE := 0.13
const STIR_TRAVEL := 32.0 # Cell pixels to turn a resting plume to the limit.
const STIR_REST := 0.001

## Hold every piece still (or hide it), including an impulse already on screen.
var reduced_motion := false:
	set(value):
		if reduced_motion == value:
			return
		reduced_motion = value
		if value:
			_reset_stir()
			for t in things:
				_hold_still(t)
		else:
			for t in things:
				t["holder"].show()
			_update(0.0)
		_refresh_activity()
## Seconds since build().
var time := 0.0
## One Dictionary per piece; see _make().
var things: Array[Dictionary] = []
var _stirrers: Array[Dictionary] = []
var _animate_ambient := false
var _stirring := false

## Sheets already cut into frames, by sheet name.
static var _cut := {}


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func _ready() -> void:
	_refresh_activity()


func _notification(what: int) -> void:
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if not is_visible_in_tree():
			_reset_stir()
		_refresh_activity()


## A data file (data/ambient.json) read whole, or {} if it is missing or not an object.
static func data(path: String) -> Dictionary:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return {}
	var d = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}


## The entries under `key` in a data file (data/ambient.json's "map"), or [] if missing.
static func entries(path: String, key: String) -> Array:
	var list = data(path).get(key, [])
	return list if list is Array else []


## True when nothing should move: the save's reduced-motion setting, or the browser's
## prefers-reduced-motion on the web. The map and the fight screen both ask here.
static func motion_reduced(save: Dictionary) -> bool:
	if bool(save.get("settings", {}).get("reduced_motion", false)):
		return true
	if OS.has_feature("web"):
		return JavaScriptBridge.eval("window.matchMedia('(prefers-reduced-motion: reduce)').matches", true) == true
	return false


## The frames of assets/ambient/<sheet>-sheet.png, cut by its JSON frame map in name
## order, or [] if either file is missing.
static func frames(sheet: String) -> Array[Texture2D]:
	if _cut.has(sheet):
		return _cut[sheet]
	var out: Array[Texture2D] = []
	var png := SHEETS + sheet + "-sheet.png"
	var map := _frame_map(sheet)
	if ResourceLoader.exists(png) and not map.is_empty():
		var tex: Texture2D = load(png)
		var names: Array = map.keys()
		names.sort()
		for n in names:
			var r: Dictionary = map[n].get("frame", {})
			var a := AtlasTexture.new()
			a.atlas = tex
			a.region = Rect2(float(r.get("x", 0)), float(r.get("y", 0)), float(r.get("w", 0)), float(r.get("h", 0)))
			out.append(a)
	_cut[sheet] = out
	return out


## A sheet's frames a second, from its JSON's frame durations (ms), or 0 with none.
static func sheet_fps(sheet: String) -> float:
	var map := _frame_map(sheet)
	if map.is_empty():
		return 0.0
	var ms := 0.0
	for n in map:
		ms += float(map[n].get("duration", 0))
	return 1000.0 * map.size() / ms if ms > 0.0 else 0.0


static func _frame_map(sheet: String) -> Dictionary:
	var f := FileAccess.open(SHEETS + sheet + "-sheet.json", FileAccess.READ)
	if f == null:
		return {}
	var data = JSON.parse_string(f.get_as_text())
	return data.get("frames", {}) if data is Dictionary and data.get("frames", {}) is Dictionary else {}


## Replaces the pieces with the ones in list.
func build(list: Array) -> void:
	for c in get_children():
		remove_child(c)
		c.queue_free()
	things = []
	_stirrers = []
	_animate_ambient = false
	_stirring = false
	time = 0.0
	for e in list:
		if e is Dictionary:
			var t := _make(e)
			if not t.is_empty():
				things.append(t)
				if t.has("stir_pivot"):
					_stirrers.append(t)
				_animate_ambient = _animate_ambient or t["moves"] or (t["mode"] != "still" and t["frames"].size() > 1)
	_update(0.0)
	_refresh_activity()


func _refresh_activity() -> void:
	var active := is_inside_tree() and is_visible_in_tree() and not reduced_motion
	set_process(active and (_animate_ambient or _stirring))
	set_process_input(active and not _stirrers.is_empty())


func _process(delta: float) -> void:
	if reduced_motion or not is_visible_in_tree():
		return
	if _animate_ambient:
		time += delta
		_update(delta)
	if _stirring:
		_settle_stir(delta)


## Watch only motion, never mark the event handled. Real mouse and touch drag get
## the same passive effect; button presses, taps and touch-emulated mouse are ignored.
func _input(event: InputEvent) -> void:
	if reduced_motion or not is_visible_in_tree():
		return
	if not (event is InputEventMouseMotion or event is InputEventScreenDrag):
		return
	if event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	var at: Vector2 = event.position
	var travel: Vector2 = event.relative
	if travel.is_zero_approx():
		return
	for t in _stirrers:
		var stem: Node2D = t["spinner"]
		var sprite: Sprite2D = t["sprite"]
		var inverse := stem.get_global_transform_with_canvas().affine_inverse()
		var local_at := inverse * at
		var local_travel := inverse.basis_xform(travel)
		var reach := sprite.get_rect().grow(STIR_REACH)
		# Check the swept path as well as the endpoints: fast passes may skip the
		# whole plume between motion events, especially on a reduced-size board.
		if not _passes(reach, local_at - local_travel, local_at):
			continue
		var push := (local_travel.x + local_travel.y * 0.24) / STIR_TRAVEL
		if absf(push) < 0.001:
			continue
		t["stir_target"] = clampf(float(t["stir_target"]) + STIR_LIMIT * push, -STIR_LIMIT, STIR_LIMIT)
		t["stir_hold"] = STIR_PULSE
		if not _stirring:
			_stirring = true
			_refresh_activity()


static func _passes(rect: Rect2, from: Vector2, to: Vector2) -> bool:
	if rect.has_point(from) or rect.has_point(to):
		return true
	var a := rect.position
	var b := Vector2(rect.end.x, a.y)
	var c := rect.end
	var d := Vector2(a.x, c.y)
	return (
		Geometry2D.segment_intersects_segment(from, to, a, b) != null
		or Geometry2D.segment_intersects_segment(from, to, b, c) != null
		or Geometry2D.segment_intersects_segment(from, to, c, d) != null
		or Geometry2D.segment_intersects_segment(from, to, d, a) != null
	)


func _settle_stir(delta: float) -> void:
	var awake := false
	for t in _stirrers:
		var pivot: Node2D = t["stir_pivot"]
		var target: float = t["stir_target"]
		var hold: float = t["stir_hold"]
		var elapsed := minf(delta, hold)
		if elapsed > 0.0:
			pivot.rotation = lerpf(pivot.rotation, target, 1.0 - exp(-21.0 * elapsed))
			hold -= elapsed
			t["stir_hold"] = hold
			if hold <= 0.0:
				t["stir_target"] = 0.0
		if hold <= 0.0:
			pivot.rotation *= exp(-8.0 * (delta - elapsed))
		if hold <= 0.0 and absf(pivot.rotation) < STIR_REST:
			pivot.rotation = 0.0
		else:
			awake = true
	_stirring = awake
	if not awake:
		_refresh_activity()


func _reset_stir() -> void:
	for t in _stirrers:
		t["stir_pivot"].rotation = 0.0
		t["stir_target"] = 0.0
		t["stir_hold"] = 0.0
	_stirring = false


func thing(id: String) -> Dictionary:
	for t in things:
		if t["id"] == id:
			return t
	return {}


## Problems with a list: unknown sheets, motions or frame modes, a still frame out of
## range, and positions or path points far outside the board (board_size, in pixels).
static func check(list: Array, board_size: Vector2, label := "") -> PackedStringArray:
	var problems: PackedStringArray = []
	var ids := {}
	var bounds := Rect2(Vector2.ZERO, board_size).grow(EDGE)
	for e in list:
		if not e is Dictionary:
			problems.append("%s: an entry is not an object" % label)
			continue
		var id := str(e.get("id", ""))
		var where := "%s piece %s" % [label, id]
		if id == "" or ids.has(id):
			problems.append("%s: missing or repeated id" % where)
		ids[id] = true
		var n := frames(str(e.get("sheet", ""))).size()
		if n == 0:
			problems.append("%s: no sheet %s in %s" % [where, e.get("sheet", ""), SHEETS])
		if not MOTIONS.has(str(e.get("motion", "none"))):
			problems.append("%s: unknown motion %s" % [where, e.get("motion")])
		if e.has("frames") and not FRAME_MODES.has(str(e["frames"])):
			problems.append("%s: unknown frames %s" % [where, e["frames"]])
		if e.has("stir") and not (e["stir"] is bool):
			problems.append("%s: stir must be true or false" % where)
		if e.has("still") and (int(e["still"]) < 0 or int(e["still"]) >= n):
			problems.append("%s: still frame %s is not one of its %d" % [where, e["still"], n])
		var points := points_of(e)
		if points.is_empty():
			problems.append("%s: no position" % where)
		for p in points:
			if not bounds.has_point(p):
				problems.append("%s: %s is outside the %dx%d board" % [where, p, board_size.x, board_size.y])
		if str(e.get("motion", "")) == "path" and _vecs(e.get("path", [])).is_empty():
			problems.append("%s: a path motion needs a path" % where)
		if str(e.get("motion", "")) == "drift" and not e.has("to"):
			problems.append("%s: a drift needs a \"to\" point" % where)
	return problems


## Every board point an entry names: its position, then to and path.
static func points_of(e: Dictionary) -> PackedVector2Array:
	var out := PackedVector2Array()
	var pos = e.get("position", null)
	if pos is Array and pos.size() == 2:
		out.append(Vector2(float(pos[0]), float(pos[1])))
	else:
		return out
	if e.has("to"):
		out.append_array(_vecs([e["to"]]))
	out.append_array(_vecs(e.get("path", [])))
	return out


static func _vecs(list) -> PackedVector2Array:
	var out := PackedVector2Array()
	if list is Array:
		for p in list:
			if p is Array and p.size() == 2:
				out.append(Vector2(float(p[0]), float(p[1])))
	return out


# --- building ---------------------------------------------------------------------------


## holder (position, scale, flip) > spinner (sway) > optional stir pivot > Sprite2D.
## The sprite's authored anchor stays fixed at the origin of both rotators.
func _make(e: Dictionary) -> Dictionary:
	var sheet := str(e.get("sheet", ""))
	var cells := frames(sheet)
	var points := points_of(e)
	if cells.is_empty() or points.is_empty():
		return {}
	var id := str(e.get("id", sheet))
	var holder := Node2D.new()
	holder.name = id
	add_child(holder)
	var spinner := Node2D.new()
	holder.add_child(spinner)
	var sprite := Sprite2D.new()
	sprite.centered = false
	var anchor := _vecs([e.get("anchor", [0, 0])])
	sprite.offset = -anchor[0] if not anchor.is_empty() else Vector2.ZERO
	sprite.texture = cells[0]
	var pivot: Node2D
	if e.get("stir", false) is bool and e.get("stir", false):
		pivot = Node2D.new()
		spinner.add_child(pivot)
		pivot.add_child(sprite)
	else:
		spinner.add_child(sprite)
	var mode := str(e.get("frames", "cycle"))
	if not FRAME_MODES.has(mode):
		mode = "cycle"
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(id + sheet)
	var t := {
		"id": id,
		"data": e,
		"holder": holder,
		"spinner": spinner,
		"sprite": sprite,
		"frames": cells,
		"frame": 0,
		"mode": mode,
		"fps": float(e.get("fps", sheet_fps(sheet) if sheet_fps(sheet) > 0.0 else 6.0)),
		"motion": str(e.get("motion", "none")),
		"base": points[0],
		"scale": float(e.get("scale", 1.0)),
		"facing": 1.0,
		"alpha": float(e.get("alpha", 1.0)),
		"rng": rng,
		"timer": rng.randf_range(0.0, 2.0),
		"phase": float(e.get("phase", rng.randf())),
		"track": PackedVector2Array(),
		"track_at": PackedFloat32Array(),
		"track_len": 0.0,
	}
	if pivot != null:
		t["stir_pivot"] = pivot
		t["stir_target"] = 0.0
		t["stir_hold"] = 0.0
	# A piece with no motion and no bob is placed once, in build(), not every frame.
	t["moves"] = t["motion"] != "none" or float(e.get("bob", 0.0)) != 0.0
	if t["motion"] == "path":
		var pts := PackedVector2Array([points[0]])
		pts.append_array(_vecs(e.get("path", [])))
		var loop: bool = e.get("loop", true)
		t["track"] = _smooth(pts, loop)
		if not loop:
			var back: PackedVector2Array = t["track"].duplicate()
			back.reverse()
			t["track"].append_array(back.slice(1))
		t["track_at"] = _distances(t["track"])
		t["track_len"] = t["track_at"][-1]
	if reduced_motion:
		_hold_still(t)
	return t


## Reduced motion: the entry's still frame at its position, or hidden.
func _hold_still(t: Dictionary) -> void:
	var e: Dictionary = t["data"]
	var holder: Node2D = t["holder"]
	holder.visible = e.has("still")
	t["frame"] = clampi(int(e.get("still", 0)), 0, t["frames"].size() - 1)
	t["sprite"].texture = t["frames"][t["frame"]]
	t["spinner"].rotation = 0.0
	holder.position = t["base"]
	holder.scale = Vector2.ONE * t["scale"]
	holder.modulate.a = t["alpha"]


# --- playing ----------------------------------------------------------------------------


func _update(delta: float) -> void:
	if reduced_motion:
		return
	for t in things:
		_play_frames(t, delta)
		if t["moves"] or delta == 0.0:
			_play_motion(t)


func _play_frames(t: Dictionary, delta: float) -> void:
	var cells: Array[Texture2D] = t["frames"]
	var n := cells.size()
	var rng: RandomNumberGenerator = t["rng"]
	match t["mode"]:
		"cycle":
			t["frame"] = int((time + t["phase"] * 10.0) * t["fps"]) % n
		"blink":
			t["timer"] -= delta
			if t["timer"] <= 0.0:
				if t["frame"] == 0 and n > 1:
					t["frame"] = 1
					t["timer"] = 0.15
				else:
					t["frame"] = 0
					t["timer"] = rng.randf_range(2.0, 4.0)
		_:
			t["frame"] = 0
	var sprite: Sprite2D = t["sprite"]
	if sprite.texture != cells[t["frame"]]:
		sprite.texture = cells[t["frame"]]


func _play_motion(t: Dictionary) -> void:
	var e: Dictionary = t["data"]
	var holder: Node2D = t["holder"]
	var base: Vector2 = t["base"]
	var pos := base
	var rot := 0.0
	var grow := 1.0
	var alpha: float = t["alpha"]
	var period := maxf(float(e.get("period", 3.0)), 0.05)
	var seconds := maxf(float(e.get("seconds", 10.0)), 0.05)
	var phase: float = t["phase"]
	var turn_to := Vector2.ZERO
	match t["motion"]:
		"sway":
			rot = deg_to_rad(float(e.get("amount", 5.0))) * sin(TAU * (time / period + phase))
		"drift":
			var to: Vector2 = _vecs([e["to"]])[0]
			var u := TAU * (time / seconds + phase)
			pos = base.lerp(to, 0.5 - 0.5 * cos(u))
			turn_to = (to - base) * sin(u)
		"path":
			var track: PackedVector2Array = t["track"]
			var at: PackedFloat32Array = t["track_at"]
			var d: float = fposmod(time / seconds + phase, 1.0) * t["track_len"]
			pos = _point_at(track, at, d)
			turn_to = _point_at(track, at, fposmod(d + 6.0, t["track_len"])) - pos
		"pulse":
			var k := 0.5 - 0.5 * cos(TAU * (time / period + phase))
			grow = lerpf(0.6, 1.0, k)
			alpha *= k
		"rise":
			var u := fposmod(time / seconds + phase, 1.0)
			pos += Vector2(sin(u * TAU) * 6.0, -float(e.get("amount", 100.0)) * u)
			grow = lerpf(0.5, 1.2, u)
			alpha *= pow(sin(PI * u), 0.8)
	var bob := float(e.get("bob", 6.0 if t["motion"] == "bob" else 0.0))
	if bob != 0.0:
		pos.y += sin(TAU * (time / maxf(float(e.get("bob_period", 2.5)), 0.05) + phase)) * bob
	if str(e.get("face", "")) == "flip" and absf(turn_to.x) > 0.01:
		t["facing"] = 1.0 if turn_to.x > 0.0 else -1.0
	holder.position = pos
	holder.scale = Vector2(t["facing"], 1.0) * t["scale"] * grow
	holder.modulate.a = alpha
	t["spinner"].rotation = rot


# --- one-shot effects -------------------------------------------------------------------


## Plays a sheet once at `at` (parent's pixels) with its anchor there, then frees it: a
## fight's hit spark or dust burst. Returns the node, or null when the sheet is missing.
static func play_once(parent: Node, sheet: String, at: Vector2, anchor: Vector2, scale: float,
		fps: float = 0.0) -> Node2D:
	var cells := frames(sheet)
	if cells.is_empty():
		return null
	var once := OneShot.new()
	once.name = sheet
	once.cells = cells
	once.fps = fps if fps > 0.0 else maxf(sheet_fps(sheet), 1.0)
	once.position = at
	once.scale = Vector2.ONE * scale
	once.centered = false
	once.offset = -anchor
	once.texture = cells[0]
	parent.add_child(once)
	return once


class OneShot extends Sprite2D:
	var cells: Array[Texture2D] = []
	var fps := 12.0
	var time := 0.0

	func _process(delta: float) -> void:
		time += delta
		var i := int(time * fps)
		if i >= cells.size():
			queue_free()
			return
		texture = cells[i]


# --- geometry ---------------------------------------------------------------------------


## A Catmull-Rom curve through pts, sampled about every 6 px; closed when loop.
static func _smooth(pts: PackedVector2Array, loop: bool) -> PackedVector2Array:
	var out := PackedVector2Array()
	var n := pts.size()
	if n < 2:
		return pts
	var count := n if loop else n - 1
	for i in count:
		var p0 := pts[(i - 1 + n) % n] if loop else pts[maxi(i - 1, 0)]
		var p1 := pts[i]
		var p2 := pts[(i + 1) % n]
		var p3 := pts[(i + 2) % n] if loop else pts[mini(i + 2, n - 1)]
		var steps := maxi(2, int(p1.distance_to(p2) / 6.0))
		for k in steps:
			var s := float(k) / steps
			out.append(0.5 * ((2.0 * p1) + (p2 - p0) * s + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * s * s \
				+ (3.0 * p1 - p0 - 3.0 * p2 + p3) * s * s * s))
	out.append(pts[0] if loop else pts[-1])
	return out


## How far along pts each point is, from 0 to the whole length.
static func _distances(pts: PackedVector2Array) -> PackedFloat32Array:
	var out := PackedFloat32Array([0.0])
	for i in range(1, pts.size()):
		out.append(out[-1] + pts[i - 1].distance_to(pts[i]))
	return out


## The point dist along pts, found by a binary search of _distances(pts): one lookup a
## frame, not a walk of the whole track (FAL-1075 measured the walk on a slow phone).
static func _point_at(pts: PackedVector2Array, at: PackedFloat32Array, dist: float) -> Vector2:
	if pts.is_empty():
		return Vector2.ZERO
	var i := clampi(at.bsearch(maxf(dist, 0.0)), 1, pts.size() - 1)
	var seg := at[i] - at[i - 1]
	return pts[i - 1].lerp(pts[i], clampf((dist - at[i - 1]) / seg, 0.0, 1.0)) if seg > 0.0 else pts[i]
