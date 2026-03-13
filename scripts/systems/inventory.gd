extends Node

# Singleton: Inventory
# Manages the player's bag — add, remove, use items.
# Slots are { "id": String, "qty": int }

signal inventory_changed
signal item_used(item_id: String)
signal gold_changed(new_gold: int)

const MAX_SLOTS := 24

var slots : Array[Dictionary] = []   # up to MAX_SLOTS entries
var gold  : int = 0

# ─── Init ─────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_load_from_save()

func _load_from_save() -> void:
	gold  = SaveSystem.data.get("gold", 0)
	var raw : Array = SaveSystem.data.get("inventory", [])
	slots.clear()
	for entry in raw:
		slots.append({ "id": entry["id"], "qty": entry["qty"] })

# ─── Add / Remove ─────────────────────────────────────────────────────────────
func add(item_id: String, qty: int = 1) -> bool:
	var def := ItemDB.get(item_id)
	if def.is_empty():
		push_warning("Inventory.add: unknown item '%s'" % item_id)
		return false

	var max_stack : int = def.get("max_stack", 1)

	# Try to stack onto existing slot first
	for slot in slots:
		if slot["id"] == item_id and slot["qty"] < max_stack:
			var space := max_stack - slot["qty"]
			var add_amt := min(qty, space)
			slot["qty"] += add_amt
			qty -= add_amt
			if qty == 0:
				_persist()
				emit_signal("inventory_changed")
				return true

	# Open new slot(s)
	while qty > 0:
		if slots.size() >= MAX_SLOTS:
			push_warning("Inventory full — could not add all of '%s'" % item_id)
			emit_signal("inventory_changed")
			return false
		var add_amt := min(qty, max_stack)
		slots.append({ "id": item_id, "qty": add_amt })
		qty -= add_amt

	_persist()
	emit_signal("inventory_changed")
	return true

func remove(item_id: String, qty: int = 1) -> bool:
	if count(item_id) < qty:
		return false
	var remaining := qty
	for i in range(slots.size() - 1, -1, -1):
		if slots[i]["id"] == item_id:
			var take := min(slots[i]["qty"], remaining)
			slots[i]["qty"] -= take
			remaining -= take
			if slots[i]["qty"] == 0:
				slots.remove_at(i)
			if remaining == 0:
				break
	_persist()
	emit_signal("inventory_changed")
	return true

func count(item_id: String) -> int:
	var total := 0
	for slot in slots:
		if slot["id"] == item_id:
			total += slot["qty"]
	return total

func has_item(item_id: String, qty: int = 1) -> bool:
	return count(item_id) >= qty

# ─── Use ──────────────────────────────────────────────────────────────────────
func use(item_id: String) -> bool:
	if not has_item(item_id):
		return false
	var def := ItemDB.get(item_id)
	if def.get("type") != ItemDB.ItemType.CONSUMABLE:
		return false

	var player := get_tree().get_first_node_in_group("player")
	if not player:
		return false

	var effect : String = def.get("effect", "")
	var value  : int    = def.get("value", 0)

	match effect:
		"heal":
			if player.health >= player.max_health:
				return false   # don't consume if already full
			player.health = min(player.health + value, player.max_health)
			player.emit_signal("health_changed", player.health)
		"restore_stamina":
			player.stamina = player.MAX_STAMINA
			player.emit_signal("stamina_changed", player.stamina)
		"restore_qi":
			player.qi = min(player.qi + value, player.MAX_QI)
			player.emit_signal("qi_changed", player.qi)
		"cure_poison":
			player.set_meta("poisoned", false)
		_:
			return false

	remove(item_id, 1)
	emit_signal("item_used", item_id)
	return true

# ─── Gold ─────────────────────────────────────────────────────────────────────
func add_gold(amount: int) -> void:
	gold += amount
	SaveSystem.data["gold"] = gold
	emit_signal("gold_changed", gold)

func spend_gold(amount: int) -> bool:
	if gold < amount:
		return false
	gold -= amount
	SaveSystem.data["gold"] = gold
	emit_signal("gold_changed", gold)
	return true

# ─── Hotbar (4 quick-use slots) ───────────────────────────────────────────────
var hotbar        : Array[String] = ["", "", "", ""]
var hotbar_index  : int           = 0   # currently selected slot

func _load_hotbar() -> void:
	var saved : Array = SaveSystem.data.get("hotbar", ["potion_small", "", "", ""])
	for i in 4:
		hotbar[i] = saved[i] if i < saved.size() else ""

func hotbar_selected() -> String:
	return hotbar[hotbar_index]

func hotbar_cycle() -> void:
	hotbar_index = (hotbar_index + 1) % 4
	emit_signal("inventory_changed")

func hotbar_set(slot: int, item_id: String) -> void:
	if slot < 0 or slot >= 4:
		return
	hotbar[slot] = item_id
	SaveSystem.data["hotbar"] = hotbar.duplicate()
	emit_signal("inventory_changed")

# ─── Persist ──────────────────────────────────────────────────────────────────
func _persist() -> void:
	SaveSystem.data["inventory"] = slots.map(func(s): return { "id": s["id"], "qty": s["qty"] })
	SaveSystem.data["gold"]      = gold
	SaveSystem.data["hotbar"]    = hotbar.duplicate()
