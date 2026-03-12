extends Node
class_name BaseBoss

# ─── Phase Enum ──────────────────────────────────────────────────────────────
enum Phase { ONE, TWO, THREE }
enum State { IDLE, INTRO, ATTACK, TRANSITION, DEAD }

# ─── Stats (override in subclass) ────────────────────────────────────────────
@export var boss_id       : String = "base_boss"
@export var max_health    : int    = 1000
@export var phase2_thresh : float  = 0.6   # 60% hp triggers phase 2
@export var phase3_thresh : float  = 0.3   # 30% hp triggers phase 3

var health  : int
var phase   : Phase = Phase.ONE
var state   : State = State.IDLE

signal health_changed(current: int, maximum: int)
signal phase_changed(new_phase: Phase)
signal died(boss_id: String)

@onready var anim         : AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox       : Area2D           = $Hitbox
@onready var hurtbox      : Area2D           = $Hurtbox

var player : CharacterBody2D = null

func _ready() -> void:
	health = max_health
	hurtbox.area_entered.connect(_on_hurtbox_hit)

func _physics_process(_delta: float) -> void:
	if not player:
		player = get_tree().get_first_node_in_group("player")

	match state:
		State.IDLE:       _state_idle()
		State.INTRO:      pass   # handled by subclass cutscene
		State.ATTACK:     _state_attack()
		State.TRANSITION: pass   # locked during phase change
		State.DEAD:       pass

func _state_idle() -> void:
	pass   # subclass decides when to start

func _state_attack() -> void:
	pass   # subclass implements attack patterns

# ─── Damage ──────────────────────────────────────────────────────────────────
func take_damage(amount: int) -> void:
	if state == State.DEAD or state == State.TRANSITION:
		return
	health -= amount
	health = max(health, 0)
	emit_signal("health_changed", health, max_health)
	_check_phase_transition()
	if health == 0:
		_die()

func _on_hurtbox_hit(area: Area2D) -> void:
	if area.is_in_group("player_hitbox"):
		take_damage(area.get_meta("damage", 15))

# ─── Phase transitions ───────────────────────────────────────────────────────
func _check_phase_transition() -> void:
	var ratio := float(health) / float(max_health)
	if phase == Phase.ONE and ratio <= phase2_thresh:
		_transition_to(Phase.TWO)
	elif phase == Phase.TWO and ratio <= phase3_thresh:
		_transition_to(Phase.THREE)

func _transition_to(new_phase: Phase) -> void:
	phase = new_phase
	state = State.TRANSITION
	emit_signal("phase_changed", phase)
	anim.play("phase_transition")
	await get_tree().create_timer(2.0).timeout
	state = State.ATTACK
	_on_phase_started(phase)

func _on_phase_started(_new_phase: Phase) -> void:
	pass   # subclass overrides to swap attack patterns

# ─── Death ───────────────────────────────────────────────────────────────────
func _die() -> void:
	state = State.DEAD
	anim.play("death")
	emit_signal("died", boss_id)
	GameManager.register_boss_defeat(boss_id)
	await get_tree().create_timer(3.0).timeout
	queue_free()
