extends Area2D

const PICKUP_KEY := KEY_E

var player_in_range: CharacterBody2D

@onready var prompt: Label = $Prompt

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _unhandled_input(event: InputEvent) -> void:
	if player_in_range != null and event is InputEventKey and event.pressed and not event.echo and event.keycode == PICKUP_KEY:
		_pick_up()

func _on_body_entered(body: Node2D) -> void:
	if body is CharacterBody2D:
		player_in_range = body
		prompt.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body == player_in_range:
		player_in_range = null
		prompt.visible = false

func _pick_up() -> void:
	if player_in_range == null:
		return
	player_in_range.call("equip_weapon")
	queue_free()
