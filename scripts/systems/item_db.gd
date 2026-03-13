extends Node

# Singleton: ItemDB
# All item definitions in one place. Scripts reference items by string ID only.

enum ItemType { CONSUMABLE, WEAPON, ARMOR, MATERIAL }
enum WeaponType { SWORD, SPEAR, FIST }
enum ArmorSlot { BODY, ACCESSORY }

# ─── Master item table ────────────────────────────────────────────────────────
# Keys every item must have:
#   id, name, description, type, icon, max_stack
# Consumables add:  effect, value
# Weapons add:      weapon_type, damage, attack_speed, crit_chance, price
# Armor adds:       armor_slot, defense, bonus (dict of stat->value), price
# Materials add:    price

const ITEMS : Dictionary = {

	# ── Consumables ──────────────────────────────────────────────────────────
	"potion_small": {
		"id": "potion_small", "type": ItemType.CONSUMABLE,
		"name": "Minor Healing Draught",
		"description": "Restores 30 HP. Brewed from mountain herbs.",
		"icon": "res://assets/sprites/ui/items/potion_small.png",
		"max_stack": 9,
		"effect": "heal", "value": 30,
		"price": 40,
	},
	"potion_large": {
		"id": "potion_large", "type": ItemType.CONSUMABLE,
		"name": "Greater Healing Draught",
		"description": "Restores 80 HP.",
		"icon": "res://assets/sprites/ui/items/potion_large.png",
		"max_stack": 5,
		"effect": "heal", "value": 80,
		"price": 100,
	},
	"stamina_tonic": {
		"id": "stamina_tonic", "type": ItemType.CONSUMABLE,
		"name": "Stamina Tonic",
		"description": "Instantly refills stamina.",
		"icon": "res://assets/sprites/ui/items/stamina_tonic.png",
		"max_stack": 5,
		"effect": "restore_stamina", "value": 100,
		"price": 60,
	},
	"qi_pill": {
		"id": "qi_pill", "type": ItemType.CONSUMABLE,
		"name": "Qi Condensing Pill",
		"description": "Fills the Qi meter by 50.",
		"icon": "res://assets/sprites/ui/items/qi_pill.png",
		"max_stack": 5,
		"effect": "restore_qi", "value": 50,
		"price": 80,
	},
	"antidote": {
		"id": "antidote", "type": ItemType.CONSUMABLE,
		"name": "Antidote",
		"description": "Cures poison.",
		"icon": "res://assets/sprites/ui/items/antidote.png",
		"max_stack": 9,
		"effect": "cure_poison", "value": 0,
		"price": 30,
	},

	# ── Weapons ──────────────────────────────────────────────────────────────
	"sword_iron": {
		"id": "sword_iron", "type": ItemType.WEAPON,
		"name": "Iron Dao",
		"description": "A sturdy iron blade. Reliable, nothing more.",
		"icon": "res://assets/sprites/ui/items/sword_iron.png",
		"max_stack": 1,
		"weapon_type": WeaponType.SWORD,
		"damage": 14, "attack_speed": 1.0, "crit_chance": 0.05,
		"price": 150,
	},
	"sword_flame": {
		"id": "sword_flame", "type": ItemType.WEAPON,
		"name": "Bi Fang Blade",
		"description": "Forged from Bi Fang's feathers. Light attacks leave a fire trail.",
		"icon": "res://assets/sprites/ui/items/sword_flame.png",
		"max_stack": 1,
		"weapon_type": WeaponType.SWORD,
		"damage": 22, "attack_speed": 1.1, "crit_chance": 0.10,
		"price": 0,   # crafted, not bought
	},
	"spear_jade": {
		"id": "spear_jade", "type": ItemType.WEAPON,
		"name": "Jade Serpent Spear",
		"description": "Long reach. Heavy attacks pierce through enemies.",
		"icon": "res://assets/sprites/ui/items/spear_jade.png",
		"max_stack": 1,
		"weapon_type": WeaponType.SPEAR,
		"damage": 18, "attack_speed": 0.85, "crit_chance": 0.08,
		"price": 220,
	},
	"fist_iron": {
		"id": "fist_iron", "type": ItemType.WEAPON,
		"name": "Iron Gauntlets",
		"description": "Fast strikes. Parry window is slightly wider.",
		"icon": "res://assets/sprites/ui/items/fist_iron.png",
		"max_stack": 1,
		"weapon_type": WeaponType.FIST,
		"damage": 10, "attack_speed": 1.3, "crit_chance": 0.12,
		"price": 180,
	},

	# ── Armor ─────────────────────────────────────────────────────────────────
	"armor_cloth": {
		"id": "armor_cloth", "type": ItemType.ARMOR,
		"name": "Traveler's Robe",
		"description": "Light cloth. No defense, but doesn't slow you down.",
		"icon": "res://assets/sprites/ui/items/armor_cloth.png",
		"max_stack": 1,
		"armor_slot": ArmorSlot.BODY,
		"defense": 2, "bonus": {},
		"price": 80,
	},
	"armor_leather": {
		"id": "armor_leather", "type": ItemType.ARMOR,
		"name": "Leather Cuirass",
		"description": "Decent protection without sacrificing mobility.",
		"icon": "res://assets/sprites/ui/items/armor_leather.png",
		"max_stack": 1,
		"armor_slot": ArmorSlot.BODY,
		"defense": 6, "bonus": {},
		"price": 160,
	},
	"armor_scale": {
		"id": "armor_scale", "type": ItemType.ARMOR,
		"name": "Bashe Scale Armor",
		"description": "Scales shed by Bashe. Grants poison resistance.",
		"icon": "res://assets/sprites/ui/items/armor_scale.png",
		"max_stack": 1,
		"armor_slot": ArmorSlot.BODY,
		"defense": 12, "bonus": { "poison_resist": true },
		"price": 0,   # crafted
	},
	"acc_jade_ring": {
		"id": "acc_jade_ring", "type": ItemType.ARMOR,
		"name": "Jade Qi Ring",
		"description": "Increases max Qi by 25.",
		"icon": "res://assets/sprites/ui/items/acc_jade_ring.png",
		"max_stack": 1,
		"armor_slot": ArmorSlot.ACCESSORY,
		"defense": 0, "bonus": { "max_qi": 25 },
		"price": 200,
	},
	"acc_swiftfoot": {
		"id": "acc_swiftfoot", "type": ItemType.ARMOR,
		"name": "Swiftfoot Charm",
		"description": "Move speed +20.",
		"icon": "res://assets/sprites/ui/items/acc_swiftfoot.png",
		"max_stack": 1,
		"armor_slot": ArmorSlot.ACCESSORY,
		"defense": 0, "bonus": { "move_speed": 20 },
		"price": 180,
	},

	# ── Materials (used for crafting / selling) ───────────────────────────────
	"mat_bifang_feather": {
		"id": "mat_bifang_feather", "type": ItemType.MATERIAL,
		"name": "Bi Fang Feather",
		"description": "A blazing feather. Used to forge the Bi Fang Blade.",
		"icon": "res://assets/sprites/ui/items/mat_bifang_feather.png",
		"max_stack": 5, "price": 120,
	},
	"mat_bashe_scale": {
		"id": "mat_bashe_scale", "type": ItemType.MATERIAL,
		"name": "Bashe Scale",
		"description": "A tough scale. Used to craft Bashe Scale Armor.",
		"icon": "res://assets/sprites/ui/items/mat_bashe_scale.png",
		"max_stack": 5, "price": 90,
	},
	"mat_spirit_stone": {
		"id": "mat_spirit_stone", "type": ItemType.MATERIAL,
		"name": "Spirit Stone",
		"description": "Crystallised Qi. Sold for a good price.",
		"icon": "res://assets/sprites/ui/items/mat_spirit_stone.png",
		"max_stack": 99, "price": 50,
	},
}

# ─── Helpers ─────────────────────────────────────────────────────────────────
func get(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {})

func is_consumable(item_id: String) -> bool:
	return get(item_id).get("type") == ItemType.CONSUMABLE

func is_weapon(item_id: String) -> bool:
	return get(item_id).get("type") == ItemType.WEAPON

func is_armor(item_id: String) -> bool:
	return get(item_id).get("type") == ItemType.ARMOR
