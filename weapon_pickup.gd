extends Area2D

const PICKUP_KEY := KEY_E

@export var prompt_float_amplitude := Vector2(3.0, 5.0)
@export_range(0.1, 5.0, 0.1) var prompt_float_speed := 1.8

var player_in_range: CharacterBody2D
var prompt_rest_position: Vector2
var prompt_float_time := 0.0

@onready var prompt: Label = $Prompt

func _ready() -> void:
	prompt_rest_position = prompt.position
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	if not prompt.visible:
		return
	prompt_float_time += delta * prompt_float_speed
	prompt.position = prompt_rest_position + Vector2(
		sin(prompt_float_time * 0.7) * prompt_float_amplitude.x,
		sin(prompt_float_time) * prompt_float_amplitude.y
	)

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
