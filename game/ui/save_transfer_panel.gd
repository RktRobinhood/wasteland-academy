class_name SaveTransferPanel
extends Control
## Export and import of the save (#185), opened from the settings screen. Progress lives
## on one device and one browser, so this is how it moves: a code to copy and paste, or
## a file. Nothing is sent anywhere.
##
## The code works everywhere. A file is offered where the platform can do it: a download
## and a file picker in the browser, a file dialog on a computer or phone.
##
## Importing replaces the save on this device. The one it replaces is kept beside it
## (SaveData.replace_with), and the screen asks twice.

signal imported

const FILE_NAME := "wasteland-academy-save.json"

var save_path := SaveData.PATH
## Set by tests to skip the scene reload after an import.
var reload_after_import := true

var _box: TextEdit
var _status: Label
var _import_button: Button
var _file_dialog: FileDialog
var _pending: Dictionary = {}
var _js_callback: JavaScriptObject


func _ready() -> void:
	hide()
	set_anchors_preset(Control.PRESET_FULL_RECT)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.8)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	var panel := PanelContainer.new()
	center.add_child(panel)
	var pad := MarginContainer.new()
	for side in ["left", "top", "right", "bottom"]:
		pad.add_theme_constant_override("margin_" + side, 40)
	panel.add_child(pad)
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(900, 0)
	col.add_theme_constant_override("separation", 18)
	pad.add_child(col)

	var title := Label.new()
	title.text = "Your save"
	title.add_theme_font_size_override("font_size", 64)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(title)
	var help := Label.new()
	help.text = "Progress stays on this device and this browser. To move it, copy the code (or save the file), then paste it into the game on the other device and press Import."
	help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(help)

	_box = TextEdit.new()
	_box.name = "Code"
	_box.custom_minimum_size = Vector2(0, 320)
	_box.wrap_mode = TextEdit.LINE_WRAPPING_BOUNDARY
	_box.placeholder_text = "Paste a save code here"
	col.add_child(_box)

	col.add_child(_row([_button("Copy code", _on_copy, "CopyCode"), _button("Save file", _on_save_file, "SaveFile")]))
	_import_button = _button("Import this code", _on_import, "ImportCode")
	col.add_child(_row([_import_button, _button("Import file", _on_import_file, "ImportFile")]))

	_status = Label.new()
	_status.name = "Status"
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	col.add_child(_status)
	col.add_child(_button("Close", close, "Close"))

	_file_dialog = FileDialog.new()
	_file_dialog.use_native_dialog = true
	_file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_file_dialog.filters = PackedStringArray(["*.json, *.txt ; Wasteland Academy save"])
	_file_dialog.file_selected.connect(_on_file_chosen)
	add_child(_file_dialog)


func _button(text: String, on_press: Callable, node_name: String) -> Button:
	var b := Button.new()
	b.text = text
	b.name = node_name
	b.custom_minimum_size = Vector2(0, 96)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(on_press)
	return b


func _row(buttons: Array) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	for b in buttons:
		row.add_child(b)
	return row


## Shows the screen with this device's save as a code, ready to copy.
func open() -> void:
	_pending = {}
	_import_button.text = "Import this code"
	_box.text = current_code()
	_status.text = ""
	show()
	_box.grab_focus()


func close() -> void:
	hide()


func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		close()
		get_viewport().set_input_as_handled()


## This device's save as a code.
func current_code() -> String:
	return SaveData.export_code(SaveData.load_from(save_path))


func _on_copy() -> void:
	_box.text = current_code()
	DisplayServer.clipboard_set(_box.text)
	_status.text = "Code copied. If your device didn't copy it, select the code and copy it by hand."


func _on_save_file() -> void:
	var text := SaveData.export_text(SaveData.load_from(save_path))
	if OS.has_feature("web"):
		JavaScriptBridge.download_buffer(text.to_utf8_buffer(), FILE_NAME, "application/json")
		_status.text = "Saved %s to your downloads." % FILE_NAME
		return
	_file_dialog.file_mode = FileDialog.FILE_MODE_SAVE_FILE
	_file_dialog.current_file = FILE_NAME
	_file_dialog.set_meta("text", text)
	_file_dialog.popup_centered_ratio(0.8)


func _on_import_file() -> void:
	if OS.has_feature("web"):
		_pick_web_file()
		return
	_file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_file_dialog.remove_meta("text")
	_file_dialog.popup_centered_ratio(0.8)


func _on_file_chosen(path: String) -> void:
	if _file_dialog.has_meta("text"):
		var f := FileAccess.open(path, FileAccess.WRITE)
		if f == null:
			_status.text = "Couldn't write that file. Use Copy code instead."
			return
		f.store_string(_file_dialog.get_meta("text"))
		_status.text = "Saved to %s." % path.get_file()
		return
	_on_text_picked([FileAccess.get_file_as_string(path)])


func _pick_web_file() -> void:
	_js_callback = JavaScriptBridge.create_callback(_on_text_picked)
	JavaScriptBridge.eval("window.waPickSave = function (cb) { var i = document.createElement('input'); i.type = 'file'; i.accept = '.json,.txt,application/json,text/plain'; i.onchange = function () { var f = i.files[0]; if (f) { f.text().then(function (t) { cb(t); }); } }; i.click(); };")
	JavaScriptBridge.get_interface("window").waPickSave(_js_callback)


func _on_text_picked(args: Array) -> void:
	_box.text = str(args[0]) if not args.is_empty() else ""
	_pending = {}
	_on_import()


## First press reads the code and asks; the second, on the same code, replaces the save.
func _on_import() -> void:
	var read := SaveData.import_text(_box.text)
	if not read.ok:
		_pending = {}
		_import_button.text = "Import this code"
		_status.text = read.error
		return
	if _pending.is_empty() or _pending != read.save:
		_pending = read.save
		_import_button.text = "Press again to replace this device's save"
		_status.text = "This replaces the progress on this device. The current save is kept beside it. Press Import again to go on."
		return
	if not SaveData.replace_with(_pending, save_path):
		_status.text = "Couldn't write the save on this device. Nothing was changed."
		return
	_pending = {}
	_import_button.text = "Import this code"
	_status.text = "Imported."
	imported.emit()
	if reload_after_import and is_inside_tree() and get_tree().current_scene != null:
		close()
		get_tree().reload_current_scene()
