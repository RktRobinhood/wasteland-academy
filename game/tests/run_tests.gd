extends SceneTree
## Headless test runner. No third-party framework.
##
##   godot --headless --path game --script res://tests/run_tests.gd
##   godot --headless --path game --script res://tests/run_tests.gd -- --only=guardian
##
## --only=<text> runs just the test files whose name contains text.
## --shard=<index>/<total> selects a one-based shard by stable filename hash.
## --list prints discovered paths without loading them. Sharding and filters compose.
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
	var only := ""
	var shard_index := 0
	var shard_total := 1
	var list_only := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--only="):
			only = arg.substr(7)
		elif arg.begins_with("--shard="):
			var parts := arg.substr(8).split("/")
			if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
				printerr("FAIL: use --shard=<index>/<total> (one-based)")
				quit(2)
				return
			var index := parts[0].to_int()
			var total := parts[1].to_int()
			if index < 1 or total < index or total > 64:
				printerr("FAIL: shard requires 1 <= index <= total <= 64")
				quit(2)
				return
			shard_index = index - 1
			shard_total = total
		elif arg == "--list":
			list_only = true
	var files := _test_files(only, shard_index, shard_total)
	if files.is_empty():
		printerr("FAIL: no matching test files found in %s" % TESTS_DIR)
		quit(1)
		return
	if list_only:
		for path in files:
			print(path)
		quit()
		return
	var started := Time.get_ticks_msec()
	print("START native tests | %d files" % files.size())
	var passed := 0
	var failed := 0
	var errors := ScriptErrors.new()
	OS.add_logger(errors)
	for path in files:
		var file_started := Time.get_ticks_msec()
		var filename := path.get_file()
		print("START file %s" % filename)
		var script := load(path) as GDScript
		if script == null or not script.can_instantiate():
			printerr("FAIL %s: could not load test file" % path)
			failed += 1
			print("END   file %s | %d ms | load failed" % [filename, Time.get_ticks_msec() - file_started])
			continue
		var methods: Array[String] = []
		for m in script.get_script_method_list():
			var name: String = m["name"]
			if name.begins_with("test_") and not methods.has(name):
				methods.append(name)
		methods.sort()
		for method in methods:
			var method_started := Time.get_ticks_msec()
			print("START test %s::%s" % [filename, method])
			var case = script.new()
			case.tree = self
			errors.take()
			await case.call(method)
			for e in errors.take():
				case.failures.append("script error: " + e)
			if case.failures.is_empty():
				print("ok   %s::%s | %d ms" % [filename, method, Time.get_ticks_msec() - method_started])
				passed += 1
			else:
				for msg in case.failures:
					printerr("FAIL %s::%s: %s" % [filename, method, msg])
				print("END   failed test %s::%s | %d ms" % [filename, method, Time.get_ticks_msec() - method_started])
				failed += 1
		print("END   file %s | %d ms" % [filename, Time.get_ticks_msec() - file_started])
	print("END   native tests | %d ms" % (Time.get_ticks_msec() - started))
	print("\n%d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)


func _test_files(only: String, shard_index: int, shard_total: int) -> Array[String]:
	var out: Array[String] = []
	for f in DirAccess.get_files_at(TESTS_DIR):
		if not f.begins_with("test_") or not f.ends_with(".gd") or f == "test_case.gd":
			continue
		if not only.is_empty() and not f.contains(only):
			continue
		# First 32 bits of SHA-256: stable across platforms and unaffected by changes
		# to other files. With a single shard every file is selected in legacy order.
		if shard_total > 1 and f.sha256_text().substr(0, 8).hex_to_int() % shard_total != shard_index:
			continue
		out.append(TESTS_DIR.path_join(f))
	out.sort()
	return out
