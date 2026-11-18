class_name Toys
extends RefCounted
## The toys a lesson can name, by id (#217, game/docs/TOYS.md). The catalogue (#221)
## decides which toys exist; this is where a built one is registered.

const IDS := {
	"relay": preload("res://ui/toys/relay_toy.gd"),
}


static func has(id: String) -> bool:
	return IDS.has(id)


## Errors in a toy item, as sentences; empty when it can be built.
static func check(item: Dictionary) -> PackedStringArray:
	var id := str(item.get("toy", ""))
	if not has(id):
		return ["no toy called \"%s\"" % id]
	return IDS[id].check_spec(item)


## A toy built from a script's toy item, or null if the item can't make one.
static func make(item: Dictionary) -> LessonToy:
	if not check(item).is_empty():
		return null
	var toy: LessonToy = IDS[str(item.toy)].new()
	toy.setup(item)
	return toy
