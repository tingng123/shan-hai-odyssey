extends Node

# Singleton: SkillTree
# Manages unlockable skills purchased with Ling Essence

signal skill_unlocked(skill_id: String)
signal essence_changed(new_amount: int)

var ling_essence : int = 0
var unlocked     : Array[String] = []

# ─── Skill definitions ───────────────────────────────────────────────────────
# Each entry: id, display_name, cost, requires (array of prerequisite ids)
const SKILLS : Array[Dictionary] = [
	# Combat
	{ "id": "combo_4",       "name": "4th Strike",         "cost": 3,  "requires": [] },
	{ "id": "heavy_dash",    "name": "Dash Heavy",          "cost": 4,  "requires": ["combo_4"] },
	{ "id": "parry_riposte", "name": "Parry Riposte",       "cost": 5,  "requires": [] },
	{ "id": "qi_burst",      "name": "Qi Burst",            "cost": 4,  "requires": [] },
	{ "id": "stance_2",      "name": "Tiger Stance",        "cost": 6,  "requires": ["combo_4"] },
	{ "id": "stance_3",      "name": "Serpent Stance",      "cost": 6,  "requires": ["stance_2"] },
	{ "id": "stance_4",      "name": "Void Stance",         "cost": 8,  "requires": ["stance_3"] },
	# Survival
	{ "id": "stamina_up_1",  "name": "Iron Lungs I",        "cost": 2,  "requires": [] },
	{ "id": "stamina_up_2",  "name": "Iron Lungs II",       "cost": 4,  "requires": ["stamina_up_1"] },
	{ "id": "dodge_dist",    "name": "Wind Step",           "cost": 3,  "requires": [] },
	{ "id": "parry_window",  "name": "Still Water",         "cost": 5,  "requires": ["parry_riposte"] },
	# Transformation (unlocked after defeating bosses)
	{ "id": "transform_bifang",   "name": "Bi Fang Form",   "cost": 0,  "requires": [] },
	{ "id": "transform_taotie",   "name": "Taotie Form",    "cost": 0,  "requires": [] },
	{ "id": "transform_bashe",    "name": "Bashe Form",     "cost": 0,  "requires": [] },
]

func _ready() -> void:
	# Load from save
	var saved : Array = SaveSystem.data.get("skills_unlocked", [])
	unlocked = saved.duplicate()
	ling_essence = SaveSystem.data.get("ling_essence", 0)

func add_essence(amount: int) -> void:
	ling_essence += amount
	SaveSystem.data["ling_essence"] = ling_essence
	emit_signal("essence_changed", ling_essence)

func can_unlock(skill_id: String) -> bool:
	if skill_id in unlocked:
		return false
	var def := _get_def(skill_id)
	if def.is_empty():
		return false
	if ling_essence < def["cost"]:
		return false
	for req in def["requires"]:
		if req not in unlocked:
			return false
	return true

func unlock(skill_id: String) -> bool:
	if not can_unlock(skill_id):
		return false
	var def := _get_def(skill_id)
	ling_essence -= def["cost"]
	unlocked.append(skill_id)
	SaveSystem.data["skills_unlocked"] = unlocked
	SaveSystem.data["ling_essence"]    = ling_essence
	emit_signal("skill_unlocked", skill_id)
	emit_signal("essence_changed", ling_essence)
	return true

func has(skill_id: String) -> bool:
	return skill_id in unlocked

func _get_def(skill_id: String) -> Dictionary:
	for s in SKILLS:
		if s["id"] == skill_id:
			return s
	return {}
