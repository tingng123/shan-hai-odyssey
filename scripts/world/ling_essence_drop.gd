extends Node2D

# Ling Essence drop — spawned when enemies/bosses die
# Floats toward player and is collected on overlap

@export var value    : int   = 5
@export var lifetime : float = 12.0
@export var attract_range : float = 80.0
@export var attract_speed : float = 180.0

var _player   : CharacterBody2D = null
var _velocity : Vector2 = Vector2.ZERO
var _age      : float   = 0.0
var _attracted: bool    = false

@onready var sprite     : Sprite2D = $Sprite2D
@onready var collect_area: Area2D  = $CollectArea

func _ready() -> void:
	collect_area.area_entered.connect(_on_collect)
	# Small random pop on spawn
	_velocity = Vector2(randf_range(-60, 60), randf_range(-60, 60))

func _physics_process(delta: float) -> void:
	_age += delta
	if _age >= lifetime:
		queue_free()
		return

	if not _player:
		_player = get_tree().get_first_node_in_group("player")

	if _player:
		var dist := global_position.distance_to(_player.global_position)
		if dist < attract_range:
			_attracted = true

	if _attracted and _player:
		var dir := (_player.global_position - global_position).normalized()
		_velocity = dir * attract_speed
	else:
		_velocity = _velocity.lerp(Vector2.ZERO, 4.0 * delta)

	position += _velocity * delta

	# Pulse scale
	var pulse := 1.0 + sin(_age * 6.0) * 0.08
	sprite.scale = Vector2(pulse, pulse)

func _on_collect(area: Area2D) -> void:
	if area.is_in_group("player_hurtbox"):
		SkillTree.add_essence(value)
		queue_free()
