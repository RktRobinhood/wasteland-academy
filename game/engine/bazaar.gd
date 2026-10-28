class_name Bazaar
extends RefCounted
## The Bazaar (G6, Q10 on the FAL-274 plan): Scrap banked from runs buys capped
## upgrades, one perk for the next run, and cosmetics. Rules only, no UI, so a test can
## shop; ui/bazaar.gd draws it. Prices, caps and perk values are in Tuning (the Bazaar
## section at the end of engine/tuning.gd). What was bought is the save's `bazaar`
## record (engine/save_data.gd).
##
##   Bazaar.buy(save, "max_hp")                  # {"ok": true, "reason": "", "price": 850}
##   Bazaar.buy(save, "lucky_find", "freeze")    # a perk that needs a lifeline picked
##   var perk := Bazaar.equip(run, save)         # before run.start(): uses the perk up
##
## Nothing here touches combat. equip() gives the run one modifier (engine/modifiers.gd)
## built from what was bought, and the run's numbers pass through it like any other.
##
## Item ids: the upgrades "max_hp" and "lifeline", the perks in PERKS, and the cosmetics
## "frame:<id>" and "tint:<id>" (FRAMES, TINTS).

const LIFELINE_NAMES := {"fifty": "50-50", "hint": "Hint", "freeze": "Time Freeze"}

const UPGRADES := {
	"max_hp": {"name": "Max HP +10", "text": "Every run starts with 10 more HP."},
	"lifeline": {"name": "Lifeline +1", "text": "One more charge of the lifeline you pick, every run."},
}

## In the order the Bazaar lists them.
const PERKS := {
	"field_manual": {"name": "Field Manual", "text": "Hints are free."},
	"scrap_armour": {"name": "Scrap Armour", "text": "+20 HP."},
	"lucky_find": {"name": "Lucky Find", "text": "+1 charge on the lifeline you pick."},
	"second_wind": {"name": "Second Wind", "text": "Heal 20 HP after each boss."},
	"field_watch": {"name": "Field Watch", "text": "+10 s on every question."},
}

## The items the player picks a lifeline for when buying.
const PICK_LIFELINE := ["lifeline", "lucky_find"]

## Name-plate frames, from the encounter UI art (FAL-359). margins are the nine-slice
## margins in that art's ui.json: left, top, right, bottom.
const FRAMES := {
	"field_note": {"name": "Field Note", "art": "res://assets/ui/encounter/field-note-card.png", "margins": [12, 12, 12, 12]},
	"signal": {"name": "Signal Box", "art": "res://assets/ui/encounter/dialogue-box.png", "margins": [14, 14, 14, 14]},
	"brass": {"name": "Brass Chip", "art": "res://assets/ui/encounter/stakes-chip.png", "margins": [10, 8, 10, 8]},
}

## Colour tints for the name plate and the player's HP bar, from the Salvage Neon
## palette (ART_REQUIREMENTS.md). With none worn they are Scrap Teal.
const TINTS := {
	"magenta": {"name": "Bazaar Magenta", "color": Color("ff3da7")},
	"rust": {"name": "Rust Orange", "color": Color("faa261")},
	"dust": {"name": "Dust Yellow", "color": Color("eacb74")},
	"chrome": {"name": "Chrome", "color": Color("c9d2dc")},
}

## Why a purchase failed. "" means it can be bought.
const NOT_ENOUGH := "Not enough Scrap."
const CAPPED := "That's as far as it goes."
const OWNED := "You have it already."
const SLOT_FULL := "Your perk slot is full until your next run."
const PICK := "Pick a lifeline."
const UNKNOWN := "Nothing by that name."


## The save's Bazaar record, with any missing field filled in.
static func record(save: Dictionary) -> Dictionary:
	var fresh := SaveData.blank_bazaar()
	if not save.get("bazaar") is Dictionary:
		save.bazaar = fresh
	var rec: Dictionary = save.bazaar
	for key in fresh:
		if not rec.has(key):
			rec[key] = fresh[key]
	for id in fresh.lifelines:
		if not rec.lifelines.has(id):
			rec.lifelines[id] = 0
	return rec


static func cosmetics() -> Array:
	var out := []
	for id in FRAMES:
		out.append("frame:" + id)
	for id in TINTS:
		out.append("tint:" + id)
	return out


## Levels of an upgrade bought. The lifeline upgrade counts every lifeline's charges.
static func level(save: Dictionary, upgrade: String) -> int:
	var rec := record(save)
	if upgrade == "max_hp":
		return int(rec.max_hp)
	var n := 0
	for id in rec.lifelines:
		n += int(rec.lifelines[id])
	return n


static func cap(upgrade: String) -> int:
	return (Tuning.UPGRADES[upgrade] as Array).size()


## What an item costs now: an upgrade's next level, a perk, a cosmetic. -1 for an
## upgrade at its cap or an unknown id.
static func price(save: Dictionary, item: String) -> int:
	if Tuning.UPGRADES.has(item):
		var lv := level(save, item)
		return int(Tuning.UPGRADES[item][lv]) if lv < cap(item) else -1
	if Tuning.PERKS.has(item):
		return int(Tuning.PERKS[item])
	if item in cosmetics():
		return Tuning.COSMETIC_PRICE
	return -1


## "" when the item can be bought now (with this lifeline, where it needs one), else why not.
static func why_not(save: Dictionary, item: String, lifeline: String = "") -> String:
	var rec := record(save)
	if price(save, item) < 0:
		return CAPPED if Tuning.UPGRADES.has(item) else UNKNOWN
	if Tuning.PERKS.has(item) and not (rec.perk as Dictionary).is_empty():
		return SLOT_FULL
	if item in PICK_LIFELINE and not LIFELINE_NAMES.has(lifeline):
		return PICK
	if item in cosmetics() and item in rec.owned:
		return OWNED
	if int(save.get("scrap", 0)) < price(save, item):
		return NOT_ENOUGH
	return ""


## Buys an item. A purchase that can't go through changes nothing.
## Returns {"ok", "reason", "price"}.
static func buy(save: Dictionary, item: String, lifeline: String = "") -> Dictionary:
	var reason := why_not(save, item, lifeline)
	var cost := price(save, item)
	if reason != "":
		return {"ok": false, "reason": reason, "price": cost}
	var rec := record(save)
	save.scrap = int(save.scrap) - cost
	rec.spent = int(rec.spent) + cost
	if item == "max_hp":
		rec.max_hp = int(rec.max_hp) + 1
	elif item == "lifeline":
		rec.lifelines[lifeline] = int(rec.lifelines[lifeline]) + 1
	elif Tuning.PERKS.has(item):
		rec.perk = {"id": item, "lifeline": lifeline if item in PICK_LIFELINE else ""}
	else:
		rec.owned.append(item)
		wear(save, item)
	return {"ok": true, "reason": "", "price": cost}


## Puts on an owned frame or tint, or takes it off ("frame:" or "tint:"). False if it
## isn't owned.
static func wear(save: Dictionary, item: String) -> bool:
	var rec := record(save)
	var parts := item.split(":", true, 1)
	if parts.size() != 2 or not parts[0] in ["frame", "tint"]:
		return false
	if parts[1] != "" and not item in rec.owned:
		return false
	rec[parts[0]] = parts[1]
	return true


## What a perk record is called, "Lucky Find (Hint)" for one with a lifeline.
static func perk_name(perk: Dictionary) -> String:
	if perk.is_empty():
		return ""
	var name: String = PERKS[perk.id].name
	return name + (" (%s)" % LIFELINE_NAMES[perk.lifeline] if perk.get("lifeline", "") != "" else "")


## The one modifier for a run: the upgrades bought (rec, the Bazaar record) and the
## perk for this run ({} for none). Each part changes only its own value.
static func modifier(rec: Dictionary, perk: Dictionary) -> Callable:
	var hp_levels := int(rec.get("max_hp", 0))
	var charges: Dictionary = (rec.get("lifelines", {}) as Dictionary).duplicate()
	var perk_id: String = perk.get("id", "")
	var perk_lifeline: String = perk.get("lifeline", "")
	return func(kind: String, v: float, ctx: Dictionary) -> float:
		match kind:
			"max_hp":
				v += Tuning.MAX_HP_STEP * hp_levels
				if perk_id == "scrap_armour":
					v += Tuning.PERK_ARMOUR_HP
			"lifelines":
				var id: String = ctx.get("lifeline", "")
				v += int(charges.get(id, 0))
				if perk_id == "lucky_find" and id == perk_lifeline:
					v += 1
			"lifeline_cost":
				if perk_id == "field_manual" and ctx.get("lifeline", "") == "hint":
					return 0.0
			"boss_heal":
				if perk_id == "second_wind" and ctx.get("boss", "") in Tuning.PERK_SECOND_WIND_AFTER:
					v += Tuning.PERK_SECOND_WIND_HP
			"time":
				if perk_id == "field_watch" and not ctx.get("freeze", false):
					v += Tuning.PERK_WATCH_SECONDS
		return v


## Gets a run ready before run.start(): adds the modifier for what was bought, and uses
## the perk up, so the run after this one has none unless another is bought. A run that
## records nothing (run.records false, a link that jumps ahead) plays with the perk but
## leaves it for the next run. Returns the perk this run plays with ({} for none).
static func equip(run: Run, save: Dictionary) -> Dictionary:
	var rec := record(save)
	var perk: Dictionary = (rec.perk as Dictionary).duplicate()
	if run.records:
		rec.perk = {}
	run.modifiers.add(modifier(rec, perk))
	return perk
