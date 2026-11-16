extends CharacterBody2D

signal died

const ATTACK_RANGE: float = 180.0
const ATTACK_LAST_FRAME: int = 10
const ATTACK_MOVEMENT_FRAME_COUNT: int = 2

@export var speed: float = 750.0
@export var gravity: float = 1400.0
@export var jump_velocity: float = 790.0
const PLAYER_RADIUS: float = 51.0
const PLAYER_FOOT_EXTENT: float = 51.0
@export var world_size := Vector2(6400.0, 1080.0)
@export var spawn_run_distance: float = 120.0
@export var spawn_run_speed: float = 300.0

var spawn_start: Vector2
var is_spawning: bool = true
var is_respawning: bool = false
var is_jumping: bool = false
var is_attacking: bool = false
var has_weapon: bool = false
var knockback_velocity_x: float = 0.0
var level_elapsed: float = 0.0
var is_level_complete: bool = false
var is_entering_portal: bool = false
var portal_walk_velocity: float = 0.0

@onready var player_sprite: AnimatedSprite2D = $Sprite2D
@onready var follow_camera: Camera2D = $Camera2D
@onready var death_screen_layer: CanvasLayer = $DeathScreenLayer
@onready var attack_prompt_anchor: Node2D = $AttackPromptAnchor
@onready var attack_prompt: Label = $AttackPromptAnchor/AttackPrompt
@onready var attack_prompt_forward_distance: float = absf(attack_prompt_anchor.position.x)

func _ready() -> void:
	add_to_group("player")
	spawn_start = position
	# Keep the camera in the player's interpolated transform hierarchy so its
	# view and the rendered player always use the same 2D interpolation.
	follow_camera.set_as_top_level(false)
	follow_camera.position_smoothing_enabled = false
	follow_camera.position = Vector2.ZERO
	reset_physics_interpolation()
	player_sprite.play("idle")

func equip_weapon() -> void:
	has_weapon = true
	attack_prompt.show()
	var prompt_float := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS).set_loops()
	prompt_float.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	prompt_float.tween_property(attack_prompt, "position", attack_prompt.position + Vector2(3.0, -5.0), 1.2)
	prompt_float.tween_property(attack_prompt, "position", attack_prompt.position, 1.2)
	if is_jumping:
		var jump_frame := player_sprite.frame
		player_sprite.play("jump_armed")
		player_sprite.frame = mini(jump_frame, 2)
		return
	if player_sprite.animation == &"run":
		player_sprite.play("run_armed")
	else:
		player_sprite.play("idle_armed")

func _unhandled_input(event: InputEvent) -> void:
	if not has_weapon:
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F:
		_attack()

func _attack() -> void:
	if not has_weapon or is_attacking or is_jumping or is_respawning or is_spawning or is_level_complete or is_entering_portal:
		return
	is_attacking = true
	attack_prompt.hide()
	velocity.x = 0.0
	knockback_velocity_x = 0.0
	player_sprite.play("attack_armed")
	for enemy in get_tree().get_nodes_in_group("enemy"):
		if enemy is Node2D and global_position.distance_to(enemy.global_position) <= ATTACK_RANGE:
			if enemy.has_method("take_attack"):
				enemy.take_attack()
			else:
				enemy.queue_free()

func _physics_process(_delta: float) -> void:
	if attack_prompt.visible:
		attack_prompt_anchor.position.x = attack_prompt_forward_distance * (-1.0 if player_sprite.flip_h else 1.0)
	if is_respawning or is_level_complete:
		return
	if is_entering_portal:
		velocity.x = portal_walk_velocity
		if is_on_floor():
			velocity.y = 0.0
		velocity.y += gravity * _delta
		_move_with_landing_sound()
		return
	level_elapsed += _delta
	if is_spawning:
		var remaining_distance := spawn_start.x + spawn_run_distance - position.x
		player_sprite.flip_h = false
		player_sprite.play("run_armed" if has_weapon else "run")
		velocity.x = minf(spawn_run_speed, maxf(remaining_distance, 0.0) / _delta)
		velocity.y += gravity * _delta
		_move_with_landing_sound()
		if position.x >= spawn_start.x + spawn_run_distance - 0.01 or is_on_wall():
			is_spawning = false
			velocity.x = 0.0
			player_sprite.play("idle_armed" if has_weapon else "idle")
		return

	if is_attacking and not player_sprite.is_playing():
		is_attacking = false
		if is_jumping:
			player_sprite.play("jump_armed")
			player_sprite.frame = 2
			player_sprite.pause()

	var horizontal_direction := float(Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT)) - float(Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT))
	var can_move_during_attack := not is_attacking or player_sprite.frame < ATTACK_MOVEMENT_FRAME_COUNT or player_sprite.frame == ATTACK_LAST_FRAME
	if horizontal_direction != 0.0 and can_move_during_attack:
		player_sprite.flip_h = horizontal_direction < 0.0
	if not is_jumping and not is_attacking:
		var movement_animation := "run" if horizontal_direction != 0.0 else "idle"
		if has_weapon:
			movement_animation += "_armed"
		player_sprite.play(movement_animation)
	if not can_move_during_attack:
		knockback_velocity_x = 0.0
		velocity.x = 0.0
	else:
		knockback_velocity_x = move_toward(knockback_velocity_x, 0.0, 1800.0 * _delta)
		velocity.x = horizontal_direction * speed + knockback_velocity_x
	if is_on_floor():
		velocity.y = 0.0
		if Input.is_action_just_pressed("ui_accept") and can_move_during_attack:
			velocity.y = -jump_velocity
			is_jumping = true
			if not is_attacking:
				player_sprite.play("jump_armed" if has_weapon else "jump")
	else:
		velocity.y += gravity * _delta
	_move_with_landing_sound()
	if is_jumping and is_on_floor():
		is_jumping = false
		if not is_attacking:
			var landing_animation := "run" if horizontal_direction != 0.0 else "idle"
			if has_weapon:
				landing_animation += "_armed"
			player_sprite.play(landing_animation)
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

func _move_with_landing_sound() -> void:
	var was_grounded := is_on_floor()
	var falling_speed := velocity.y
	move_and_slide()
	# Ignore floor snapping and tiny bumps while walking over level geometry.
	if not was_grounded and is_on_floor() and falling_speed > 80.0:
		$GrassFootsteps.stop()
		$LandingThump.play()

func enter_end_portal(destination: Vector2) -> void:
	if is_entering_portal or is_level_complete or is_respawning:
		return
	is_entering_portal = true
	is_attacking = false
	is_jumping = false
	velocity.x = 0.0
	knockback_velocity_x = 0.0
	attack_prompt.hide()
	# Keep ramp/floor collisions; the portal physics branch skips world bounds.
	portal_walk_velocity = (destination.x - global_position.x) / 0.9
	player_sprite.flip_h = destination.x < global_position.x
	player_sprite.play("run_armed" if has_weapon else "run")
	var entry := create_tween().set_parallel(true)
	entry.set_process_mode(Tween.TWEEN_PROCESS_PHYSICS)
	entry.tween_property(player_sprite, "modulate:a", 0.0, 0.45).set_delay(0.45)
	await entry.finished
	player_sprite.hide()
	complete_level()

func complete_level() -> void:
	if is_level_complete:
		return
	is_level_complete = true
	velocity = Vector2.ZERO
	get_tree().call_group("game_screens", "show_completion", level_elapsed)

func _respawn() -> void:
	if is_respawning:
		return

	is_respawning = true
	died.emit()
	is_jumping = false
	is_attacking = false
	velocity = Vector2.ZERO
	knockback_velocity_x = 0.0
	player_sprite.play("idle_armed" if has_weapon else "idle")
	get_tree().paused = true
	death_screen_layer.visible = true
	await get_tree().create_timer(0.5, true).timeout

	global_position = spawn_start
	velocity = Vector2.ZERO
	is_spawning = true
	reset_physics_interpolation()
	death_screen_layer.visible = false
	get_tree().paused = false
	is_respawning = false
