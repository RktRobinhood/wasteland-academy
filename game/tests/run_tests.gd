extends SceneTree
## Headless test runner. No third-party framework.
##
##   godot --headless --path game --script res://tests/run_tests.gd
##   godot --headless --path game --script res://tests/run_tests.gd -- --only=guardian
##
## --only=<text> runs just the test files whose name contains text.
##
## Loads every res://tests/test_*.gd, instantiates it, and calls each method whose
## name starts with "test_". A test fails if it calls fail() (or a check_* helper
## that fails) or if its file does not load. Exits 0 when everything passes, 1 otherwise.
##
## A test file extends res://tests/test_case.gd. Test methods may be coroutines.
##
## A script error while a test runs (say, a null access inside a coroutine the test
## started) fails that test too, even though the engine carries on after it.

const TESTS_DIR := "res://tests"


## Collects the script errors the engine reports, from any thread.
class ScriptErrors extends Logger:
	var _lock := Mutex.new()
	var _seen: PackedStringArray = []

	func _log_error(_function: String, file: String, line: int, code: String, rationale: String,
			_editor_notify: bool, error_type: int, _backtraces: Array[ScriptBacktrace]) -> void:
		if error_type != ERROR_TYPE_SCRIPT:
			return
		_lock.lock()
		_seen.append("%s:%d: %s" % [file, line, rationale if rationale != "" else code])
		_lock.unlock()

	func take() -> PackedStringArray:
		_lock.lock()
		var out := _seen
		_seen = []
		_lock.unlock()
		return out


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var files := _test_files()
	var passed := 0
	var failed := 0
	var errors := ScriptErrors.new()
	OS.add_logger(errors)
	if files.is_empty():
		printerr("FAIL: no test files found in %s" % TESTS_DIR)
		quit(1)
		return
	for path in files:
		var script := load(path) as GDScript
		if script == null or not script.can_instantiate():
			printerr("FAIL %s: could not load test file" % path)
			failed += 1
			continue
		var methods: Array[String] = []
		for m in script.get_script_method_list():
			var name: String = m["name"]
			if name.begins_with("test_") and not methods.has(name):
				methods.append(name)
		methods.sort()
		for method in methods:
			var case = script.new()
			case.tree = self
			errors.take()
			await case.call(method)
			for e in errors.take():
				case.failures.append("script error: " + e)
			if case.failures.is_empty():
				print("ok   %s::%s" % [path.get_file(), method])
				passed += 1
			else:
				for msg in case.failures:
					printerr("FAIL %s::%s: %s" % [path.get_file(), method, msg])
				failed += 1
	print("\n%d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _test_files() -> Array[String]:
	var out: Array[String] = []
	var only := ""
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--only="):
			only = a.substr(7)
	for f in DirAccess.get_files_at(TESTS_DIR):
		if f.begins_with("test_") and f.ends_with(".gd") and f != "test_case.gd" and (only == "" or f.contains(only)):
			out.append(TESTS_DIR.path_join(f))
	out.sort()
	return out
