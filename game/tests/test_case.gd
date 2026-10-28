extends RefCounted
## Base class for tests run by res://tests/run_tests.gd.

var tree: SceneTree
var failures: Array[String] = []


func fail(msg: String) -> void:
	failures.append(msg)


func check(cond: bool, msg: String = "check failed") -> void:
	if not cond:
		fail(msg)


func check_eq(actual: Variant, expected: Variant, msg: String = "") -> void:
	if actual != expected:
		fail("%sexpected %s, got %s" % [msg + ": " if msg else "", var_to_str(expected), var_to_str(actual)])
