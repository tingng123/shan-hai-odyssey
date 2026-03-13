extends Node2D

# Hub — Temple of Ling Yun
# Central hub between chapters: skill tree, chapter select, save shrine

@onready var player          : CharacterBody2D  = $Player
@onready var skill_tree_ui   : CanvasLayer      = $SkillTreeUI
@onready var shrine_interact : Area2D           = $Shrine/InteractArea
@onready var chapter_doors   : Array[Node]      = []
@onready var music_player    : AudioStreamPlayer = $MusicPlayer

func _ready() -> void:
	player.add_to_group("player")
	player.died.connect(_on_player_died)

	skill_tree_ui.hide()

	shrine_interact.area_entered.connect(_on_shrine_entered)
	shrine_interact.area_exited.connect(_on_shrine_exited)

	# Collect all chapter door nodes
	for door in get_tree().get_nodes_in_group("chapter_door"):
		chapter_doors.append(door)
		door.interact_pressed.connect(_on_chapter_door_pressed.bind(door))

	# Restore player health at hub
	player.health = player.max_health
	player.emit_signal("health_changed", player.health)

	music_player.play()

func _on_shrine_entered(_area: Area2D) -> void:
	# Show "Press E to save / open skill tree" prompt
	$InteractPrompt.show()

func _on_shrine_exited(_area: Area2D) -> void:
	$InteractPrompt.hide()
	skill_tree_ui.hide()

func _input(event: InputEvent) -> void:
	if event.is_action_just_pressed("interact"):
		var in_shrine := shrine_interact.has_overlapping_areas()
		if in_shrine:
			_open_skill_tree()

	if event.is_action_just_pressed("ui_cancel"):
		skill_tree_ui.hide()

func _open_skill_tree() -> void:
	SaveSystem.save()
	skill_tree_ui.show()

func _on_chapter_door_pressed(door: Node) -> void:
	var chapter_id : int = door.get_meta("chapter_id", 1)
	# Only allow entering if previous chapter is cleared (or it's chapter 1)
	if chapter_id == 1 or _is_chapter_unlocked(chapter_id):
		GameManager.go_to_chapter(chapter_id)
	else:
		$LockedPrompt.show()
		await get_tree().create_timer(1.5).timeout
		$LockedPrompt.hide()

func _is_chapter_unlocked(chapter_id: int) -> bool:
	var prev_boss_ids := ["", "bi_fang", "taotie", "hundun", "bashe", "tiangou", "nine_tailed_fox"]
	if chapter_id <= 0 or chapter_id >= prev_boss_ids.size():
		return false
	return prev_boss_ids[chapter_id] in GameManager.defeated_bosses

func _on_player_died() -> void:
	# Can't die in hub — just restore health
	player.health = player.max_health
	player.emit_signal("health_changed", player.health)
	player.state = player.State.IDLE
	player.set_physics_process(true)
