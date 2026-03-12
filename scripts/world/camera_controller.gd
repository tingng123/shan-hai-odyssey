extends Camera2D

# Pixel-perfect camera with shake and slow-mo zoom punch

const SHAKE_DECAY   := 5.0
const ZOOM_DEFAULT  := Vector2(2.0, 2.0)   # 4× upscale at 2× zoom
const ZOOM_PARRY    := Vector2(2.4, 2.4)   # punch in on parry
const ZOOM_SPEED    := 8.0

var shake_strength : float = 0.0
var target_zoom    : Vector2 = ZOOM_DEFAULT

func _ready() -> void:
	zoom = ZOOM_DEFAULT
	position_smoothing_enabled = true
	position_smoothing_speed   = 10.0

	# Connect to player signals
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.parry_triggered.connect(_on_parry)
		player.died.connect(_on_player_died)

func _process(delta: float) -> void:
	# Shake decay
	if shake_strength > 0.0:
		offset = Vector2(
			randf_range(-shake_strength, shake_strength),
			randf_range(-shake_strength, shake_strength)
		)
		shake_strength = lerpf(shake_strength, 0.0, SHAKE_DECAY * delta)
		if shake_strength < 0.5:
			shake_strength = 0.0
			offset = Vector2.ZERO

	# Smooth zoom
	zoom = zoom.lerp(target_zoom, ZOOM_SPEED * delta)

# ─── Public API ──────────────────────────────────────────────────────────────
func shake(strength: float = 8.0) -> void:
	shake_strength = max(shake_strength, strength)

func zoom_punch(target: Vector2, duration: float = 0.3) -> void:
	target_zoom = target
	await get_tree().create_timer(duration).timeout
	target_zoom = ZOOM_DEFAULT

# ─── Signal handlers ─────────────────────────────────────────────────────────
func _on_parry() -> void:
	zoom_punch(ZOOM_PARRY, 0.25)
	shake(4.0)

func _on_player_died() -> void:
	shake(12.0)
