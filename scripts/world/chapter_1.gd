extends Node2D

# Chapter 1 — Flaming Peaks
# Orchestrates the chapter flow: exploration → boss arena → victory

enum ChapterState { EXPLORING, BOSS_INTRO, BOSS_FIGHT, VICTORY }

var chapter_state : ChapterState = ChapterState.EXPLORING

@onready var player       : CharacterBody2D = $Player
@onready var hud          : CanvasLayer     = $HUD
@onready var boss_arena   : Node2D          = $BossArena
@onready var boss         : Node            = $BossArena/BiFang
@onready var arena_gate   : StaticBody2D    = $BossArena/ArenaGate
@onready var camera       : Camera2D        = $Player/Camera2D
@onready var music_player : AudioStreamPlayer = $MusicPlayer

func _ready() -> void:
	player.add_to_group("player")
	player.died.connect(_on_player_died)
	boss.died.connect(_on_boss_died)
	boss_arena.hide()
	arena_gate.process_mode = Node.PROCESS_MODE_DISABLED

func _on_boss_trigger_entered(_body: Node2D) -> void:
	if chapter_state != ChapterState.EXPLORING:
		return
	chapter_state = ChapterState.BOSS_INTRO
	_start_boss_sequence()

func _start_boss_sequence() -> void:
	# Lock arena gate behind player
	arena_gate.process_mode = Node.PROCESS_MODE_INHERIT
	boss_arena.show()

	# Camera pan to boss, then back
	var tween := create_tween()
	tween.tween_property(camera, "global_position", boss.global_position, 1.2)
	tween.tween_interval(1.0)
	tween.tween_property(camera, "global_position", player.global_position, 1.0)
	await tween.finished

	chapter_state = ChapterState.BOSS_FIGHT
	hud.show_boss("Bi Fang", boss)
	boss.state = BaseBoss.State.INTRO
	music_player.play()   # swap to boss music

func _on_boss_died(_id: String) -> void:
	chapter_state = ChapterState.VICTORY
	_play_victory()

func _play_victory() -> void:
	music_player.stop()
	# Unlock arena gate
	arena_gate.process_mode = Node.PROCESS_MODE_DISABLED

	# Grant Bi Fang transformation
	SkillTree.unlock("transform_bifang")

	# Brief pause then show chapter clear screen
	await get_tree().create_timer(3.0).timeout
	GameManager.register_boss_defeat("bi_fang")
	GameManager.go_to_hub()

func _on_player_died() -> void:
	await get_tree().create_timer(2.0).timeout
	get_tree().reload_current_scene()
