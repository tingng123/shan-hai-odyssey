extends CanvasLayer

# ShopUI — opened by interacting with a merchant NPC
# Displays items for sale; player buys with gold

signal closed

var _stock : Array[String] = []   # item IDs this shop sells

@onready var item_list   : VBoxContainer = $Panel/VBox/ScrollContainer/ItemList
@onready var gold_label  : Label         = $Panel/VBox/TopRow/GoldLabel
@onready var tooltip     : Label         = $Panel/Tooltip
@onready var title_label : Label         = $Panel/VBox/TopRow/TitleLabel

# ─── Open ─────────────────────────────────────────────────────────────────────
func open(stock: Array[String], shop_name: String = "Merchant") -> void:
	_stock = stock
	title_label.text = shop_name
	_build_list()
	_refresh_gold()
	show()
	get_tree().paused = true

func _close() -> void:
	hide()
	get_tree().paused = false
	emit_signal("closed")

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_just_pressed("ui_cancel"):
		_close()

# ─── Build ────────────────────────────────────────────────────────────────────
func _build_list() -> void:
	for child in item_list.get_children():
		child.queue_free()

	for item_id in _stock:
		var def := ItemDB.get(item_id)
		if def.is_empty():
			continue

		var row := HBoxContainer.new()

		var name_lbl := Label.new()
		name_lbl.text = def.get("name", item_id)
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var price_lbl := Label.new()
		var price : int = def.get("price", 0)
		price_lbl.text = "%d G" % price

		var buy_btn := Button.new()
		buy_btn.text = "Buy"
		buy_btn.pressed.connect(_on_buy.bind(item_id, price))
		buy_btn.mouse_entered.connect(_on_hover.bind(item_id))
		buy_btn.mouse_exited.connect(func(): tooltip.text = "")

		row.add_child(name_lbl)
		row.add_child(price_lbl)
		row.add_child(buy_btn)
		item_list.add_child(row)

# ─── Buy ──────────────────────────────────────────────────────────────────────
func _on_buy(item_id: String, price: int) -> void:
	if not Inventory.spend_gold(price):
		tooltip.text = "Not enough gold!"
		return
	Inventory.add(item_id, 1)
	_refresh_gold()
	tooltip.text = "Purchased %s." % ItemDB.get(item_id).get("name", item_id)

func _on_hover(item_id: String) -> void:
	var def := ItemDB.get(item_id)
	var lines := [def.get("name", item_id), def.get("description", "")]
	if def.has("damage"):
		lines.append("ATK: %d" % def["damage"])
	if def.has("defense"):
		lines.append("DEF: %d" % def["defense"])
	lines.append("Price: %d G" % def.get("price", 0))
	tooltip.text = "\n".join(lines)

func _refresh_gold() -> void:
	gold_label.text = "Gold: %d" % Inventory.gold
