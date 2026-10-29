class_name JourneyAssets
extends RefCounted
## Every journey sheet in res://assets/journey/, found by folder (FAL-331). The folder is
## a copy of the repo's assets/journey/, made by scripts/godot-env.sh before each
## import and export; its format is assets/journey/README.md.
##
##   party/<avatar>.json   the Learners (facing right, weapon hand slot) and spark.json
##   enemies/dN-*.json     the D1-D5 ranks, keyed by N; a sheet with `stages` is a boss
##   weapons/<name>.json   + <name>.png, drawn in the Learner's hand
##   <region>/             layers.json (parallax), loot.json, props (`beat` and `states`)
##                         and the region's creatures (any other sheet with an attack)
##   cast/, encounters/    read and checked, not drawn yet (FAL-349)
##
## A new sheet that follows the README works without a code change. Images are decoded
## from their original bytes on first use (the export keeps them as they are, see
## godot-env.sh) and cached.

const ROOT := "res://assets/journey"
## Folders that aren't regions.
const SHARED := ["party", "enemies", "weapons", "cast", "encounters"]

var root: String
## name -> sheet: {name, folder, json, image, figure_height, facing, frames: Array,
## by_id: {id: frame}, anims, stages, states, beat}. Frame rects are atlas px; ox, oy and
## hand are shipped px from the feet point.
var sheets := {}
## name -> {name, image, grip: Vector2, size: Vector2}
var weapons := {}
## region -> {layers: Array of {name, image, scroll, feet_y, w, h}, props: Array,
## creatures: Array, loot: String}
var regions := {}
## tier (1-5) -> enemy sheet name
var enemies := {}
## Learner sheet names (party/ sheets that have a walk), and Spark's.
var avatars: Array[String] = []
var spark := ""
## Problems found while scanning (unreadable JSON, missing fields).
var errors: PackedStringArray = []

var _textures := {}


static func scan(from: String = ROOT) -> JourneyAssets:
	var a := JourneyAssets.new()
	a.root = from
	a._scan_dir(from, "")
	a.avatars.sort()
	for r in a.regions.values():
		r.props.sort()
		r.creatures.sort()
	return a


func _scan_dir(path: String, rel: String) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for sub in dir.get_directories():
		_scan_dir(path.path_join(sub), rel.path_join(sub) if rel != "" else sub)
	for f in dir.get_files():
		if f.ends_with(".json"):
			_add(path, rel, f)


func _add(dir: String, rel: String, file: String) -> void:
	var path := dir.path_join(file)
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary:
		errors.append("%s: not a JSON object" % path)
		return
	var top := rel.split("/")[0]
	var name := file.get_basename()
	if top == "weapons":
		var grip: Array = data.get("grip", [0, 0])
		var size: Array = data.get("size", [0, 0])
		weapons[name] = {"name": name, "image": dir.path_join(name + ".png"),
				"grip": Vector2(grip[0], grip[1]), "size": Vector2(size[0], size[1])}
		return
	var region := "" if top in SHARED else top
	if file == "layers.json":
		var layers: Array = []
		for ln in ["far", "mid", "near"]:
			if data.get("layers", {}).has(ln):
				var l: Dictionary = data.layers[ln]
				layers.append({"name": ln, "image": dir.path_join(l.image), "scroll": float(l.get("scroll", 1.0)),
						"feet_y": float(l.get("feet_y", 0)), "w": float(l.get("w", 0)), "h": float(l.get("h", 0))})
		_region(region).layers = layers
		return
	if not data.has("frames") or not data.has("image"):
		errors.append("%s: no frames or image" % path)
		return
	var s := {"name": name, "folder": rel, "json": path, "image": dir.path_join(data.image),
			"figure_height": float(data.get("figure_height", 1)), "facing": data.get("facing", "none"),
			"frames": data.frames, "by_id": {}, "anims": data.get("anims", {}),
			"stages": data.get("stages", []), "states": data.get("states", {}),
			"beat": data.get("beat", ""), "dials": data.get("dials", [])}
	for fr in data.frames:
		s.by_id[fr.id] = fr
	if s.beat == "" and region != "":
		if name.begins_with("cache-"):
			s.beat = "explore"
		elif name.begins_with("obstacle-"):
			s.beat = "puzzle"
	if s.states.is_empty() and s.beat != "":
		s.states = _default_states(s)
	sheets[name] = s
	if top == "party":
		if s.anims.has("walk"):
			avatars.append(name)
		else:
			spark = name
	elif top == "enemies":
		var m := RegEx.create_from_string("^d(\\d)-").search(name)
		if m != null:
			enemies[int(m.get_string(1))] = name
	elif region != "":
		var r := _region(region)
		if name == "loot":
			r.loot = name
		elif s.beat != "":
			r.props.append(name)
		elif s.anims.has("attack"):
			r.creatures.append(name)


## States for a prop JSON written before FAL-346: start is its first frame, cleared its
## second (the cache's `open`, the trap's `cleared`).
static func _default_states(s: Dictionary) -> Dictionary:
	var ids: Array = s.frames.map(func(f): return f.id)
	var st := {"start": ids[0], "cleared": ids[min(1, ids.size() - 1)]}
	for id in ids.slice(2):
		st[id] = id
	return st


func _region(name: String) -> Dictionary:
	if not regions.has(name):
		regions[name] = {"layers": [], "props": [], "creatures": [], "loot": ""}
	return regions[name]


func has_avatar(avatar: String) -> bool:
	return avatar in avatars


## The sheets a region's beats can use: what JourneyBeats.encounter() picks from.
func roster(region: String) -> Dictionary:
	var r: Dictionary = regions.get(region, {"props": [], "creatures": []})
	var out := {"explore": [], "puzzle": [], "creatures": r.creatures.duplicate(), "enemies": {}, "bosses": {}}
	for p in r.props:
		if out.has(sheets[p].beat):
			out[sheets[p].beat].append(p)
	for tier in enemies:
		out.enemies[tier] = enemies[tier]
		var n: int = sheets[enemies[tier]].stages.size()
		if n > 1:
			out.bosses[tier] = n
	return out


## Anim name -> frame ids. Anims whose indexes are out of range are left out (validate()
## reports them).
func anim_ids(sheet: Dictionary, anim: String) -> Array:
	var a: Dictionary = sheet.anims.get(anim, {})
	var out := []
	for i in a.get("frames", []):
		if int(i) >= 0 and int(i) < sheet.frames.size():
			out.append(sheet.frames[int(i)].id)
	return out


## The decoded image at path, as a mipmapped texture. Null if it can't be read.
func texture(path: String) -> Texture2D:
	if _textures.has(path):
		return _textures[path]
	var img := image(path)
	var tex: Texture2D = null
	if img != null:
		img.generate_mipmaps()
		tex = ImageTexture.create_from_image(img)
	_textures[path] = tex
	return tex


static func image(path: String) -> Image:
	var bytes := FileAccess.get_file_as_bytes(path)
	if bytes.is_empty():
		return null
	var img := Image.new()
	var err := img.load_png_from_buffer(bytes) if path.ends_with(".png") else img.load_webp_from_buffer(bytes)
	return img if err == OK else null


## Every problem with the sheets: unreadable images, frame and overlay rectangles outside
## their atlas, anim frame indexes that don't exist, states and boss stages that name
## missing frames or anims. Empty when everything is drawable.
func validate() -> PackedStringArray:
	var out := errors.duplicate()
	for name in sheets:
		var s: Dictionary = sheets[name]
		var img := image(s.image)
		if img == null:
			out.append("%s: can't read %s" % [name, s.image])
			continue
		var atlas := Rect2i(Vector2i.ZERO, img.get_size())
		for fr in s.frames:
			if not atlas.encloses(Rect2i(int(fr.x), int(fr.y), int(fr.w), int(fr.h))):
				out.append("%s: frame %s outside its %s atlas" % [name, fr.id, img.get_size()])
			var ov = fr.get("overlay")
			if ov is Dictionary and not atlas.encloses(Rect2i(int(ov.x), int(ov.y), int(ov.w), int(ov.h))):
				out.append("%s: frame %s overlay outside its atlas" % [name, fr.id])
		for an in s.anims:
			for i in s.anims[an].get("frames", []):
				if int(i) < 0 or int(i) >= s.frames.size():
					out.append("%s: anim %s has no frame %s" % [name, an, i])
		for st in s.states:
			if not s.by_id.has(s.states[st]):
				out.append("%s: state %s names missing frame %s" % [name, st, s.states[st]])
		for stage in s.stages:
			for key in stage:
				if not s.anims.has(stage[key]):
					out.append("%s: stage names missing anim %s" % [name, stage[key]])
	for w in weapons.values():
		if image(w.image) == null:
			out.append("%s: can't read %s" % [w.name, w.image])
	for rn in regions:
		for l in regions[rn].layers:
			if image(l.image) == null:
				out.append("%s: can't read layer %s" % [rn, l.image])
	return out
