extends Node

# Singleton: TransformationSystem
# Lets the player temporarily become a mini-version of a defeated boss

signal transformation_started(boss_id: String)
signal transformation_ended(boss_id: String)

const TRANSFORM_DURATION := 8.0
const QI_COST            := 60.0

var active_transform : String = ""
var transform_timer  : float  = 0.0
var is_transformed   : bool   = false

# Maps boss_id -> transformation config
const TRANSFORMS : Dictionary = {
	"bi_fang": {
		"name":        "Bi Fang Form",
		"move_speed":  220.0,
		"special":     "fire_dash",     # dashes and leaves fire trail
		"anim_prefix": "bifang_",
	},
	"taotie": {
		"name":        "Taotie Form",
		"move_speed":  140.0,
		"special":     "devour",        # absorbs one projectile
		"anim_prefix": "taotie_",
	},
	"bashe": {
		"name":        "Bashe Form",
		"move_speed":  180.0,
		"special":     "poison_trail",  # leaves poison on ground
		"anim_prefix": "bashe_",
	},
}

var _player : CharacterBody2D = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	if not is_transformed:
		return
	transform_timer -= delta
	if transform_timer <= 0.0:
		end_transformation()

func try_transform(boss_id: String) -> bool:
	if is_transformed:
		return false
	if not SkillTree.has("transform_%s" % boss_id):
		return false
	if not _player:
		_player = get_tree().get_first_node_in_group("player")
	if not _player or _player.qi < QI_COST:
		return false

	_player.qi -= QI_COST
	_player.emit_signal("qi_changed", _player.qi)
	active_transform = boss_id
	transform_timer  = TRANSFORM_DURATION
	is_transformed   = true

	var cfg : Dictionary = TRANSFORMS[boss_id]
	_player.MOVE_SPEED = cfg["move_speed"]   # override speed
	_player.anim.play(cfg["anim_prefix"] + "idle")
	emit_signal("transformation_started", boss_id)
	return true

func end_transformation() -> void:
	if not is_transformed:
		return
	is_transformed = false
	var prev := active_transform
	active_transform = ""
	transform_timer  = 0.0

	if _player:
		_player.MOVE_SPEED = 160.0   # restore default
		_player.anim.play("idle")
	emit_signal("transformation_ended", prev)

func use_special() -> void:
	if not is_transformed or active_transform.is_empty():
		return
	var special : String = TRANSFORMS[active_transform]["special"]
	match special:
		"fire_dash":    _special_fire_dash()
		"devour":       _special_devour()
		"poison_trail": _special_poison_trail()

func _special_fire_dash() -> void:
	if not _player:
		return
	# Short invincible dash that scorches the path
	_player.is_invincible = true
	var dir := Vector2.from_angle(_player.rotation)
	_player.velocity = dir * 500.0
	await get_tree().create_timer(0.25).timeout
	_player.is_invincible = false

func _special_devour() -> void:
	# Absorb the nearest enemy projectile and convert to health
	var projectiles := get_tree().get_nodes_in_group("enemy_projectile")
	if projectiles.is_empty():
		return
	var nearest : Node2D = null
	var min_dist := INF
	for p in projectiles:
		var d := _player.global_position.distance_to(p.global_position)
		if d < min_dist:
			min_dist = d
			nearest = p
	if nearest and min_dist < 120.0:
		nearest.queue_free()
		_player.health = min(_player.health + 15, _player.max_health)
		_player.emit_signal("health_changed", _player.health)

func _special_poison_trail() -> void:
	# Spawning handled by a trail emitter attached to player in scene
	if _player:
		_player.emit_signal("state_changed", _player.state)   # trigger trail FX
