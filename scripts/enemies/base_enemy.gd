extends CharacterBody2D
class_name BaseEnemy

# ─── State Enum ──────────────────────────────────────────────────────────────
enum State { IDLE, PATROL, CHASE, ATTACK, HURT, DEAD }

# ─── Stats (override in subclass) ────────────────────────────────────────────
@export var max_health  : int   = 30
@export var move_speed  : float = 60.0
@export var attack_dmg  : int   = 10
@export var attack_range: float = 32.0
@export var chase_range : float = 200.0

var health : int
var state  : State = State.IDLE

signal died(enemy: BaseEnemy)

@onready var anim    : AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox  : Area2D           = $Hitbox
@onready var nav     : NavigationAgent2D = $NavigationAgent2D

var player : CharacterBody2D = null

func _ready() -> void:
	health = max_health
	add_to_group("enemies")
	hitbox.set_meta("damage", attack_dmg)

func _physics_process(_delta: float) -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player")

	match state:
		State.IDLE:    _state_idle()
		State.CHASE:   _state_chase()
		State.ATTACK:  _state_attack()
		State.HURT:    pass
		State.DEAD:    pass

	move_and_slide()

func _state_idle() -> void:
	velocity = Vector2.ZERO
	if player and global_position.distance_to(player.global_position) < chase_range:
		state = State.CHASE

func _state_chase() -> void:
	if not player:
		return
	var dist := global_position.distance_to(player.global_position)
	if dist <= attack_range:
		state = State.ATTACK
		return
	nav.target_position = player.global_position
	var next := nav.get_next_path_position()
	velocity = (next - global_position).normalized() * move_speed

func _state_attack() -> void:
	velocity = Vector2.ZERO
	# Subclasses override with actual attack logic

func take_damage(amount: int) -> void:
	if state == State.DEAD:
		return
	health -= amount
	health = max(health, 0)
	if health == 0:
		_die()
	else:
		state = State.HURT
		anim.play("hurt")
		await get_tree().create_timer(0.3).timeout
		state = State.CHASE

func _die() -> void:
	state = State.DEAD
	anim.play("death")
	emit_signal("died", self)
	await get_tree().create_timer(1.0).timeout
	queue_free()
