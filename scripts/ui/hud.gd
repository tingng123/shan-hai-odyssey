extends CanvasLayer

# HUD — connects to player signals on ready

@onready var health_bar   : ProgressBar = $MarginContainer/VBox/HealthBar
@onready var stamina_bar  : ProgressBar = $MarginContainer/VBox/StaminaBar
@onready var qi_bar       : ProgressBar = $MarginContainer/VBox/QiBar
@onready var boss_panel   : Control     = $BossPanel
@onready var boss_bar     : ProgressBar = $BossPanel/BossHealthBar
@onready var boss_name_lbl: Label       = $BossPanel/BossName

func _ready() -> void:
	boss_panel.hide()
	var player := get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(_on_health_changed)
		player.stamina_changed.connect(_on_stamina_changed)
		player.qi_changed.connect(_on_qi_changed)
		health_bar.max_value  = player.max_health
		health_bar.value      = player.health
		stamina_bar.max_value = 100.0
		qi_bar.max_value      = 100.0

func _on_health_changed(hp: int) -> void:
	health_bar.value = hp

func _on_stamina_changed(val: float) -> void:
	stamina_bar.value = val

func _on_qi_changed(val: float) -> void:
	qi_bar.value = val

func show_boss(boss_name: String, boss: BaseBoss) -> void:
	boss_name_lbl.text = boss_name
	boss_bar.max_value = boss.max_health
	boss_bar.value     = boss.health
	boss_panel.show()
	boss.health_changed.connect(func(cur, _max): boss_bar.value = cur)
	boss.died.connect(func(_id): boss_panel.hide())
