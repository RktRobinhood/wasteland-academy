class_name JourneyStage
extends Control
## The journey strip (FAL-331, plan on FAL-289): a band of side-view scene above the
## question card. The Learner walks right with Spark beside them over the region's
## parallax, and each answer plays out as a beat: Explore, Puzzle, Fight or Boss.
##
## View only. The run calls the methods below and never reads anything back; nothing
## here can delay a question or take input (mouse_filter is IGNORE). Call them with
## call_deferred() (see JourneyDemoRun.notify()), so even a script error in here can't
## reach the run.
##
##   start_run(region, avatar, weapon, seed)   hides the strip if the avatar has no sheet
##   fight_started(fight, tier, questions)      tier 1-5, or 0 if the run has none yet
##   question_opened(index)                     calm: whatever is playing jumps to its end
##   answer_resolved(outcome, info)             right, wrong, timeout, late or partial
##   fight_ended()                              victory or retreat, then walk on
##   run_ended()
##   set_weapon(name)                           cosmetic; the Learner isn't redrawn
##
## Everything is drawn in _draw() from a timeline of segments (a walk, a walk-in, one
## beat per answer), in strip units: the band is H units tall and as wide as it needs
## to be, with the action centred in a 360-unit window. The beat timings are the
## FAL-293 reel's (_scratch/FAL-293/tools/reel.py).

const H := 200.0
const ACTION_W := 360.0
const LX := 112.0              # the Learner's feet x
const SX := 54.0               # Spark's
const SLOTS := [214.0, 262.0, 314.0]   # monster feet x, front to back
const WALK_FPS := 12.0
const APPROACH := 2.6          # the walk that brings an encounter into view
const ENTER := 1.6             # monsters walking in
const LAYER_K := {"far": 1.0, "mid": 0.5, "near": 0.62}
const FLASH := 0.08            # one white flash per hit, 80 ms
const FLASH_GLOW := 0.55
const FLASH_PER_SECOND := 3
const BREATH := 2.4            # idle breathing period, scale 1 to 1.02
## Display heights in strip units (the README's preview heights; the Learner is 92).
const DISP := {"spark": 56, "loot": 14, "dishback": 56, "scrap-pile": 64, "mud-stuck": 52, "hatch-locked": 58,
		"vault-dials": 104, "cache-vending": 96, "obstacle-livewire": 58}
const ENEMY_H := {1: 80, 2: 92, 3: 104, 4: 108, 5: 124}
const LEARNER_H := 92.0
## Learner pose for each prop's job; anything else works with `work`.
const HEAVE_PROPS := ["mud-stuck"]
const TEAL := Color8(34, 211, 197)
const MAGENTA := Color8(255, 61, 167)
const DUST := Color8(234, 203, 116)
const MINT := Color8(159, 240, 230)
const RED := Color8(255, 72, 72)
const SLASH := {"rebar": TEAL, "neon-blade": MAGENTA, "antenna-spear": MINT}
const LOOT_IDS := ["bolt", "cell", "gear", "crystal", "tube", "cap"]
const FONT := preload("res://assets/fonts/bangers-latin.woff2")

static var _shared: JourneyAssets

var assets: JourneyAssets
## Swap poses only and stop the scroll.
var reduced_motion := false
## Test hook: every animation fails (nothing is planned or drawn).
var fail_animations := false
## False until start_run() finds the avatar's sheet. The strip is hidden while false.
var active := false
## Advance the clock in _process. Tests turn it off and call advance().
var auto_clock := true

var region := ""
var avatar := ""
var weapon := "rebar"
var run_seed := 0
var question_open := false
var encounter := {}          # the JourneyBeats encounter playing now
var clock := 0.0
## Times a flash was drawn (tests read it).
var flashes: Array[float] = []

var _roster := {}
var _ground := 160.0
var _layers: Array = []      # {tex, scroll, y, w, h}
var _speed := 0.0            # ground speed, strip units per second
var _queue: Array = []
var _seg := {}
var _cam := 0.0              # the camera after every queued segment
var _monsters: Array = []    # alive, front to back: {sheet, hits, stage, stages, done}
var _props: Array = []       # in the world: {name, x, state, progress, steps}
var _answered := 0
var _flash_times: Array[float] = []
var _flash_on := false
var _state := {}


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	clip_contents = true


func _ready() -> void:
	visible = active


func _process(delta: float) -> void:
	if auto_clock:
		advance(delta)


## The journey sheets, scanned once and shared by every strip.
static func shared_assets() -> JourneyAssets:
	if _shared == null:
		_shared = JourneyAssets.scan()
	return _shared


# ------------------------------------------------------------------ the run's calls

func start_run(p_region: String, p_avatar: String, p_weapon: String = "rebar", p_seed: int = 0) -> void:
	if fail_animations:
		return
	if assets == null:
		assets = shared_assets()
	region = p_region
	avatar = p_avatar
	run_seed = p_seed
	weapon = p_weapon if assets.weapons.has(p_weapon) else "rebar"
	active = assets.has_avatar(avatar)
	visible = active
	_queue.clear()
	_seg = {}
	_monsters.clear()
	_props.clear()
	encounter = {}
	question_open = false
	_cam = 0.0
	_roster = assets.roster(region)
	_build_layers()
	var lh: float = LEARNER_H
	_speed = 36.0 / 880.0 * lh * WALK_FPS
	if active:
		_push({"kind": "travel", "d": INF})
	queue_redraw()


func fight_started(fight: int, tier: int = 0, questions: int = 3, override: Dictionary = {}) -> void:
	if not _live():
		return
	_cut_travel()
	_finish_encounter_props()
	encounter = override.duplicate(true) if not override.is_empty() else JourneyBeats.encounter(run_seed, fight, tier, _roster, questions)
	if override.has("kind"):
		var base := {"tier": maxi(1, tier), "fight": fight, "questions": questions, "prop": "", "group": [],
				"hits": [], "ambush": false, "stages": 1}
		base.merge(encounter, true)
		encounter = base
		if encounter.hits.is_empty() and not encounter.group.is_empty():
			encounter.hits = JourneyBeats._hits(encounter.group.size(), questions)
	_answered = 0
	_monsters.clear()
	for i in encounter.group.size():
		var sh: String = encounter.group[i]
		if assets.sheets.has(sh):
			var st: int = assets.sheets[sh].stages.size() if encounter.kind == "boss" else 1
			_monsters.append({"sheet": sh, "hits": int(encounter.hits[i]), "total": int(encounter.hits[i]),
					"stage": 0, "stages": maxi(1, st)})
	if _monsters.is_empty() and encounter.kind in ["fight", "boss"]:
		encounter.kind = "travel"
	var after := _cam + _speed * APPROACH
	if encounter.kind in ["explore", "puzzle"] and assets.sheets.has(encounter.prop):
		var w := _prop_half_w(encounter.prop)
		_props.append({"name": encounter.prop, "x": after + LX + 64.0 + w, "state": "start", "progress": 0,
				"steps": int(encounter.questions), "temp": ""})
	_push({"kind": "travel", "d": APPROACH})
	if not _monsters.is_empty():
		_push({"kind": "enter", "d": ENTER, "ambush": encounter.ambush})


func question_opened(_index: int = 0) -> void:
	if not _live():
		return
	_skip_to_rest()
	question_open = true


func answer_resolved(outcome: String, info: Dictionary = {}) -> void:
	if not _live():
		return
	question_open = false
	if encounter.is_empty() or encounter.kind == "travel":
		return
	_answered += 1
	var final := _answered >= int(encounter.questions)
	var good := outcome in ["right", "late", "partial"]
	var glance := outcome in ["late", "partial"]
	var cost := int(info.get("damage", JourneyBeats.MISS_COST.get(int(encounter.tier), 15)))
	if glance and not info.has("damage"):
		cost = ceili(cost / 2.0)
	if encounter.kind in ["fight", "boss"]:
		if _monsters.is_empty():
			return
		if good:
			var m: Dictionary = _monsters[0]
			var seg := {"kind": "strike", "d": 1.9, "glance": glance, "hit": 20 * int(encounter.tier)}
			m.hits -= 1
			var done: int = m.total - m.hits
			var stage := mini(m.stages - 1, done * m.stages / maxi(1, m.total))
			seg.kills = m.hits <= 0
			seg.stage_to = stage if stage > m.stage and not seg.kills else -1
			_push(seg)
			if seg.stage_to >= 0:
				m.stage = stage
			if seg.kills:
				_monsters.pop_front()
		else:
			_push({"kind": "struck", "d": 1.3, "cost": cost})
	else:
		var p: Dictionary = _props[-1] if not _props.is_empty() else {}
		if p.is_empty():
			return
		var sheet: Dictionary = assets.sheets[p.name]
		if good:
			var seg := {"kind": "work", "d": 1.6, "glance": glance, "final": final, "cost": cost,
					"loot": final and encounter.kind == "explore" and p.state != "cleared"}
			_push(seg)
			p.progress = mini(p.steps, p.progress + 1)
			if final:
				p.state = "cleared"
		else:
			var miss := ""
			if sheet.states.has("failed"):
				miss = "failed"
			elif final and sheet.states.has("empty"):
				miss = "empty"
			elif sheet.states.has("mimic"):
				miss = "mimic"
			_push({"kind": "slip", "d": 1.3, "cost": cost, "miss": miss, "final": final})
			if final and miss in ["failed", "empty"]:
				p.state = miss


func fight_ended() -> void:
	if not _live():
		return
	if not _monsters.is_empty():
		_push({"kind": "retreat", "d": 1.2})
		_monsters.clear()
	elif encounter.kind in ["fight", "boss"]:
		_push({"kind": "victory", "d": 2.3, "loot": true})
	elif not _props.is_empty() and _props[-1].state == "cleared":
		_push({"kind": "victory", "d": 1.2, "loot": false})
	encounter = {}
	_push({"kind": "travel", "d": INF})


func run_ended() -> void:
	if not _live():
		return
	_cut_travel()
	encounter = {}
	_monsters.clear()
	_push({"kind": "travel", "d": INF})


func set_weapon(p_weapon: String, show_swap: bool = true) -> void:
	if not _live() or not assets.weapons.has(p_weapon) or p_weapon == weapon:
		return
	if show_swap:
		_cut_travel()
		_push({"kind": "swap", "d": 1.9, "from": weapon, "to": p_weapon})
	weapon = p_weapon


# ------------------------------------------------------------------ the clock

func advance(dt: float) -> void:
	if not _live():
		return
	clock += dt
	while true:
		if _seg.is_empty():
			if _queue.is_empty():
				break
			_begin(_queue.pop_front(), clock)
		var end: float = _seg.t0 + _seg.d
		if clock < end:
			break
		_seg = {}
		if not _queue.is_empty():
			_begin(_queue.pop_front(), end)
	_state = _compose()
	var lit: bool = _state.flash
	if lit and not _flash_on:
		flashes.append(clock)
	_flash_on = lit
	queue_redraw()


## What is on screen now, for tests: each sprite's anim, whether anything flashes, the
## code effects and the camera.
func snapshot() -> Dictionary:
	if _state.is_empty():
		return {"anims": [], "flash": false, "fx": [], "cam": 0.0, "sprites": []}
	var sprites: Array = [_state.learner, _state.spark] + _state.enemies + _state.props
	return {"anims": sprites.map(func(s): return s.anim), "flash": _state.flash,
			"fx": _state.fx.map(func(f): return f.k), "cam": _state.cam, "sprites": sprites}


func _live() -> bool:
	return active and not fail_animations


func _push(seg: Dictionary) -> void:
	seg.cam0 = _cam
	if seg.kind == "travel" and seg.d != INF:
		_cam += _speed * seg.d
	seg.monsters = _monsters.map(func(m): return {"sheet": m.sheet, "stage": m.stage})
	if not _props.is_empty():
		var p: Dictionary = _props[-1]
		seg.prop = {"state": p.state, "progress": p.progress}
	_queue.append(seg)


func _begin(seg: Dictionary, t0: float) -> void:
	seg.t0 = t0
	seg.lit = {}
	for off in _flash_offsets(seg):
		var at: float = t0 + off
		var recent := _flash_times.filter(func(f): return at - f < 1.0)
		if recent.size() < FLASH_PER_SECOND:
			seg.lit[off] = true
			_flash_times.append(at)
	_flash_times = _flash_times.filter(func(f): return t0 - f < 2.0)
	_seg = seg


func _flash_offsets(seg: Dictionary) -> Array:
	match seg.kind:
		"strike":
			return [0.42, 1.0] if seg.stage_to >= 0 else [0.42]
		"struck":
			return [0.33]
		"slip":
			return [0.52]
	return []


## Ends an open-ended walk: the camera stops where it is now.
func _cut_travel() -> void:
	if not _seg.is_empty() and _seg.kind == "travel" and _seg.d == INF:
		_seg.d = clock - _seg.t0
		_cam = _seg.cam0 + (0.0 if reduced_motion else _speed * _seg.d)
		_cam = maxf(_cam, _seg.cam0)
		_seg = {}
		_requeue_cams()
	_queue = _queue.filter(func(s): return not (s.kind == "travel" and s.d == INF))


## A walk cut short moved the camera less than planned: re-plan what is queued after it.
func _requeue_cams() -> void:
	var c := _cam
	for s in _queue:
		s.cam0 = c
		if s.kind == "travel" and s.d != INF:
			c += _speed * s.d
	_cam = c


## Calm: a question opened, so whatever is playing jumps to where it would end.
func _skip_to_rest() -> void:
	_cut_travel()
	_seg = {}
	_queue.clear()


## The props of an encounter the party is leaving keep their last state.
func _finish_encounter_props() -> void:
	for p in _props:
		p.temp = ""
	_props = _props.filter(func(p): return p.x - _cam > -200.0)


func _build_layers() -> void:
	_layers.clear()
	_ground = 160.0
	var r: Dictionary = assets.regions.get(region, {})
	for l in r.get("layers", []):
		var tex := assets.texture(l.image)
		if tex == null:
			continue
		var k: float = H / 256.0 * float(LAYER_K.get(l.name, 1.0))
		var w: float = tex.get_width() * k
		var h: float = tex.get_height() * k
		var y := 0.0
		if l.name == "near":
			y = H - h
			_ground = H - h + float(l.feet_y) * k
		_layers.append({"name": l.name, "tex": tex, "scroll": float(l.scroll), "w": w, "h": h, "y": y})
	for l in _layers:
		if l.name == "mid":
			l.y = _ground - 6.0 - l.h


# ------------------------------------------------------------------ composing a frame

func _disp_h(name: String) -> float:
	if name in assets.avatars:
		return LEARNER_H
	if DISP.has(name):
		return float(DISP[name])
	var m := RegEx.create_from_string("^d(\\d)-").search(name)
	if m != null:
		return float(ENEMY_H.get(int(m.get_string(1)), 92))
	return 64.0


func _prop_half_w(name: String) -> float:
	var s: Dictionary = assets.sheets[name]
	var fr: Dictionary = s.by_id.get(s.states.get("start", ""), s.frames[0])
	return float(fr.w) * _disp_h(name) / s.figure_height / 2.0


func _anim_frame(sheet: Dictionary, anim: String, t: float, fallback: String = "") -> String:
	var ids := assets.anim_ids(sheet, anim)
	if ids.is_empty():
		return fallback if fallback != "" else sheet.frames[0].id
	var fps: float = sheet.anims[anim].get("fps", 1)
	var i := int(floor(t * fps))
	if sheet.anims[anim].get("loop", true):
		i = posmod(i, ids.size())
	else:
		i = mini(i, ids.size() - 1)
	return ids[i]


func _sprite(name: String, fid: String, x: float, anim: String) -> Dictionary:
	return {"sheet": name, "fid": fid, "x": x, "home": x, "dy": 0.0, "scale": 1.0, "flash": 0.0, "a": 1.0, "anim": anim}


func _monster_idle(m: Dictionary) -> Array:
	var s: Dictionary = assets.sheets[m.sheet]
	var an := "idle"
	if not s.stages.is_empty():
		an = s.stages[mini(m.stage, s.stages.size() - 1)].get("idle", "idle")
	return [_anim_frame(s, an, 0.0), an]


func _monster_attack(m: Dictionary) -> String:
	var s: Dictionary = assets.sheets[m.sheet]
	var an := "attack"
	if not s.stages.is_empty():
		an = s.stages[mini(m.stage, s.stages.size() - 1)].get("attack", "attack")
	return _anim_frame(s, an, 0.0)


static func _ease(t: float) -> float:
	t = clampf(t, 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)


func _lit(off: float, u: float) -> float:
	return FLASH_GLOW if _seg.lit.has(off) and u >= off and u < off + FLASH else 0.0


func _compose() -> Dictionary:
	var seg := _seg
	var kind: String = seg.get("kind", "rest")
	var u := clock - float(seg.get("t0", clock))
	var t := clock
	var walking: bool = kind == "travel" and not reduced_motion
	var cam: float = seg.get("cam0", _cam)
	if walking:
		cam += _speed * u
	var L := _sprite(avatar, "", LX, "idle")
	var lsheet: Dictionary = assets.sheets[avatar]
	L.fid = _anim_frame(lsheet, "walk", u) if walking else _anim_frame(lsheet, "idle", 0.0)
	L.anim = "walk" if walking else "idle"
	L.weapon = weapon
	if not walking:
		L.scale = 1.0 + 0.01 * (1.0 + sin(t * TAU / BREATH))
	var SP := _sprite(assets.spark, "idle", SX, "idle")
	if walking:
		SP.dy = -1.0 if int(t * 8.0) % 2 == 1 else 0.0
	var st := {"cam": cam, "learner": L, "spark": SP, "enemies": [], "props": [], "fx": [], "flash": false}
	# monsters, front to back: as they were when this segment began, or now if resting
	var ms: Array = seg.get("monsters", _monsters.map(func(m): return {"sheet": m.sheet, "stage": m.stage}))
	if kind == "travel":
		ms = []
	for i in ms.size():
		var m: Dictionary = ms[i]
		var idle := _monster_idle(m)
		var e := _sprite(m.sheet, idle[0], SLOTS[mini(i, SLOTS.size() - 1)], "idle")
		e.m = m
		e.scale = 1.0 + 0.01 * (1.0 + sin(t * PI + i))
		st.enemies.append(e)
	# props in the world
	for j in _props.size():
		var p: Dictionary = _props[j]
		var x: float = p.x - cam
		if x < -160.0 or x > _width() - _action_x() + 160.0:
			continue
		var state: String = p.state
		var progress: int = p.progress
		if j == _props.size() - 1 and seg.has("prop") and kind != "rest":
			state = seg.prop.state
			progress = seg.prop.progress
		var sheet: Dictionary = assets.sheets[p.name]
		var o := _sprite(p.name, sheet.states.get(state, sheet.states.get("start", sheet.frames[0].id)), x, "state")
		o.steps = p.steps
		o.progress = progress
		o.current = j == _props.size() - 1 and not encounter.is_empty()
		st.props.append(o)
	match kind:
		"enter":
			_enter(st, u)
		"strike":
			_strike(st, u)
		"struck":
			_struck(st, u)
		"work":
			_work(st, u)
		"slip":
			_slip(st, u)
		"victory":
			_victory(st, u)
		"retreat":
			_retreat(st, u)
		"swap":
			_swap(st, u)
	for o in st.props:
		if o.current and o.steps > 1:
			st.fx.append({"k": "ticks", "x": o.x, "y": _ground - _disp_h(o.sheet) - 10.0, "n": o.steps, "on": o.progress})
		var dials: Array = assets.sheets[o.sheet].dials
		if o.current and not dials.is_empty() and o.fid == assets.sheets[o.sheet].states.get("start"):
			st.fx.append({"k": "dials", "sprite": o, "dials": dials, "on": o.progress, "spin": o.get("spin", -1.0),
					"buzz": o.get("buzz", 0.0)})
	if reduced_motion:
		_reduce(st)
	for s in [L, SP] + st.enemies + st.props:
		if s.flash > 0.0:
			st.flash = true
	return st


## Reduced motion: every sprite stands at its home, nothing flashes or breathes, and
## only effects that don't move are kept.
func _reduce(st: Dictionary) -> void:
	for s in [st.learner, st.spark] + st.enemies + st.props:
		s.x = s.home
		s.dy = 0.0
		s.scale = 1.0
		s.flash = 0.0
		s.a = 1.0 if s.a >= 0.5 else 0.0
		s.erase("wangle")
	var keep: Array = []
	for f in st.fx:
		if f.k in ["ticks", "dials", "banner"]:
			f.spin = -1.0
			keep.append(f)
		elif f.k == "dmg":
			f.still = true
			keep.append(f)
	st.fx = keep


func _width() -> float:
	return size.x / maxf(0.001, size.y / H) if size.y > 0.0 else ACTION_W


func _action_x() -> float:
	return maxf(0.0, (_width() - ACTION_W) / 2.0)


# ------------------------------------------------------------------ beats (u: seconds in)

func _enter(st: Dictionary, u: float) -> void:
	var right := _width() - _action_x()
	for i in st.enemies.size():
		var e: Dictionary = st.enemies[i]
		var p := _ease(u / (ENTER - 0.2))
		var sheet: Dictionary = assets.sheets[e.sheet]
		if _seg.get("ambush", false):
			var drop := _ease((u - 0.12 * i) / 0.7)
			e.dy = lerpf(-H, 0.0, drop) - (6.0 * sin(PI * clampf((u - 0.12 * i - 0.7) / 0.3, 0.0, 1.0)) if drop >= 1.0 else 0.0)
			if drop < 1.0:
				e.anim = "drop"
			if u > 0.12 * i + 0.7 and u < 0.12 * i + 1.1:
				st.fx.append({"k": "dust", "x": e.x, "p": (u - 0.12 * i - 0.7) / 0.4})
		else:
			e.x = lerpf(right + 30.0 + 50.0 * i, e.home, p)
			if p < 1.0:
				e.fid = _anim_frame(sheet, "walk", u, e.fid)
				e.anim = "walk"
				e.scale = 1.0


func _strike(st: Dictionary, u: float) -> void:
	var L: Dictionary = st.learner
	if st.enemies.is_empty():
		return
	var tgt: Dictionary = st.enemies[0]
	var tsheet: Dictionary = assets.sheets[tgt.sheet]
	var lsheet: Dictionary = assets.sheets[avatar]
	var atk := assets.anim_ids(lsheet, "attack")
	var windup: String = atk[0] if not atk.is_empty() else L.fid
	var strike: String = atk[-1] if not atk.is_empty() else L.fid
	var tx: float = SLOTS[0]
	var reach := tx - 62.0
	var g: float = 0.5 if _seg.glance else 1.0
	if u < 0.22:
		L.x = lerpf(LX, reach, _ease(u / 0.22))
		L.fid = _anim_frame(lsheet, "walk", u * 2.0)
		L.anim = "walk"
		L.scale = 1.0
	elif u < 0.40:
		L.x = reach
		L.fid = windup
		L.anim = "attack"
		L.wangle = lerpf(150.0, 168.0, (u - 0.22) / 0.18)
		L.scale = 1.0
	elif u < 0.80:
		L.x = reach + 6.0
		L.fid = strike
		L.anim = "attack"
		L.scale = 1.0
		L.wangle = lerpf(290.0, 400.0, _ease(minf(1.0, (u - 0.40) / 0.2)))
		if u < 0.66:
			st.fx.append({"k": "slash", "x": tx, "a": 1.0 - (u - 0.40) / 0.26, "col": SLASH.get(weapon, DUST), "s": g})
	elif u < 1.10:
		var p := _ease((u - 0.80) / 0.30)
		L.x = lerpf(reach, LX, p)
		L.dy = -14.0 * sin(PI * p)
	tgt.flash = _lit(0.42, u)
	var later_stage: bool = int(tgt.m.stage) > 0
	if u >= 0.42 and u < 0.95:
		if not later_stage:
			tgt.fid = _anim_frame(tsheet, "hurt", 0.0, tgt.fid)
		tgt.anim = "hurt"
		tgt.x = tx + 6.0 + (3.0 * sin(u * 60.0) if u < 0.72 else 0.0)
		tgt.scale = 1.0
	if _seg.kills and u >= 0.95:
		var p := (u - 0.95) / 0.9
		tgt.fid = _anim_frame(tsheet, "defeated", 0.0, tgt.fid)
		tgt.anim = "defeated"
		tgt.x = tx + 6.0
		tgt.home = tx
		tgt.dy = 12.0 * _ease(p)
		tgt.a = 1.0 - _ease((p - 0.35) / 0.65)
		tgt.scale = 1.0
		for i in range(1, st.enemies.size()):
			var e: Dictionary = st.enemies[i]
			if u > 1.45:
				var q := _ease((u - 1.45) / 0.4)
				e.x = lerpf(SLOTS[i], SLOTS[i - 1], q)
				e.home = SLOTS[i - 1]
				if q < 1.0:
					e.fid = _anim_frame(assets.sheets[e.sheet], "walk", u, e.fid)
					e.anim = "walk"
					e.scale = 1.0
	elif _seg.stage_to >= 0 and u >= 0.95:
		# stage change: flash white, shake, swap to the next stage's idle at the flash peak
		tgt.flash = maxf(tgt.flash, _lit(1.0, u))
		if u < 1.3:
			tgt.x = tx + 4.0 * sin(u * 70.0)
			tgt.anim = "hurt"
		if u >= 1.04:
			var nm: Dictionary = {"sheet": tgt.sheet, "stage": _seg.stage_to}
			tgt.fid = _monster_idle(nm)[0]
	if u >= 0.45 and u < 1.35:
		st.fx.append({"k": "dmg", "x": tx, "p": (u - 0.45) / 0.9, "txt": "-%d" % _seg.hit,
				"col": DUST, "s": g})


func _struck(st: Dictionary, u: float) -> void:
	var L: Dictionary = st.learner
	if not st.enemies.is_empty():
		var e: Dictionary = st.enemies[0]
		var sheet: Dictionary = assets.sheets[e.sheet]
		var ex: float = e.home
		var reach := LX + 66.0
		if u < 0.25:
			e.x = lerpf(ex, reach, _ease(u / 0.25))
			e.fid = _anim_frame(sheet, "walk", u * 2.0, e.fid)
			e.anim = "walk"
			e.scale = 1.0
		elif u < 0.6:
			e.x = reach - (6.0 if u < 0.45 else 0.0)
			e.fid = _monster_attack(e.m)
			e.anim = "attack"
			e.scale = 1.0
		elif u < 0.95:
			var p := _ease((u - 0.6) / 0.35)
			e.x = lerpf(reach, ex, p)
			e.dy = -10.0 * sin(PI * p)
	_hurt(st, u, 0.33, 0.9, _seg.cost, 1.0)
	if u >= 0.33 and u < 0.6:
		st.fx.append({"k": "impact", "x": LX + 10.0, "p": (u - 0.33) / 0.27})


## The Learner takes a hit at u = at: flash, hurt pose with a shake, damage number.
func _hurt(st: Dictionary, u: float, at: float, until: float, cost: int, size_k: float) -> void:
	var L: Dictionary = st.learner
	L.flash = _lit(at, u)
	if u >= at and u < until:
		L.fid = _anim_frame(assets.sheets[avatar], "hurt", 0.0, L.fid)
		L.anim = "hurt"
		L.scale = 1.0
		L.x = L.x - 4.0 + (3.0 * sin(u * 60.0) if u < at + 0.3 else 0.0)
	if cost > 0 and u >= at + 0.03 and u < at + 0.93:
		st.fx.append({"k": "dmg", "x": LX, "p": (u - at - 0.03) / 0.9, "txt": "-%d" % cost, "col": MAGENTA, "s": size_k})


func _current_prop(st: Dictionary) -> Dictionary:
	for o in st.props:
		if o.current:
			return o
	return {}


## The Learner walks up to the prop's grab point (its left side) and works it.
func _work_pose(st: Dictionary, u: float, from: float, to: float, o: Dictionary) -> void:
	var L: Dictionary = st.learner
	var lsheet: Dictionary = assets.sheets[avatar]
	var spot: float = o.x - _prop_half_w(o.sheet) - 18.0
	var heave: bool = o.sheet in HEAVE_PROPS and lsheet.anims.has("heave")
	var anim := "heave" if heave else "work"
	if u < from:
		var p := _ease(u / from)
		L.x = lerpf(LX, spot, p)
		if p < 1.0 and absf(spot - LX) > 2.0:
			L.fid = _anim_frame(lsheet, "walk", u * 2.0)
			L.anim = "walk"
		L.scale = 1.0
	elif u < to:
		L.x = spot
		L.home = spot
		L.scale = 1.0
		L.anim = anim
		if lsheet.anims.has(anim):
			L.fid = _anim_frame(lsheet, anim, u - from)
			if heave:
				L.x = spot - 2.0 * absf(sin((u - from) * 9.0))   # code rocks the heave
		else:
			L.dy = -3.0 * absf(sin((u - from) * 12.0))           # idle with a code bob
	elif u < to + 0.25:
		L.x = lerpf(spot, LX, _ease((u - to) / 0.25))


func _scan(st: Dictionary, u: float, until: float, o: Dictionary) -> void:
	var SP: Dictionary = st.spark
	if u < until:
		SP.fid = _anim_frame(assets.sheets[assets.spark], "attack", 0.0, "idle")
		SP.anim = "zap"
		if u > 0.08:
			st.fx.append({"k": "beam", "x0": SX + 26.0, "x1": o.x, "y1": _ground - _disp_h(o.sheet) * 0.55,
					"a": 0.6 + 0.4 * sin(u * 30.0)})


func _work(st: Dictionary, u: float) -> void:
	var o := _current_prop(st)
	if o.is_empty():
		return
	var puzzle: bool = assets.sheets[o.sheet].beat == "puzzle"
	var start := 0.0
	if puzzle:
		_scan(st, u, 0.5, o)
		start = 0.4
	_work_pose(st, u - start, 0.25, 1.0 - start * 0.5, o)
	if u >= 0.45 and u < 0.95:
		o.x += 2.0 * sin(u * 50.0)
		if int(u * 10.0) % 3 == 0:
			st.fx.append({"k": "dust", "x": o.x - _prop_half_w(o.sheet) * 0.5, "p": fmod(u * 2.0, 1.0)})
	if not assets.sheets[o.sheet].dials.is_empty() and u < 0.9:
		o.spin = u
	if u >= 0.9:
		o.progress = mini(o.steps, o.progress + 1)
		if _seg.final:
			var sheet: Dictionary = assets.sheets[o.sheet]
			o.fid = sheet.states.get("cleared", o.fid)
			if u < 1.3:
				st.fx.append({"k": "dust", "x": o.x, "p": (u - 0.9) / 0.4, "big": true})
	if _seg.glance and u >= 1.0:
		# scraped: the hurt pose with a small zap (Puzzle) or a scrape (Explore)
		if puzzle and u < 1.2:
			st.fx.append({"k": "zap", "x0": o.x - _prop_half_w(o.sheet), "x1": st.learner.x, "a": 1.0 - (u - 1.0) / 0.2, "s": 0.5})
		_hurt(st, u, 1.0, 1.35, _seg.cost, 0.5)
	if _seg.loot:
		_loot_burst(st, u - 0.95, o.x, 6)


func _slip(st: Dictionary, u: float) -> void:
	var o := _current_prop(st)
	if o.is_empty():
		_hurt(st, u, 0.52, 1.1, _seg.cost, 1.0)
		return
	var sheet: Dictionary = assets.sheets[o.sheet]
	var puzzle: bool = sheet.beat == "puzzle"
	if puzzle:
		_scan(st, u, 0.35, o)
	_work_pose(st, u, 0.2, 0.5, o)
	if u >= 0.5:
		var miss: String = _seg.miss
		if miss == "mimic" and u < 1.1:
			o.fid = sheet.states.mimic
			o.anim = "attack"
			o.x -= 14.0 * sin(PI * clampf((u - 0.5) / 0.3, 0.0, 1.0))
		elif miss in ["failed", "empty"] and (_seg.final or u < 1.1):
			o.fid = sheet.states[miss]
			if u < 0.9:
				st.fx.append({"k": "dust", "x": o.x, "p": (u - 0.5) / 0.4, "big": true})
		if puzzle and not sheet.dials.is_empty():
			o.buzz = 1.0 - clampf((u - 0.5) / 0.45, 0.0, 1.0)
		elif puzzle and u < 0.85:
			st.fx.append({"k": "zap", "x0": o.x - _prop_half_w(o.sheet), "x1": st.learner.x, "a": 1.0 - (u - 0.55) / 0.3, "s": 1.0})
		if puzzle and u >= 0.6 and u < 1.0:
			st.spark.fid = _anim_frame(assets.sheets[assets.spark], "hurt", 0.0, "idle")
			st.spark.anim = "hurt"
	_hurt(st, u, 0.52, 1.1, _seg.cost, 1.0)
	if not puzzle and _seg.miss == "" and u >= 0.52 and u < 0.9:
		st.learner.dy = 6.0 * sin(PI * (u - 0.52) / 0.38)   # slips in the mud


func _victory(st: Dictionary, u: float) -> void:
	var L: Dictionary = st.learner
	if u > 0.15:
		L.fid = _anim_frame(assets.sheets[avatar], "victory", 0.0, L.fid)
		L.anim = "victory"
		L.scale = 1.0
	L.dy = -8.0 * sin(PI * clampf((u - 0.15) / 0.35, 0.0, 1.0))
	if u > 0.3:
		st.spark.fid = _anim_frame(assets.sheets[assets.spark], "victory", 0.0, "idle")
		st.spark.anim = "victory"
	if _seg.loot:
		_loot_burst(st, u - 0.2, SLOTS[0] + 6.0, 3)


func _loot_burst(st: Dictionary, u: float, x0: float, n: int) -> void:
	var loot: String = assets.regions.get(region, {}).get("loot", "")
	if loot == "" or u < 0.0:
		return
	var spread := [-34.0, -14.0, 10.0, 30.0, 52.0, 70.0] if n > 3 else [32.0, 58.0, 84.0]
	for j in n:
		st.fx.append({"k": "loot", "sheet": loot, "id": LOOT_IDS[j % LOOT_IDS.size()], "x0": x0,
				"p": u - 0.07 * j, "dx": spread[j % spread.size()]})


func _retreat(st: Dictionary, u: float) -> void:
	for e in st.enemies:
		e.x = e.home + 220.0 * _ease(u / 1.1)
		e.a = 1.0 - _ease((u - 0.5) / 0.6)
		e.fid = _anim_frame(assets.sheets[e.sheet], "walk", u, e.fid)
		e.anim = "walk"
		e.scale = 1.0


func _swap(st: Dictionary, u: float) -> void:
	var L: Dictionary = st.learner
	if u < 0.7:
		L.weapon = _seg.from
		L.wfade = 1.0 - _ease((u - 0.2) / 0.5)
	else:
		L.weapon = _seg.to
		L.wfade = _ease((u - 0.7) / 0.4)
		if u < 1.4:
			st.fx.append({"k": "glint", "x": L.x, "p": (u - 0.7) / 0.7})
	var name: String = _seg.to.replace("-", " ").capitalize()
	st.fx.append({"k": "banner", "txt": "%s equipped" % name, "a": minf(1.0, u / 0.3) * (1.0 - _ease((u - 1.6) / 0.3))})


# ------------------------------------------------------------------ drawing

func _draw() -> void:
	if not _live() or _state.is_empty() or size.y <= 0.0:
		return
	var k := size.y / H
	var w := _width()
	var base := Transform2D(0.0, Vector2(k, k), 0.0, Vector2.ZERO)
	draw_set_transform_matrix(base)
	draw_rect(Rect2(0, 0, w, H), Color8(31, 41, 55))
	var cam: float = _state.cam
	for l in _layers:
		if l.name == "near":
			draw_rect(Rect2(0, 0, w, H), Color8(40, 30, 60, 70))   # depth haze (code)
		_tile(l, cam, w)
	var ax := _action_x()
	for o in _state.props:
		_draw_sprite(base, o, ax)
	_draw_sprite(base, _state.spark, ax)
	_draw_sprite(base, _state.learner, ax)
	var back: Array = _state.enemies.duplicate()
	back.reverse()
	for e in back:
		_draw_sprite(base, e, ax)
	for f in _state.fx:
		_draw_fx(base, f, ax, k)
	draw_set_transform_matrix(Transform2D.IDENTITY)


func _tile(l: Dictionary, cam: float, w: float) -> void:
	var off := fmod(cam * float(l.scroll), float(l.w))
	var x := -off
	while x < w:
		draw_texture_rect(l.tex, Rect2(floorf(x), l.y, l.w + 1.0, l.h), false)
		x += l.w


func _draw_sprite(base: Transform2D, s: Dictionary, ax: float) -> void:
	if not assets.sheets.has(s.sheet) or s.a <= 0.0:
		return
	var sheet: Dictionary = assets.sheets[s.sheet]
	var fr: Dictionary = sheet.by_id.get(s.fid, {})
	var tex := assets.texture(sheet.image)
	if fr.is_empty() or tex == null:
		return
	var ks: float = _disp_h(s.sheet) / sheet.figure_height * s.scale
	var feet := Vector2(ax + s.x, _ground + s.dy)
	var f: float = s.flash
	var mod := Color(1.0 + 2.0 * f, 1.0 + 2.0 * f, 1.0 + 2.0 * f, s.a)
	draw_texture_rect_region(tex, Rect2(feet + Vector2(fr.ox, fr.oy) * ks, Vector2(fr.w, fr.h) * ks),
			Rect2(fr.x, fr.y, fr.w, fr.h), mod)
	var hand = fr.get("hand")
	var wname: String = s.get("weapon", "")
	if wname == "" or not hand is Dictionary or not assets.weapons.has(wname):
		return
	var wp: Dictionary = assets.weapons[wname]
	var wtex := assets.texture(wp.image)
	if wtex != null and s.get("wfade", 1.0) > 0.0:
		var ang := deg_to_rad(float(s.get("wangle", hand.angle)))
		var at := feet + Vector2(hand.x, hand.y) * ks
		draw_set_transform_matrix(base * Transform2D(ang, Vector2(ks, ks), 0.0, at))
		draw_texture(wtex, -wp.grip, Color(mod, s.a * float(s.get("wfade", 1.0))))
		draw_set_transform_matrix(base)
	var ov = fr.get("overlay")
	if ov is Dictionary:
		draw_texture_rect_region(tex, Rect2(feet + Vector2(ov.ox, ov.oy) * ks, Vector2(ov.w, ov.h) * ks),
				Rect2(ov.x, ov.y, ov.w, ov.h), mod)


func _draw_fx(base: Transform2D, f: Dictionary, ax: float, k: float) -> void:
	var G := _ground
	match f.k:
		"slash":
			var a := maxf(0.0, f.a)
			var r: float = 40.0 * f.s
			var c := Vector2(ax + f.x - 18.0, G - 48.0 * f.s)
			draw_arc(c, r, deg_to_rad(-70), deg_to_rad(60), 24, Color(f.col, 0.47 * a), 7.0 * f.s)
			draw_arc(c, r, deg_to_rad(-60), deg_to_rad(50), 24, Color(1, 1, 1, 0.9 * a), 2.0 * f.s)
		"impact":
			var a: float = 1.0 - f.p
			var c := Vector2(ax + f.x, G - 52.0)
			for j in 8:
				var ang := j * PI / 4.0 + 0.3
				var d := Vector2(cos(ang), sin(ang))
				draw_line(c + d * (6.0 + 10.0 * f.p), c + d * (14.0 + 16.0 * f.p), Color(MAGENTA, a), 2.0)
		"zap":
			var pts := PackedVector2Array()
			var p0 := Vector2(ax + f.x0, G - 12.0)
			var p1 := Vector2(ax + f.x1 + 6.0, G - 40.0)
			for j in 9:
				var jit: float = 0.0 if j in [0, 8] else (6.0 if j % 2 == 1 else -6.0) * f.s
				pts.append(p0.lerp(p1, j / 8.0) + Vector2(0, jit))
			var a := clampf(f.a, 0.0, 1.0)
			draw_polyline(pts, Color(TEAL, 0.55 * a), 5.0 * f.s)
			draw_polyline(pts, Color(1, 1, 1, a), 2.0 * f.s)
		"beam":
			var p0 := Vector2(ax + f.x0, G - 34.0)
			var p1 := Vector2(ax + f.x1, f.y1)
			draw_line(p0, p1, Color(TEAL, 0.35 * f.a), 6.0)
			draw_line(p0, p1, Color(MINT, 0.8 * f.a), 1.5)
			draw_circle(p1, 5.0, Color(TEAL, 0.3 * f.a))
		"dust":
			var p: float = clampf(f.p, 0.0, 1.0)
			var n := 5 if f.get("big", false) else 3
			for j in n:
				var dx := (j - (n - 1) / 2.0) * 9.0 * (0.4 + p)
				draw_circle(Vector2(ax + f.x + dx, G - 4.0 - 10.0 * p), 3.0 + 4.0 * p, Color(DUST, 0.45 * (1.0 - p)))
		"glint":
			var a: float = 1.0 - f.p
			for j in 6:
				var ang: float = j * PI / 3.0 + f.p * 2.0
				var r: float = 10.0 + 18.0 * f.p
				draw_circle(Vector2(ax + f.x + 8.0, G - 40.0) + Vector2(cos(ang), sin(ang)) * r, 2.0, Color(MAGENTA, a))
		"loot":
			_draw_loot(base, f, ax)
		"ticks":
			var n: int = f.n
			var x0: float = ax + f.x - (n - 1) * 6.0
			for j in n:
				var r := Rect2(x0 + j * 12.0 - 4.0, f.y - 4.0, 8.0, 8.0)
				if j < f.on:
					draw_rect(r, TEAL)
				draw_rect(r, Color(TEAL, 0.9), false, 1.2)
		"dials":
			_draw_dials(f, ax, k)
		"dmg":
			var p: float = 0.3 if f.get("still", false) else clampf(f.p, 0.0, 1.0)
			var a := 1.0 if f.get("still", false) else 1.0 - _ease((f.p - 0.6) / 0.4)
			var y := G - 92.0 - 22.0 * _ease(p)
			_text(f.txt, Vector2(ax + f.x, y), 20.0 * f.s, Color(f.col, a), k)
		"banner":
			var a: float = clampf(f.a, 0.0, 1.0)
			var w := _width()
			draw_rect(Rect2(w / 2.0 - 90.0, 10.0, 180.0, 24.0), Color(0.07, 0.09, 0.15, 0.85 * a))
			draw_rect(Rect2(w / 2.0 - 90.0, 10.0, 180.0, 24.0), Color(MAGENTA, a), false, 1.5)
			_text(f.txt, Vector2(w / 2.0, 29.0), 15.0, Color(DUST, a), k)


func _draw_loot(base: Transform2D, f: Dictionary, ax: float) -> void:
	var p: float = f.p
	if p < 0.0 or p >= 1.7:
		return
	var x: float
	var y: float
	if p < 0.6:
		var q := p / 0.6
		x = f.x0 + f.dx * q
		y = -30.0 - 46.0 * sin(PI * q) + 26.0 * q
	elif p < 1.2:
		x = f.x0 + f.dx
		y = -4.0
		if int((p - 0.6) * 6.0) % 2 == 0:   # a small 3 Hz twinkle, not a flash
			var c := Vector2(ax + x + 5.0, _ground + y - 14.0)
			draw_line(c - Vector2(4, 0), c + Vector2(4, 0), Color(1, 1, 0.86, 0.8), 1.0)
			draw_line(c - Vector2(0, 4), c + Vector2(0, 4), Color(1, 1, 0.86, 0.8), 1.0)
	else:
		var q := _ease((p - 1.2) / 0.5)
		x = lerpf(f.x0 + f.dx, _width() - _action_x() - 30.0, q)
		y = lerpf(-4.0, -_ground + 10.0, q)
	_draw_sprite(base, _sprite(f.sheet, f.id, x, "loot").merged({"dy": y}, true), ax)


## The vault's dials: digits drawn in the blank faces. Set dials are teal, the one being
## worked spins, and a miss buzzes them red.
func _draw_dials(f: Dictionary, ax: float, k: float) -> void:
	var o: Dictionary = f.sprite
	var sheet: Dictionary = assets.sheets[o.sheet]
	var ks: float = _disp_h(o.sheet) / sheet.figure_height
	var feet := Vector2(ax + o.x, _ground + o.dy)
	for i in f.dials.size():
		var d: Dictionary = f.dials[i]
		var c := feet + Vector2(d.x, d.y) * ks
		var r: float = float(d.r) * ks
		var digit: int = (7 + 3 * i + run_seed) % 10
		var col := Color(0.6, 0.65, 0.7)
		if i < f.on:
			col = TEAL
		elif i == f.on and f.spin >= 0.0:
			digit = int(f.spin * 24.0) % 10
			col = DUST
		if f.buzz > 0.0:
			draw_circle(c, r * 1.3, Color(RED, 0.5 * f.buzz))
			col = RED
		_text(str(digit), c + Vector2(0, r * 0.55), r * 1.5, col, k)


## Text is drawn without the strip's scale, at its real pixel size, so it stays sharp.
func _text(txt: String, at: Vector2, px: float, col: Color, k: float) -> void:
	draw_set_transform_matrix(Transform2D.IDENTITY)
	var fs := maxi(6, int(px * k))
	var w := FONT.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	var pos := at * k - Vector2(w / 2.0, 0)
	draw_string_outline(FONT, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, maxi(2, int(fs * 0.18)), Color(0, 0, 0, 0.8 * col.a))
	draw_string(FONT, pos, txt, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, col)
	draw_set_transform_matrix(Transform2D(0.0, Vector2(k, k), 0.0, Vector2.ZERO))
