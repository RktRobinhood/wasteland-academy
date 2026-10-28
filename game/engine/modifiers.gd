class_name Modifiers
extends RefCounted
## The modifiers step (class plan phase 0, FAL-291). Every damage, heal, Scrap and time
## value combat uses passes through apply(). With nothing added it returns the value
## unchanged. Bazaar perks (G6) and class skills (FAL-308) plug in with add().
##
## A modifier is a Callable (kind: String, value: float, ctx: Dictionary) -> float. It
## must return value unchanged for kinds it doesn't touch. ctx says where the value comes
## from: {"outcome", "tier", "floor", "fight"} as far as they apply.
##
##   var mods := Modifiers.new()
##   mods.add(func(kind, v, _ctx): return v * 2.0 if kind == "scrap" else v)

## enemy_damage  HP taken off the enemy
## player_damage HP the player loses
## heal          HP the player gets back
## scrap         Scrap earned
## time          seconds on a question's clock, and Time Freeze's length
## max_hp        the player's HP at the start of a run
const KINDS := ["enemy_damage", "player_damage", "heal", "scrap", "time", "max_hp"]

var _mods: Array[Callable] = []


func add(m: Callable) -> void:
	_mods.append(m)


func apply(kind: String, value: float, ctx: Dictionary = {}) -> float:
	assert(kind in KINDS, "Modifiers: unknown kind %s" % kind)
	var v := value
	for m in _mods:
		v = float(m.call(kind, v, ctx))
	return v
