extends Node

# Singleton: EquipmentManager
# Tracks what the player has equipped (weapon + body armor + accessory).
# Applies stat deltas to the player whenever equipment changes.

signal equipment_changed(slot: String, item_id: String)

# Active equipment — empty string = nothing equipped
var equipped : Dictionary = {
	"weapon":    "",
	"body":      "",
	"accessory": "",
}

# Cached stat bonuses currently applied to the player
var _applied_bonus : Dictionary = {}

# ─── Init ─────────────────────────────────────────────────────────────────────
func _ready() -> void:
	_load_from_save()

func _load_from_save() -> void:
	var saved : Dictionary = SaveSystem.data.get("equipment", {})
	for slot in equipped.keys():
		equipped[slot] = saved.get(slot, "")

# ─── Equip / Unequip ──────────────────────────────────────────────────────────
func equip(item_id: String) -> bool:
	var def := ItemDB.get(item_id)
	if def.is_empty():
		return false

	var item_type : int = def.get("type", -1)
	if item_type == ItemDB.ItemType.WEAPON:
		_set_slot("weapon", item_id)
	elif item_type == ItemDB.ItemType.ARMOR:
		var armor_slot : int = def.get("armor_slot", -1)
		match armor_slot:
			ItemDB.ArmorSlot.BODY:      _set_slot("body", item_id)
			ItemDB.ArmorSlot.ACCESSORY: _set_slot("accessory", item_id)
			_: return false
	else:
		return false

	return true

func unequip(slot: String) -> void:
	if slot not in equipped:
		return
	_set_slot(slot, "")

func _set_slot(slot: String, item_id: String) -> void:
	# Remove old bonuses
	var old_id : String = equipped.get(slot, "")
	if old_id != "":
		_remove_bonuses(old_id)
		# Return old item to inventory
		Inventory.add(old_id, 1)

	equipped[slot] = item_id

	# Remove new item from inventory and apply bonuses
	if item_id != "":
		Inventory.remove(item_id, 1)
		_apply_bonuses(item_id)

	_persist()
	emit_signal("equipment_changed", slot, item_id)

# ─── Stat application ─────────────────────────────────────────────────────────
func _apply_bonuses(item_id: String) -> void:
	var player := _get_player()
	if not player:
		return
	var def := ItemDB.get(item_id)
	var bonus : Dictionary = def.get("bonus", {})
	for key in bonus.keys():
		_apply_single_bonus(player, key, bonus[key], true)

func _remove_bonuses(item_id: String) -> void:
	var player := _get_player()
	if not player:
		return
	var def := ItemDB.get(item_id)
	var bonus : Dictionary = def.get("bonus", {})
	for key in bonus.keys():
		_apply_single_bonus(player, key, bonus[key], false)

func _apply_single_bonus(player: Node, key: String, value, apply: bool) -> void:
	match key:
		"max_qi":
			player.MAX_QI += value if apply else -value
		"move_speed":
			player.MOVE_SPEED += value if apply else -value
		"poison_resist":
			player.set_meta("poison_resist", apply)

# ─── Computed stats ───────────────────────────────────────────────────────────
func get_attack_damage() -> int:
	var weapon_id : String = equipped.get("weapon", "")
	if weapon_id == "":
		return 10   # bare-hand default
	return ItemDB.get(weapon_id).get("damage", 10)

func get_attack_speed() -> float:
	var weapon_id : String = equipped.get("weapon", "")
	if weapon_id == "":
		return 1.0
	return ItemDB.get(weapon_id).get("attack_speed", 1.0)

func get_crit_chance() -> float:
	var weapon_id : String = equipped.get("weapon", "")
	if weapon_id == "":
		return 0.05
	return ItemDB.get(weapon_id).get("crit_chance", 0.05)

func get_defense() -> int:
	var total := 0
	for slot in ["body", "accessory"]:
		var id : String = equipped.get(slot, "")
		if id != "":
			total += ItemDB.get(id).get("defense", 0)
	return total

func get_weapon_type() -> int:
	var weapon_id : String = equipped.get("weapon", "")
	if weapon_id == "":
		return ItemDB.WeaponType.FIST
	return ItemDB.get(weapon_id).get("weapon_type", ItemDB.WeaponType.FIST)

# ─── Helpers ──────────────────────────────────────────────────────────────────
func _get_player() -> Node:
	return get_tree().get_first_node_in_group("player")

func _persist() -> void:
	SaveSystem.data["equipment"] = equipped.duplicate()
