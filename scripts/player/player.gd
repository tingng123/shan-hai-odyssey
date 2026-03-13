extends CharacterBody2D

# ─── Constants ───────────────────────────────────────────────────────────────
var   MOVE_SPEED        := 160.0   # var — equipment bonuses can modify
const DODGE_SPEED       := 380.0
const DODGE_DURATION    := 0.22
const DODGE_COOLDOWN    := 0.6
const PARRY_WINDOW      := 0.18
const HEAVY_HOLD_TIME   := 0.35   # seconds to trigger heavy attack
const COMBO_TIMEOUT     := 0.55   # window to chain next light hit
const MAX_STAMINA       := 100.0
const STAMINA_REGEN     := 20.0   # per second
const DODGE_COST        := 25.0
const HEAVY_COST        := 30.0
var   MAX_QI            := 100.0  # var — equipment bonuses can modify
const QI_REGEN          := 5.0    # per second

# ─── State Enum ──────────────────────────────────────────────────────────────
enum State {
	IDLE,
	MOVE,
	ATTACK_LIGHT,
	ATTACK_HEAVY_CHARGE,
	ATTACK_HEAVY,
	DODGE,
	PARRY,
	PARRY_SUCCESS,
	HURT,
	DEAD,
}

# ─── Stats ───────────────────────────────────────────────────────────────────
var max_health    := 100
var health        := max_health
var stamina       := MAX_STAMINA
var qi            := 0.0

# ─── State tracking ──────────────────────────────────────────────────────────
var state         : State = State.IDLE
var combo_step    := 0          # 0-2 for 3-hit light chain
var combo_timer   := 0.0
var dodge_timer   := 0.0
var dodge_cd      := 0.0
var parry_timer   := 0.0
var heavy_held    := 0.0
var attack_timer  := 0.0        # locks movement during attack animation
var hurt_timer    := 0.0
var is_invincible := false      # true during dodge / parry success

# ─── Signals ─────────────────────────────────────────────────────────────────
signal health_changed(new_hp: int)
signal stamina_changed(new_stamina: float)
signal qi_changed(new_qi: float)
signal state_changed(new_state: State)
signal parry_triggered                  # emit to slow time externally
signal died

# ─── Node refs (assign in scene) ─────────────────────────────────────────────
@onready var anim       : AnimatedSprite2D = $AnimatedSprite2D
@onready var hitbox     : Area2D           = $Hitbox
@onready var hurtbox    : Area2D           = $Hurtbox
@onready var parry_area : Area2D           = $ParryArea

# ─────────────────────────────────────────────────────────────────────────────
func _ready() -> void:
	hurtbox.area_entered.connect(_on_hurtbox_hit)

func _physics_process(delta: float) -> void:
	_tick_timers(delta)
	_regen_resources(delta)

	match state:
		State.IDLE, State.MOVE:
			_handle_movement(delta)
			_handle_combat_input()
		State.ATTACK_LIGHT:
			_handle_light_attack_active(delta)
		State.ATTACK_HEAVY_CHARGE:
			_handle_heavy_charge(delta)
		State.ATTACK_HEAVY:
			_handle_heavy_active(delta)
		State.DODGE:
			_handle_dodge_active(delta)
		State.PARRY:
			_handle_parry_active(delta)
		State.PARRY_SUCCESS:
			pass   # frozen briefly — handled by timer
		State.HURT:
			pass
		State.DEAD:
			pass

	move_and_slide()

# ─── Timers & regen ──────────────────────────────────────────────────────────
func _tick_timers(delta: float) -> void:
	combo_timer  = max(combo_timer  - delta, 0.0)
	dodge_cd     = max(dodge_cd     - delta, 0.0)
	attack_timer = max(attack_timer - delta, 0.0)
	hurt_timer   = max(hurt_timer   - delta, 0.0)
	parry_timer  = max(parry_timer  - delta, 0.0)
	dodge_timer  = max(dodge_timer  - delta, 0.0)

	if combo_timer == 0.0 and state == State.ATTACK_LIGHT and attack_timer == 0.0:
		combo_step = 0
		_set_state(State.IDLE)

	if attack_timer == 0.0 and state == State.ATTACK_HEAVY:
		_set_state(State.IDLE)

	if parry_timer == 0.0 and state == State.PARRY:
		_set_state(State.IDLE)

	if parry_timer == 0.0 and state == State.PARRY_SUCCESS:
		is_invincible = false
		_set_state(State.IDLE)

	if dodge_timer == 0.0 and state == State.DODGE:
		is_invincible = false
		_set_state(State.IDLE)

	if hurt_timer == 0.0 and state == State.HURT:
		_set_state(State.IDLE)

func _regen_resources(delta: float) -> void:
	if state not in [State.DODGE, State.ATTACK_HEAVY_CHARGE, State.ATTACK_HEAVY]:
		stamina = min(stamina + STAMINA_REGEN * delta, MAX_STAMINA)
		emit_signal("stamina_changed", stamina)

	if state not in [State.DEAD]:
		qi = min(qi + QI_REGEN * delta, MAX_QI)
		emit_signal("qi_changed", qi)

# ─── Movement ────────────────────────────────────────────────────────────────
func _handle_movement(delta: float) -> void:
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	velocity = dir * MOVE_SPEED
	_set_state(State.MOVE if dir.length() > 0.1 else State.IDLE)
	_face_mouse()

func _face_mouse() -> void:
	var mouse_dir := get_global_mouse_position() - global_position
	if mouse_dir.length() > 4.0:
		rotation = mouse_dir.angle()

# ─── Combat input ────────────────────────────────────────────────────────────
func _handle_combat_input() -> void:
	# Quick-use item (Tab cycles hotbar, F uses selected)
	if Input.is_action_just_pressed("hotbar_cycle"):
		Inventory.hotbar_cycle()
	if Input.is_action_just_pressed("item_use"):
		Inventory.use(Inventory.hotbar_selected())

	# Dodge
	if Input.is_action_just_pressed("dodge") and dodge_cd == 0.0 and stamina >= DODGE_COST:
		_start_dodge()
		return

	# Parry
	if Input.is_action_just_pressed("parry"):
		_start_parry()
		return

	# Heavy — hold to charge
	if Input.is_action_pressed("attack_heavy"):
		heavy_held += get_physics_process_delta_time()
		if heavy_held >= HEAVY_HOLD_TIME and stamina >= HEAVY_COST:
			_set_state(State.ATTACK_HEAVY_CHARGE)
		return
	elif Input.is_action_just_released("attack_heavy") and heavy_held > 0.0:
		heavy_held = 0.0
		if state == State.ATTACK_HEAVY_CHARGE:
			_release_heavy()
		return
	else:
		heavy_held = 0.0

	# Light combo
	if Input.is_action_just_pressed("attack_light"):
		_start_light_attack()

# ─── Light attack ────────────────────────────────────────────────────────────
func _start_light_attack() -> void:
	if combo_step < 3 and (state == State.IDLE or state == State.MOVE or
			(state == State.ATTACK_LIGHT and combo_timer > 0.0)):
		combo_step = (combo_step % 3) + 1
		combo_timer  = COMBO_TIMEOUT
		attack_timer = 0.25
		_set_state(State.ATTACK_LIGHT)
		anim.play("attack_light_%d" % combo_step)
		_activate_hitbox(0.25)

func _handle_light_attack_active(_delta: float) -> void:
	velocity = Vector2.ZERO   # root during swing

# ─── Heavy attack ────────────────────────────────────────────────────────────
func _handle_heavy_charge(_delta: float) -> void:
	velocity = Vector2.ZERO
	anim.play("attack_heavy_charge")

func _release_heavy() -> void:
	stamina -= HEAVY_COST
	emit_signal("stamina_changed", stamina)
	attack_timer = 0.45
	_set_state(State.ATTACK_HEAVY)
	anim.play("attack_heavy_release")
	_activate_hitbox(0.45)

func _handle_heavy_active(_delta: float) -> void:
	velocity = Vector2.ZERO

# ─── Dodge ───────────────────────────────────────────────────────────────────
func _start_dodge() -> void:
	stamina -= DODGE_COST
	emit_signal("stamina_changed", stamina)
	dodge_cd    = DODGE_COOLDOWN
	dodge_timer = DODGE_DURATION
	is_invincible = true
	var dir := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if dir.length() < 0.1:
		dir = Vector2.from_angle(rotation)   # dodge forward if no input
	velocity = dir.normalized() * DODGE_SPEED
	_set_state(State.DODGE)
	anim.play("dodge")

func _handle_dodge_active(_delta: float) -> void:
	pass   # velocity set on entry, decays naturally via move_and_slide

# ─── Parry ───────────────────────────────────────────────────────────────────
func _start_parry() -> void:
	parry_timer = PARRY_WINDOW
	is_invincible = false
	_set_state(State.PARRY)
	anim.play("parry")
	parry_area.monitoring = true

func _handle_parry_active(_delta: float) -> void:
	velocity = Vector2.ZERO

func trigger_parry_success() -> void:
	# Called externally when an attack lands during parry window
	parry_area.monitoring = false
	parry_timer = 0.3   # brief freeze
	is_invincible = true
	_set_state(State.PARRY_SUCCESS)
	anim.play("parry_success")
	emit_signal("parry_triggered")   # let GameManager apply slow-mo

# ─── Damage ──────────────────────────────────────────────────────────────────
func take_damage(amount: int) -> void:
	if is_invincible or state == State.DEAD:
		return
	if state == State.PARRY:
		trigger_parry_success()
		return
	# Subtract defense from equipped armor (minimum 1 damage)
	var defense := EquipmentManager.get_defense() if Engine.has_singleton("EquipmentManager") else 0
	var final_dmg := max(amount - defense, 1)
	health -= final_dmg
	health = max(health, 0)
	emit_signal("health_changed", health)
	if health == 0:
		_die()
	else:
		hurt_timer = 0.3
		_set_state(State.HURT)
		anim.play("hurt")

func _on_hurtbox_hit(area: Area2D) -> void:
	if area.is_in_group("enemy_hitbox"):
		take_damage(area.get_meta("damage", 10))

# ─── Death ───────────────────────────────────────────────────────────────────
func _die() -> void:
	_set_state(State.DEAD)
	anim.play("death")
	set_physics_process(false)
	emit_signal("died")

# ─── Hitbox helper ───────────────────────────────────────────────────────────
func _activate_hitbox(duration: float) -> void:
	# Stamp current weapon damage onto hitbox so enemies read it
	var dmg := EquipmentManager.get_attack_damage() if Engine.has_singleton("EquipmentManager") else 10
	hitbox.set_meta("damage", dmg)
	hitbox.monitoring = true
	await get_tree().create_timer(duration * 0.5).timeout
	hitbox.monitoring = false

# ─── State setter ────────────────────────────────────────────────────────────
func _set_state(new_state: State) -> void:
	if state == new_state:
		return
	state = new_state
	emit_signal("state_changed", state)
