extends Area2D

# Omen flame — telegraphed ground marker that detonates after a delay

@export var warn_duration : float = 1.8
@export var damage        : int   = 20

@onready var warning_sprite : Sprite2D         = $WarningSprite
@onready var explode_area   : CollisionShape2D = $ExplodeShape

func _ready() -> void:
	add_to_group("enemy_hitbox")
	set_meta("damage", damage)
	explode_area.disabled = true
	# Pulse the warning sprite via tween instead of AnimationPlayer
	_pulse_warning()
	await get_tree().create_timer(warn_duration).timeout
	_explode()

func _pulse_warning() -> void:
	var tween := create_tween().set_loops()
	tween.tween_property(warning_sprite, "modulate:a", 0.2, 0.3)
	tween.tween_property(warning_sprite, "modulate:a", 1.0, 0.3)

func _explode() -> void:
	warning_sprite.modulate = Color(1, 0.5, 0, 1)
	explode_area.disabled = false
	monitoring = true
	area_entered.connect(_on_hit)
	await get_tree().create_timer(0.25).timeout
	queue_free()

func _on_hit(area: Area2D) -> void:
	if area.is_in_group("player_hurtbox"):
		pass   # damage handled via player hurtbox signal
