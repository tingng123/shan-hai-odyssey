extends BaseEnemy

# Yaoguai — basic melee enemy for Chapter 1 exploration
# Drops Ling Essence on death

@export var essence_drop_scene : PackedScene
@export var essence_value      : int = 3

const ATTACK_COOLDOWN := 1.2
const LUNGE_SPEED     := 220.0
const LUNGE_DURATION  := 0.18

var attack_cd  : float = 0.0
var is_lunging : bool  = false

func _ready() -> void:
	super()
	max_health   = 30
	move_speed   = 65.0
	attack_dmg   = 8
	attack_range = 28.0
	chase_range  = 180.0
	health       = max_health
	died.connect(_on_died)

func _physics_process(delta: float) -> void:
	super(delta)
	attack_cd = max(attack_cd - delta, 0.0)

func _state_attack() -> void:
	if attack_cd > 0.0 or is_lunging:
		return
	_lunge()

func _lunge() -> void:
	if not player:
		return
	is_lunging = true
	attack_cd  = ATTACK_COOLDOWN
	anim.play("attack")
	hitbox.monitoring = true

	var dir := (player.global_position - global_position).normalized()
	velocity = dir * LUNGE_SPEED

	await get_tree().create_timer(LUNGE_DURATION).timeout
	velocity = Vector2.ZERO
	hitbox.monitoring = false
	is_lunging = false
	state = State.CHASE

func _on_died(_enemy: BaseEnemy) -> void:
	if essence_drop_scene:
		var drop := essence_drop_scene.instantiate()
		get_parent().add_child(drop)
		drop.global_position = global_position
		drop.value = essence_value
