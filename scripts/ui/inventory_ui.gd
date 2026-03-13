extends CanvasLayer

# InventoryUI — toggled with I key
# Shows bag slots, equipment panel, and hotbar

signal closed

const SLOT_SIZE := 48

@onready var bag_grid      : GridContainer = $Panel/VBox/HBox/BagPanel/BagGrid
@onready var equip_weapon  : TextureRect   = $Panel/VBox/HBox/EquipPanel/WeaponSlot/Icon
@onready var equip_body    : TextureRect   = $Panel/VBox/HBox/EquipPanel/BodySlot/Icon
@onready var equip_acc     : TextureRect   = $Panel/VBox/HBox/EquipPanel/AccSlot/Icon
@onready var gold_label    : Label         = $Panel/VBox/GoldRow/GoldLabel
@onready var tooltip_label : Label         = $Panel/Tooltip
@onready var hotbar_row    : HBoxContainer = $Hotbar/HBoxContainer

var _slot_nodes : Array = []   # bag slot Button nodes

# ─── Lifecycle ────────────────────────────────────────────────────────────────
func _ready() -> void:
	_build_bag_slots()
	_build_hotbar()
	Inventory.inventory_changed.connect(_refresh)
	Inventory.gold_changed.connect(_on_gold_changed)
	EquipmentManager.equipment_changed.connect(_refresh_equipment)
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_just_pressed("inventory_toggle"):
		if visible:
			_close()
		else:
			_open()

# ─── Open / Close ─────────────────────────────────────────────────────────────
func _open() -> void:
	_refresh()
	show()
	get_tree().paused = true

func _close() -> void:
	hide()
	get_tree().paused = false
	emit_signal("closed")

# ─── Build ────────────────────────────────────────────────────────────────────
func _build_bag_slots() -> void:
	for i in Inventory.MAX_SLOTS:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		btn.pressed.connect(_on_slot_pressed.bind(i))
		btn.mouse_entered.connect(_on_slot_hover.bind(i))
		btn.mouse_exited.connect(func(): tooltip_label.text = "")
		bag_grid.add_child(btn)
		_slot_nodes.append(btn)

func _build_hotbar() -> void:
	for child in hotbar_row.get_children():
		child.queue_free()
	for i in 4:
		var btn := Button.new()
		btn.custom_minimum_size = Vector2(SLOT_SIZE, SLOT_SIZE)
		btn.pressed.connect(_on_hotbar_pressed.bind(i))
		hotbar_row.add_child(btn)

# ─── Refresh ──────────────────────────────────────────────────────────────────
func _refresh() -> void:
	# Bag slots
	for i in _slot_nodes.size():
		var btn : Button = _slot_nodes[i]
		if i < Inventory.slots.size():
			var slot := Inventory.slots[i]
			var def  := ItemDB.get(slot["id"])
			btn.text = "%s\nx%d" % [def.get("name", slot["id"]), slot["qty"]]
		else:
			btn.text = ""

	# Gold
	gold_label.text = "Gold: %d" % Inventory.gold

	# Hotbar
	var hb_children := hotbar_row.get_children()
	for i in 4:
		if i < hb_children.size():
			var id := Inventory.hotbar[i]
			var label := ""
			if id != "":
				var def := ItemDB.get(id)
				label = def.get("name", id)
			hb_children[i].text = "[%d] %s" % [i + 1, label]
			# Highlight selected
			hb_children[i].modulate = Color(1.4, 1.4, 0.4) if i == Inventory.hotbar_index else Color.WHITE

	_refresh_equipment()

func _refresh_equipment() -> void:
	var eq := EquipmentManager.equipped
	_set_equip_icon(equip_weapon, eq.get("weapon", ""))
	_set_equip_icon(equip_body,   eq.get("body", ""))
	_set_equip_icon(equip_acc,    eq.get("accessory", ""))

func _set_equip_icon(icon: TextureRect, item_id: String) -> void:
	if item_id == "":
		icon.texture = null
		return
	var path := "res://assets/sprites/items/%s.png" % item_id
	if ResourceLoader.exists(path):
		icon.texture = load(path)
	else:
		icon.texture = null

# ─── Interactions ─────────────────────────────────────────────────────────────
func _on_slot_pressed(index: int) -> void:
	if index >= Inventory.slots.size():
		return
	var item_id : String = Inventory.slots[index]["id"]
	var def := ItemDB.get(item_id)

	match def.get("type"):
		ItemDB.ItemType.CONSUMABLE:
			Inventory.use(item_id)
		ItemDB.ItemType.WEAPON, ItemDB.ItemType.ARMOR:
			EquipmentManager.equip(item_id)
		_:
			pass

func _on_slot_hover(index: int) -> void:
	if index >= Inventory.slots.size():
		tooltip_label.text = ""
		return
	var item_id : String = Inventory.slots[index]["id"]
	var def := ItemDB.get(item_id)
	var lines := [def.get("name", item_id), def.get("description", "")]
	if def.has("damage"):
		lines.append("ATK: %d" % def["damage"])
	if def.has("defense"):
		lines.append("DEF: %d" % def["defense"])
	if def.has("value"):
		lines.append("Effect: +%d" % def["value"])
	tooltip_label.text = "\n".join(lines)

func _on_hotbar_pressed(slot: int) -> void:
	# Right-click to clear, left-click to set from selected bag slot
	# For simplicity: pressing hotbar slot sets it to the first matching consumable
	pass
