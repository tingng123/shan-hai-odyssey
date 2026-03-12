extends Node

# Singleton: GameManager
# Handles slow-mo, scene transitions, global game state

signal chapter_started(chapter_id: int)
signal chapter_completed(chapter_id: int)
signal boss_defeated(boss_id: String)

const SLOWMO_SCALE    := 0.15
const SLOWMO_DURATION := 0.4

var current_chapter   := 0
var defeated_bosses   : Array[String] = []
var collected_relics  : Array[String] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

# Called by player parry_triggered signal
func trigger_slow_mo() -> void:
	Engine.time_scale = SLOWMO_SCALE
	await get_tree().create_timer(SLOWMO_DURATION, true, false, true).timeout
	Engine.time_scale = 1.0

func go_to_chapter(chapter_id: int) -> void:
	current_chapter = chapter_id
	emit_signal("chapter_started", chapter_id)
	var scene_path := "res://scenes/world/chapter_%d.tscn" % chapter_id
	get_tree().change_scene_to_file(scene_path)

func go_to_hub() -> void:
	get_tree().change_scene_to_file("res://scenes/hub/hub.tscn")

func register_boss_defeat(boss_id: String) -> void:
	if boss_id not in defeated_bosses:
		defeated_bosses.append(boss_id)
	emit_signal("boss_defeated", boss_id)
