extends Node

# Singleton: SaveSystem
# Handles save/load via JSON to user://

const SAVE_PATH := "user://save.json"

var data : Dictionary = {
	"health":          100,
	"qi":              0.0,
	"current_chapter": 0,
	"defeated_bosses": [],
	"collected_relics": [],
	"skills_unlocked": [],
	"playtime":        0.0,
}

func save() -> void:
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data))
	file.close()

func load_save() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var parsed := JSON.parse_string(file.get_as_text())
	file.close()
	if parsed is Dictionary:
		data.merge(parsed, true)
		return true
	return false

func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	data = {
		"health":          100,
		"qi":              0.0,
		"current_chapter": 0,
		"defeated_bosses": [],
		"collected_relics": [],
		"skills_unlocked": [],
		"playtime":        0.0,
	}
