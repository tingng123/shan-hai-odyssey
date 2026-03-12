extends Area2D

# Omen flame — telegraphed ground marker that detonates after a delay

@export var warn_duration : float = 1.8   # time showing warning before explode
@export var damage        : int   = 20
@export var explode_radius: float = 40.0

@onready var warning_sprite : Sprite2D    = $WarningSprite
@onready var explode_area   : CollisionShape2D = $ExplodeShape
@onready var anim_player    : AnimationPlayer  = $AnimationPlayer

func _ready() -> void:
	add_to_group("enemy_hitbox")
	set_meta("damage", damage)
	explode_area.disabled = true
	anim_player.play("warning_pulse")
	await get_tree().create_timer(warn_duration).timeout
	_explode()

func _explode() -> void:
	anim_player.play("explode")
	explode_area.disabled = false
	monitoring = true
	area_entered.connect(_on_hit)
	await get_tree().create_timer(0.25).timeout
	queue_free()

func _on_hit(area: Area2D) -> void:
	if area.is_in_group("player_hurtbox"):
		pass   # damage handled via player hurtbox signal
