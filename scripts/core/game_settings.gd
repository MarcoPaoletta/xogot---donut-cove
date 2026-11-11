class_name GameSettings
extends RefCounted
## `user://settings.json`: fullscreen and the best time. A missing or corrupt
## file starts fresh without an error on screen. The mute state is written
## too, but the game always boots muted.

const PATH: String = "user://settings.json"

static var data: Dictionary = {}
static var _loaded: bool = false


static func load_settings() -> void:
	_loaded = true
	data = {"fullscreen": false, "best_time": 0.0, "muted": true}
	if not FileAccess.file_exists(PATH):
		return
	var text: String = FileAccess.get_file_as_string(PATH)
	var parsed: Variant = JSON.parse_string(text)
	if parsed is Dictionary:
		for key: String in (parsed as Dictionary).keys():
			data[key] = (parsed as Dictionary)[key]


static func save_settings() -> void:
	var file: FileAccess = FileAccess.open(PATH, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(data, "\t"))
		file.close()


static func get_value(key: String, fallback: Variant) -> Variant:
	if not _loaded:
		load_settings()
	return data.get(key, fallback)


static func set_value(key: String, value: Variant) -> void:
	if not _loaded:
		load_settings()
	data[key] = value
	save_settings()


## Applies the saved fullscreen choice to the window.
static func apply_fullscreen(window: Window) -> void:
	var on: bool = bool(get_value("fullscreen", false))
	window.mode = Window.MODE_FULLSCREEN if on else Window.MODE_WINDOWED


static func toggle_fullscreen(window: Window) -> bool:
	var on: bool = not bool(get_value("fullscreen", false))
	set_value("fullscreen", on)
	apply_fullscreen(window)
	return on
