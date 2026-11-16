extends StaticBody2D

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var screen_notifier: VisibleOnScreenNotifier2D = $VisibleOnScreenNotifier2D
var death_animation_started: bool = false

func _process(_delta: float) -> void:
	if death_animation_started:
		return
	if not get_tree().get_nodes_in_group("bloom_enemy").is_empty():
		return
	if screen_notifier.is_on_screen() and _player_camera_is_at_right_limit():
		death_animation_started = true
		animated_sprite.play("death")

func _player_camera_is_at_right_limit() -> bool:
	var player := get_tree().get_first_node_in_group("player") as Node2D
	if player == null:
		return false
	var camera := player.get_node_or_null("Camera2D") as Camera2D
	if camera == null:
		return false
	var visible_width := camera.get_viewport().get_visible_rect().size.x / camera.zoom.x
	var right_limit_center := camera.limit_right - visible_width * 0.5
	return camera.get_screen_center_position().x >= right_limit_center - 2.0

func _ready() -> void:
	animated_sprite.animation_finished.connect(_on_animation_finished)
	animated_sprite.animation_changed.connect(_on_animation_changed)

func _on_animation_finished() -> void:
	if animated_sprite.animation != &"death":
		return
	collision_shape.set_deferred("disabled", true)
	visible = false

func _on_animation_changed() -> void:
	if animated_sprite.animation == &"death":
		$DeathSound.play()
