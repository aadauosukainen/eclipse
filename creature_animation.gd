extends AnimatedSprite2D

const PLAYER_GROUP: StringName = &"player"
const LEFT_ANIMATION: StringName = &"tail_flick_left"
const RIGHT_ANIMATION: StringName = &"tail_flick_right"

@export var facing_origin_offset := Vector2(397.5, 0.0)

var tracked_player: Node2D

func _ready() -> void:
	_update_facing_animation()

func _process(_delta: float) -> void:
	_update_facing_animation()

func _update_facing_animation() -> void:
	if not is_instance_valid(tracked_player):
		tracked_player = get_tree().get_first_node_in_group(PLAYER_GROUP) as Node2D
	if tracked_player == null:
		return

	var creature_facing_x := to_global(facing_origin_offset).x
	var player_is_right := tracked_player.global_position.x >= creature_facing_x
	var animation_faces_right := player_is_right != (scale.x < 0.0)
	var target_animation := RIGHT_ANIMATION if animation_faces_right else LEFT_ANIMATION
	if animation != target_animation:
		var current_frame := frame
		var current_frame_progress := frame_progress
		play(target_animation)
		frame = mini(current_frame, sprite_frames.get_frame_count(target_animation) - 1)
		frame_progress = current_frame_progress
