extends BaseBoss

# ─── Bi Fang — One-legged fire bird, Chapter 1 boss ─────────────────────────
# Phase 1 (100–60%): Aerial dives, fire rings
# Phase 2 (60–30%): Omen flames + faster dives
# Phase 3 (30–0%):  Enrage — continuous fire storm, charge dives

const DIVE_SPEED        := 420.0
const DIVE_WINDUP       := 0.6    # seconds telegraphing before dive
const FIRE_RING_COUNT   := 8
const FIRE_RING_SPEED   := 90.0
const OMEN_FLAME_COUNT  := 5
const ENRAGE_INTERVAL   := 1.8   # attack cooldown in phase 3

@export var fire_projectile_scene : PackedScene
@export var omen_flame_scene      : PackedScene

var attack_cooldown  := 0.0
var is_diving        := false
var dive_direction   := Vector2.ZERO
var windup_timer     := 0.0

# Attack pattern queues per phase
var pattern_p1 : Array[Callable]
var pattern_p2 : Array[Callable]
var pattern_p3 : Array[Callable]
var pattern_idx := 0

func _ready() -> void:
	super()
	boss_id       = "bi_fang"
	max_health    = 800
	health        = max_health
	phase2_thresh = 0.6
	phase3_thresh = 0.3

	pattern_p1 = [_attack_dive, _attack_fire_ring]
	pattern_p2 = [_attack_dive, _attack_omen_flames, _attack_fire_ring, _attack_dive]
	pattern_p3 = [_attack_dive, _attack_fire_storm, _attack_dive, _attack_omen_flames]

	add_to_group("boss")

func _physics_process(delta: float) -> void:
	super(delta)
	attack_cooldown = max(attack_cooldown - delta, 0.0)
	windup_timer    = max(windup_timer    - delta, 0.0)

	if is_diving:
		velocity = dive_direction * DIVE_SPEED
	elif state == State.IDLE or state == State.ATTACK:
		_hover_toward_player(delta)

func _hover_toward_player(_delta: float) -> void:
	if not player:
		return
	# Bi Fang circles the player at range rather than rushing
	var to_player := player.global_position - global_position
	var dist      := to_player.length()
	var ideal_dist := 180.0
	if dist > ideal_dist + 20.0:
		velocity = to_player.normalized() * 60.0
	elif dist < ideal_dist - 20.0:
		velocity = -to_player.normalized() * 40.0
	else:
		# Orbit
		var perp := Vector2(-to_player.y, to_player.x).normalized()
		velocity = perp * 50.0

# ─── State overrides ─────────────────────────────────────────────────────────
func _state_idle() -> void:
	if player and global_position.distance_to(player.global_position) < 400.0:
		state = State.INTRO
		_play_intro()

func _state_attack() -> void:
	if attack_cooldown > 0.0 or windup_timer > 0.0:
		return
	_next_attack()

func _on_phase_started(new_phase: Phase) -> void:
	pattern_idx = 0
	match new_phase:
		Phase.TWO:
			# anim.play("phase2_transition")
		Phase.THREE:
			# anim.play("enrage")

# ─── Intro ───────────────────────────────────────────────────────────────────
func _play_intro() -> void:
	# anim.play("intro")
	velocity = Vector2.ZERO
	await get_tree().create_timer(2.5).timeout
	state = State.ATTACK

# ─── Attack selector ─────────────────────────────────────────────────────────
func _next_attack() -> void:
	var pattern := _current_pattern()
	pattern[pattern_idx % pattern.size()].call()
	pattern_idx += 1

func _current_pattern() -> Array[Callable]:
	match phase:
		Phase.TWO:   return pattern_p2
		Phase.THREE: return pattern_p3
		_:           return pattern_p1

# ─── Attack: Dive ────────────────────────────────────────────────────────────
func _attack_dive() -> void:
	if not player:
		return
	# anim.play("dive_windup")
	windup_timer = DIVE_WINDUP
	# Aim slightly ahead of player
	var target := player.global_position + player.velocity * 0.3
	dive_direction = (target - global_position).normalized()
	await get_tree().create_timer(DIVE_WINDUP).timeout

	is_diving = true
	# anim.play("dive")
	hitbox.monitoring = true

	# End dive after crossing arena or hitting wall
	await get_tree().create_timer(0.55).timeout
	is_diving = false
	hitbox.monitoring = false
	velocity = Vector2.ZERO
	attack_cooldown = _cooldown()
	# anim.play("idle")

# ─── Attack: Fire Ring ───────────────────────────────────────────────────────
func _attack_fire_ring() -> void:
	# anim.play("fire_ring")
	for i in FIRE_RING_COUNT:
		var angle  := (TAU / FIRE_RING_COUNT) * i
		var bullet := fire_projectile_scene.instantiate()
		get_parent().add_child(bullet)
		bullet.global_position = global_position
		bullet.direction       = Vector2.from_angle(angle)
		bullet.speed           = FIRE_RING_SPEED
	attack_cooldown = _cooldown()

# ─── Attack: Omen Flames ─────────────────────────────────────────────────────
# Drops flame markers on the ground that detonate after a delay
func _attack_omen_flames() -> void:
	if not player:
		return
	# anim.play("omen_cast")
	for i in OMEN_FLAME_COUNT:
		var offset := Vector2(randf_range(-80, 80), randf_range(-80, 80))
		var flame  := omen_flame_scene.instantiate()
		get_parent().add_child(flame)
		flame.global_position = player.global_position + offset
	attack_cooldown = _cooldown()

# ─── Attack: Fire Storm (Phase 3 enrage) ─────────────────────────────────────
func _attack_fire_storm() -> void:
	# anim.play("fire_storm")
	# Rapid-fire 3 rings with slight rotation offset
	for wave in 3:
		await get_tree().create_timer(0.3).timeout
		for i in FIRE_RING_COUNT:
			var angle  := (TAU / FIRE_RING_COUNT) * i + (wave * PI / FIRE_RING_COUNT)
			var bullet := fire_projectile_scene.instantiate()
			get_parent().add_child(bullet)
			bullet.global_position = global_position
			bullet.direction       = Vector2.from_angle(angle)
			bullet.speed           = FIRE_RING_SPEED * 1.3
	attack_cooldown = ENRAGE_INTERVAL

# ─── Helpers ─────────────────────────────────────────────────────────────────
func _cooldown() -> float:
	match phase:
		Phase.TWO:   return 1.4
		Phase.THREE: return ENRAGE_INTERVAL
		_:           return 2.0
