# level_loader.gd — Loads level data from data/levels.json
class_name LevelLoader
extends Node

var levels_data: Array = []
var _loaded: bool = false

func _ready() -> void:
	_load_levels()

func _load_levels() -> void:
	var file = FileAccess.open("res://data/levels.json", FileAccess.READ)
	if file == null:
		push_error("LevelLoader: Could not open data/levels.json")
		return
	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var err = json.parse(json_text)
	if err != OK:
		push_error("LevelLoader: JSON parse error: " + json.get_error_message())
		return

	var data = json.get_data()
	if data is Dictionary and data.has("levels"):
		levels_data = data["levels"]
		_loaded = true
	else:
		push_error("LevelLoader: Invalid levels.json format")

func get_level(level_id: int) -> Dictionary:
	if not _loaded:
		_load_levels()
	for level in levels_data:
		if level["id"] == level_id:
			return level
	push_error("LevelLoader: Level " + str(level_id) + " not found")
	return {}

func get_level_count() -> int:
	return levels_data.size()

func get_all_levels() -> Array:
	return levels_data
