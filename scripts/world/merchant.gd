extends Area2D

# Merchant NPC — player enters interact area to open shop
# Set stock and shop_name in the scene inspector via exported vars

@export var shop_name : String = "Merchant"
@export var stock     : Array[String] = [
	"potion_small", "potion_large", "stamina_tonic", "qi_pill", "antidote",
	"sword_iron", "spear_jade", "fist_iron",
	"armor_cloth", "armor_leather", "acc_jade_ring", "acc_swiftfoot",
]

@onready var prompt  : Label      = $Prompt
@onready var shop_ui : CanvasLayer = $ShopUI

var _player_nearby := false

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	prompt.hide()

func _unhandled_input(event: InputEvent) -> void:
	if _player_nearby and event.is_action_just_pressed("interact"):
		shop_ui.open(stock, shop_name)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = true
		prompt.show()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
		prompt.hide()
