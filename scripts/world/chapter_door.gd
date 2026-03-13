extends StaticBody2D

# ChapterDoor — player walks up and presses E to enter a chapter
# Emits interact_pressed so hub.gd can handle the transition

signal interact_pressed

@export var label_text : String = "Chapter"

@onready var prompt : Label = $Prompt

var _player_nearby := false

func _ready() -> void:
	prompt.hide()

func _unhandled_input(event: InputEvent) -> void:
	if _player_nearby and event.is_action_just_pressed("interact"):
		emit_signal("interact_pressed")

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = true
		prompt.show()

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		_player_nearby = false
		prompt.hide()
