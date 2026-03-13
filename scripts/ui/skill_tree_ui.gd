extends CanvasLayer

# SkillTreeUI — opened from the shrine in the hub
# Displays all skills, shows unlock status, lets player spend Ling Essence

signal closed

@onready var essence_label : Label         = $Panel/VBox/TopRow/EssenceLabel
@onready var skill_list    : VBoxContainer = $Panel/VBox/ScrollContainer/SkillList
@onready var tooltip       : Label         = $Panel/Tooltip

func _ready() -> void:
	SkillTree.essence_changed.connect(_on_essence_changed)
	SkillTree.skill_unlocked.connect(func(_id): _refresh())
	hide()

func open() -> void:
	_refresh()
	show()

func _close() -> void:
	hide()
	emit_signal("closed")

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_just_pressed("ui_cancel"):
		_close()

# ─── Build / Refresh ──────────────────────────────────────────────────────────
func _refresh() -> void:
	essence_label.text = "Ling Essence: %d" % SkillTree.ling_essence

	for child in skill_list.get_children():
		child.queue_free()

	for skill in SkillTree.SKILLS:
		var row := HBoxContainer.new()

		var name_lbl := Label.new()
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var is_unlocked := SkillTree.has(skill["id"])
		var can_buy     := SkillTree.can_unlock(skill["id"])
		name_lbl.text = ("[✓] " if is_unlocked else "[ ] ") + skill["name"]
		if is_unlocked:
			name_lbl.modulate = Color(0.6, 1.0, 0.6)
		elif not can_buy:
			name_lbl.modulate = Color(0.5, 0.5, 0.5)

		var cost_lbl := Label.new()
		cost_lbl.text = "%d LE" % skill["cost"] if skill["cost"] > 0 else "Free"

		var btn := Button.new()
		btn.text = "Unlock"
		btn.disabled = is_unlocked or not can_buy
		btn.pressed.connect(_on_unlock.bind(skill["id"]))
		btn.mouse_entered.connect(_on_hover.bind(skill))
		btn.mouse_exited.connect(func(): tooltip.text = "")

		row.add_child(name_lbl)
		row.add_child(cost_lbl)
		row.add_child(btn)
		skill_list.add_child(row)

func _on_unlock(skill_id: String) -> void:
	SkillTree.unlock(skill_id)

func _on_hover(skill: Dictionary) -> void:
	var reqs : String = ", ".join(skill["requires"]) if skill["requires"].size() > 0 else "None"
	tooltip.text = "%s\nCost: %d LE\nRequires: %s" % [skill["name"], skill["cost"], reqs]

func _on_essence_changed(_amount: int) -> void:
	if visible:
		_refresh()
