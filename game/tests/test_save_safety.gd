extends "res://tests/test_case.gd"
## Saves are never wiped, are written atomically, and move by export and import (#185).

const DIR := "user://test_save_safety"


func _path(name: String) -> String:
	DirAccess.make_dir_recursive_absolute(DIR)
	return "%s/%s.json" % [DIR, name]


func _clean() -> void:
	for f in DirAccess.get_files_at(DIR):
		DirAccess.remove_absolute("%s/%s" % [DIR, f])


func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()


func _unreadable(name: String) -> Array:
	var out := []
	for f in DirAccess.get_files_at(DIR):
		if f.begins_with(name + ".unreadable-"):
			out.append("%s/%s" % [DIR, f])
	return out


func _played() -> Dictionary:
	var save := SaveData.blank()
	save.scrap = 42
	save.watched = ["intro"]
	save.cells = {"k": {"seen": 3, "right": 2, "wrong": 1}}
	return save


## JSON turns whole numbers into floats, so saves are compared after a trip through JSON.
func _norm(save: Dictionary) -> String:
	return JSON.stringify(JSON.parse_string(JSON.stringify(save)), "", true)


func test_a_corrupt_save_is_set_aside_not_overwritten() -> void:
	_clean()
	var path := _path("corrupt")
	_write(path, "{ this is not json")
	var loaded := SaveData.load_from(path)
	check_eq(loaded.scrap, 0, "a blank save")
	var kept := _unreadable("corrupt")
	check_eq(kept.size(), 1, "the unreadable file was not kept")
	check_eq(FileAccess.get_file_as_string(kept[0]), "{ this is not json")
	check(not FileAccess.file_exists(path), "the unreadable file is still at the save path")
	# The next store must not touch the kept file.
	check(SaveData.store(loaded, path))
	check_eq(FileAccess.get_file_as_string(_unreadable("corrupt")[0]), "{ this is not json")
	_clean()


func test_a_truncated_save_is_set_aside_and_the_backup_is_used() -> void:
	_clean()
	var path := _path("trunc")
	check(SaveData.store(_played(), path))
	var older := _played()
	older.scrap = 50
	check(SaveData.store(older, path))
	var whole := FileAccess.get_file_as_string(path)
	_write(path, whole.substr(0, whole.length() / 2))
	var loaded := SaveData.load_from(path)
	check_eq(_unreadable("trunc").size(), 1, "the truncated file was not kept")
	check_eq(loaded.scrap, 42, "the .bak (the write before the last) should be used")
	_clean()


func test_json_that_is_not_a_save_is_set_aside() -> void:
	_clean()
	var path := _path("notsave")
	_write(path, "[1, 2, 3]")
	SaveData.load_from(path)
	check_eq(_unreadable("notsave").size(), 1)
	_clean()


func test_store_writes_through_a_temp_file_and_keeps_a_backup() -> void:
	_clean()
	var path := _path("atomic")
	check(SaveData.store(_played(), path))
	check(not FileAccess.file_exists(SaveData.temp_path(path)), "the temp file should be renamed away")
	check(not FileAccess.file_exists(SaveData.backup_path(path)), "no backup until there is an old save")
	var second := _played()
	second.scrap = 99
	check(SaveData.store(second, path))
	check_eq(SaveData.load_from(path).scrap, 99)
	check_eq(SaveData.parse(FileAccess.get_file_as_string(SaveData.backup_path(path))).scrap, 42, "the .bak holds the save before")
	_clean()


func test_a_write_that_died_leaves_the_save_whole() -> void:
	_clean()
	var path := _path("died")
	check(SaveData.store(_played(), path))
	# A killed write leaves a half-written temp file and the real save untouched.
	_write(SaveData.temp_path(path), "{\"version\": 6, \"scr")
	check_eq(SaveData.load_from(path).scrap, 42)
	check_eq(_unreadable("died").size(), 0)
	_clean()


func test_a_missing_save_starts_blank_even_with_an_old_backup() -> void:
	_clean()
	var path := _path("gone")
	check(SaveData.store(_played(), path))
	check(SaveData.store(_played(), path))
	DirAccess.remove_absolute(path)
	check_eq(SaveData.load_from(path).scrap, 0, "deleting the save is a reset")
	_clean()


func test_export_and_import_round_trip() -> void:
	var save := _played()
	var code := SaveData.export_code(save)
	check(code.begins_with("WA-SAVE-1:"))
	check(not code.contains("\n"), "the code should be one line")
	var read := SaveData.import_text(code)
	check(read.ok, "import of an exported code")
	check_eq(_norm(read.save), _norm(SaveData.migrate(save)))
	# Spaces and line breaks added by a chat app or a form field do not matter.
	var wrapped := code.substr(0, 30) + "\n" + code.substr(30, 20) + " " + code.substr(50)
	check_eq(_norm(SaveData.import_text("  " + wrapped + "\n").save), _norm(SaveData.migrate(save)))
	# The exported file is the JSON itself.
	check_eq(_norm(SaveData.import_text(SaveData.export_text(save)).save), _norm(SaveData.migrate(save)))


func test_import_rejects_what_is_not_a_save() -> void:
	for text in ["", "hello", "WA-SAVE-1:", "WA-SAVE-1:!!!!", "{\"scrap\": 3}", "[1]",
			SaveData.export_code(_played()).substr(0, 40)]:
		var read := SaveData.import_text(text)
		check_eq(read.ok, false, "should refuse %s" % text)
		check(read.error != "")


func test_import_refuses_a_save_from_a_newer_game() -> void:
	var save := _played()
	save.version = SaveData.VERSION + 1
	check_eq(SaveData.import_text(SaveData.export_code(save)).ok, false)


func test_import_migrates_an_old_save() -> void:
	var old := {"version": 0, "cells": {"k": {"seen": 1}}, "seed": 7}
	var read := SaveData.import_text(SaveData.export_code(old))
	check(read.ok)
	check_eq(read.save.version, SaveData.VERSION)
	check_eq(read.save.seed, 7)


func test_the_transfer_panel_replaces_the_save_and_keeps_the_old_one() -> void:
	_clean()
	var path := _path("panel")
	check(SaveData.store(_played(), path))
	var theirs := SaveData.blank()
	theirs.scrap = 7
	var panel := SaveTransferPanel.new()
	panel.save_path = path
	panel.reload_after_import = false
	tree.root.add_child(panel)
	await tree.process_frame
	panel.open()
	check_eq((panel.find_child("Code", true, false) as TextEdit).text, SaveData.export_code(SaveData.load_from(path)), "export shows this device's code")
	var box := panel.find_child("Code", true, false) as TextEdit
	box.text = SaveData.export_code(theirs)
	var button := panel.find_child("ImportCode", true, false) as Button
	button.pressed.emit()
	check_eq(SaveData.load_from(path).scrap, 42, "the first press must not replace anything")
	button.pressed.emit()
	check_eq(SaveData.load_from(path).scrap, 7, "the second press replaces the save")
	var before := []
	for f in DirAccess.get_files_at(DIR):
		if f.contains(".before-import-"):
			before.append(f)
	check_eq(before.size(), 1, "the replaced save should be kept")
	panel.queue_free()
	await tree.process_frame
	_clean()
