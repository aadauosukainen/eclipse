extends CharacterBody2D

const PLAYER_WITH_WEAPON_TEXTURE: Texture2D = preload("res://assets/player_character.png")
const ATTACK_RANGE: float = 180.0

@export var speed: float = 750.0
@export var gravity: float = 1400.0
@export var jump_velocity: float = 790.0
const PLAYER_RADIUS: float = 51.0
const PLAYER_FOOT_EXTENT: float = 51.0
@export var world_size := Vector2(6400.0, 1080.0)
@export var spawn_end := Vector2(537.0, 699.0)
const SPAWN_DURATION := 1.0

var spawn_start: Vector2
var spawn_elapsed: float = 0.0
var is_spawning: bool = true
var is_respawning: bool = false
var has_weapon: bool = false
var knockback_velocity_x: float = 0.0
var attack_tween: Tween
var level_elapsed: float = 0.0
var is_level_complete: bool = false

@onready var player_sprite: Sprite2D = $Sprite2D
@onready var follow_camera: Camera2D = $Camera2D
@onready var death_screen_layer: CanvasLayer = $DeathScreenLayer

func _ready() -> void:
	spawn_start = position
	# Keep the camera in the player's interpolated transform hierarchy so its
	# view and the rendered player always use the same 2D interpolation.
	follow_camera.set_as_top_level(false)
	follow_camera.position_smoothing_enabled = false
	follow_camera.position = Vector2.ZERO
	reset_physics_interpolation()
	if has_weapon:
		player_sprite.texture = PLAYER_WITH_WEAPON_TEXTURE

func equip_weapon() -> void:
	has_weapon = true
	player_sprite.texture = PLAYER_WITH_WEAPON_TEXTURE

func _unhandled_input(event: InputEvent) -> void:
	if not has_weapon:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F:
		_attack()

func _attack() -> void:
	if attack_tween != null and attack_tween.is_running():
		attack_tween.kill()
	player_sprite.rotation = 0.0
	attack_tween = create_tween()
	attack_tween.tween_property(player_sprite, "rotation", deg_to_rad(35.0), 0.08)
	attack_tween.tween_property(player_sprite, "rotation", 0.0, 0.13)
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is Node2D and global_position.distance_to(enemy.global_position) <= ATTACK_RANGE:
			enemy.queue_free()

func _physics_process(_delta: float) -> void:
	if is_respawning or is_level_complete:
		return
	level_elapsed += _delta
	if is_spawning:
		spawn_elapsed = minf(spawn_elapsed + _delta, SPAWN_DURATION)
		var progress := spawn_elapsed / SPAWN_DURATION
		position.x = lerpf(spawn_start.x, spawn_end.x, progress)
		var falling_progress := 0.35 * progress + 0.65 * progress * progress
		position.y = lerpf(spawn_start.y, spawn_end.y, falling_progress)
		if spawn_elapsed >= SPAWN_DURATION:
			is_spawning = false
			velocity = Vector2.ZERO
		return

	var horizontal_direction := float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
	knockback_velocity_x = move_toward(knockback_velocity_x, 0.0, 1800.0 * _delta)
	velocity.x = horizontal_direction * speed + knockback_velocity_x
	if is_on_floor():
		velocity.y = 0.0
		if Input.is_action_just_pressed("ui_accept"):
			velocity.y = -jump_velocity
	else:
		velocity.y += gravity * _delta
	move_and_slide()
	for collision_index in get_slide_collision_count():
		var collider := get_slide_collision(collision_index).get_collider() as Node
		if collider != null and collider.is_in_group("enemy"):
			var push_direction := signf(global_position.x - collider.global_position.x)
			if push_direction == 0.0:
				push_direction = -signf(velocity.x)
			knockback_velocity_x = push_direction * 350.0
	position.x = clampf(position.x, PLAYER_RADIUS, world_size.x - PLAYER_RADIUS)
	position.y = maxf(position.y, PLAYER_RADIUS)
	if position.y > world_size.y + PLAYER_RADIUS:
		_respawn()

func complete_level() -> void:
	if is_level_complete:
		return
	is_level_complete = true
	velocity = Vector2.ZERO
	get_tree().paused = true
	$CompletionScreenLayer/CenterContainer/CompletionScreen/Panel/VBoxContainer/TimeLabel.text = "Time: %s" % _format_time(level_elapsed)
	$CompletionScreenLayer.visible = true

func _format_time(seconds: float) -> String:
	var total_seconds := int(floor(seconds))
	var minutes := total_seconds / 60
	var remaining_seconds := total_seconds % 60
	var hundredths := int((seconds - floor(seconds)) * 100.0)
	return "%02d:%02d.%02d" % [minutes, remaining_seconds, hundredths]

func _on_restart_button_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func _respawn() -> void:
	if is_respawning:
		return

	is_respawning = true
	velocity = Vector2.ZERO
	knockback_velocity_x = 0.0
	get_tree().paused = true
	death_screen_layer.visible = true
	await get_tree().create_timer(0.5, true).timeout

	global_position = spawn_start
	velocity = Vector2.ZERO
	spawn_elapsed = 0.0
	is_spawning = true
	reset_physics_interpolation()
	death_screen_layer.visible = false
	get_tree().paused = false
	is_respawning = false
