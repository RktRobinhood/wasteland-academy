class_name Seeded
extends RefCounted
## A seeded random stream. The same seed and view key always give the same numbers,
## on desktop and on the web build: the seed is an FNV-1a hash of the text (not
## Godot's hash(), which is not promised to stay the same between versions), and
## RandomNumberGenerator is PCG32, which is integer-only.

var rng := RandomNumberGenerator.new()


func _init(text: String) -> void:
	rng.seed = Seeded.fnv1a(text)
	rng.state = Seeded.fnv1a("state:" + text)


## 32-bit FNV-1a. Kept to 32 bits so the products never overflow an int.
static func fnv1a(text: String) -> int:
	var h := 0x811c9dc5
	for b in text.to_utf8_buffer():
		h = ((h ^ b) * 0x01000193) & 0xffffffff
	return h


## A whole number from lo to hi, both included.
func int_in(lo: int, hi: int) -> int:
	return rng.randi_range(lo, hi)


func chance(p: float) -> bool:
	return rng.randf() < p


func pick(items: Array) -> Variant:
	return items[rng.randi_range(0, items.size() - 1)]


## Picks an index with probability proportional to its weight.
func weighted(weights: Array) -> int:
	var total := 0.0
	for w in weights:
		total += float(w)
	var r := rng.randf() * total
	for i in weights.size():
		r -= float(weights[i])
		if r < 0.0:
			return i
	return weights.size() - 1


func shuffled(items: Array) -> Array:
	var out := items.duplicate()
	for i in range(out.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var t = out[i]
		out[i] = out[j]
		out[j] = t
	return out
