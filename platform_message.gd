extends Area2D

@export var float_distance := Vector2(4.0, -7.0)
@export var float_duration: float = 1.6

var triggered := false

@onready var landing_shape: CollisionShape2D = $LandingShape
@onready var message: Label = $Message

func _physics_process(_delta: float) -> void:
	if triggered:
		return
	var rectangle := landing_shape.shape as RectangleShape2D
	var landing_bounds := Rect2(-rectangle.size * 0.5, rectangle.size)
	for body in get_overlapping_bodies():
		if not body is CharacterBody2D or not body.is_in_group("player") or not body.is_on_floor():
			continue
		for index in body.get_slide_collision_count():
			var collision: KinematicCollision2D = body.get_slide_collision(index)
			if collision.get_normal().dot(Vector2.UP) < 0.7:
				continue
			if landing_bounds.has_point(landing_shape.to_local(collision.get_position())):
				_show_message()
				return

func _show_message() -> void:
	triggered = true
	set_physics_process(false)
	var has_living_blooms := false
	for bloom in get_tree().get_nodes_in_group("bloom_enemy"):
		if not bloom.is_dead:
			has_living_blooms = true
			break
	if not has_living_blooms:
		return
	message.show()
	message.modulate.a = 0.0
	create_tween().tween_property(message, "modulate:a", 1.0, 0.6)
	var rest_position := message.position
	var floating := create_tween().set_process_mode(Tween.TWEEN_PROCESS_PHYSICS).set_loops()
	floating.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	floating.tween_property(message, "position", rest_position + float_distance, float_duration)
	floating.tween_property(message, "position", rest_position, float_duration)
	await get_tree().create_timer(5.0, false).timeout
	var fade_out := create_tween()
	fade_out.tween_property(message, "modulate:a", 0.0, 2.0).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await fade_out.finished
	floating.kill()
	message.hide()
