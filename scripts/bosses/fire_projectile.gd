extends Area2D

# Generic fire projectile — used by Bi Fang fire ring / fire storm

@export var speed     : float   = 90.0
@export var damage    : int     = 12
@export var lifetime  : float   = 4.0

var direction : Vector2 = Vector2.RIGHT

func _ready() -> void:
	add_to_group("enemy_hitbox")
	set_meta("damage", damage)
	area_entered.connect(_on_hit)
	get_tree().create_timer(lifetime).timeout.connect(queue_free)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_hit(area: Area2D) -> void:
	if area.is_in_group("player_hurtbox"):
		queue_free()
