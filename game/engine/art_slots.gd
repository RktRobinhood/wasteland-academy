class_name ArtSlots
extends RefCounted
## Art by file name (FAL-470), so each art batch (FAL-362) shows up in the game when its
## PR merges, with no code change. A slot is a path under assets/ without its extension;
## the file may be WebP or PNG. A slot with no file falls back to today's art or the
## coded look. game/README.md, "Art slots", is the contract: every folder, file name,
## size and fallback.
##
##   ArtSlots.find("regions/quadratics/boss")      # "res://assets/regions/quadratics/boss.webp", or ""
##   ArtSlots.texture("title/key-art")             # a Texture2D, or null
##   ArtSlots.enemy("quadratics", "boss", 5, 3, 1, 10)  # {"name", "taunt", "art", "hurt", "named"}
##
## Names and taunts are data: data/bosses.json (each region's mini-boss and boss) and
## data/enemies.json (the shared pool of regular enemies). Name-plate frames are
## data/frames.json, read by Bazaar.frames().

## The extensions a slot's file may have, in the order they're looked for.
const EXTENSIONS := ["webp", "png"]
## The file name of each fight kind's art in a region's folder.
const BOSS_SLOT := {"mini": "miniboss", "boss": "boss"}
## Best-floor medals: floors 1 to MEDALS - 1, then one for MEDALS and deeper.
const MEDALS := 4

## Where the slots are. Tests point these at fixtures.
static var root := "res://assets/"
static var data_dir := "res://data/"

static var _data := {}


## The file for a slot ("" when it has none).
static func find(slot: String) -> String:
	for ext in EXTENSIONS:
		var path: String = root + slot + "." + ext
		if ResourceLoader.exists(path):
			return path
	return ""


## The slot's texture, or null when it has no file.
static func texture(slot: String) -> Texture2D:
	var path := find(slot)
	return load(path) as Texture2D if path != "" else null


## A data file in data_dir, parsed ({} or [] when it isn't there). Read once.
static func data(file: String) -> Variant:
	var path := data_dir + file
	if not _data.has(path):
		var parsed = null
		if FileAccess.file_exists(path):
			var f := FileAccess.open(path, FileAccess.READ)
			parsed = JSON.parse_string(f.get_as_text()) if f != null else null
		if parsed == null:
			parsed = [] if file == "enemies.json" or file == "frames.json" else {}
		_data[path] = parsed
	return _data[path]


## Forgets the data files read, after a test changes data_dir.
static func reset() -> void:
	_data = {}


## Who a fight is against, as the fight screen draws it: {"name", "taunt", "art", "hurt",
## "named"} (art and hurt are file paths, "" for none; named is true when
## data/bosses.json named a mini-boss or boss). kind is "fight", "mini" or "boss"
## (Dungeon.fight_kind). A mini-boss or boss uses its region's art and its name and
## taunt from data/bosses.json; a regular fight draws from the shared pool. Whatever is
## missing comes from the pool, then from the tier (Tuning.ENEMIES), as before FAL-470.
## The draw hashes the run seed, floor and fight, so it never moves the run's own dice.
static func enemy(region: String, kind: String, tier: int, seed_no: int, on_floor: int, fight: int) -> Dictionary:
	var e: Dictionary = Tuning.ENEMIES[tier]
	var out := {"name": e.name, "taunt": "", "named": false, "art": "res://assets/enemies/" + e.art, "hurt": _hurt_of("enemies/" + e.art.get_basename())}
	var pool := []
	for p in data("enemies.json"):
		if int(p.get("tier", 0)) == tier and find("enemies/" + str(p.id)) != "":
			pool.append(p)
	if not pool.is_empty():
		var p: Dictionary = pool[absi(hash([seed_no, on_floor, fight])) % pool.size()]
		out.name = p.get("name", out.name)
		out.art = find("enemies/" + str(p.id))
		out.hurt = _hurt_of("enemies/" + str(p.id))
	if BOSS_SLOT.has(kind):
		var slot: String = BOSS_SLOT[kind]
		var said: Dictionary = (data("bosses.json") as Dictionary).get(region, {}).get(slot, {})
		out.named = said.has("name")
		out.name = said.get("name", out.name)
		out.taunt = said.get("taunt", "")
		var art := find("regions/%s/%s" % [region, slot])
		if art != "":
			out.art = art
			out.hurt = find("regions/%s/%s-hurt" % [region, slot])
	return out


## A region's fight backdrop, or null.
static func backdrop(region: String) -> Texture2D:
	return texture("regions/%s/backdrop" % region)


## The best-floor medal for a floor (the last medal covers that floor and deeper), or null.
static func medal(on_floor: int) -> Texture2D:
	if on_floor < 1:
		return null
	return texture("ui/run/medal-floor-%d" % mini(on_floor, MEDALS))


## A Bazaar icon: "scrap", or an upgrade or perk id ("max_hp", "field_manual").
static func bazaar_icon(id: String) -> Texture2D:
	var kind := "scrap" if id == "scrap" else ("upgrade-" if Bazaar.UPGRADES.has(id) else "perk-") + id.replace("_", "-")
	return texture("bazaar/" + kind)


static func _hurt_of(slot: String) -> String:
	return find(slot + "-hurt")
