extends AudioStreamPlayer

## Contact poses in the existing eight-frame run cycle (zero-based).
@export var contact_frames := PackedInt32Array([1, 5])
@export var animated_sprite: AnimatedSprite2D
@export var body: CharacterBody2D
@export var step_sounds: Array[AudioStream] = []
var next_step: int = 0

func _ready() -> void:
	animated_sprite.frame_changed.connect(_on_frame_changed)
	animated_sprite.animation_changed.connect(_on_animation_changed)

func _is_running_on_ground() -> bool:
	return body.is_on_floor() and absf(body.get_real_velocity().x) > 1.0 \
		and animated_sprite.visible \
		and animated_sprite.animation in [&"run", &"run_armed"]

func _on_frame_changed() -> void:
	if not _is_running_on_ground() or not animated_sprite.frame in contact_frames:
		return
	if step_sounds.is_empty():
		return
	stream = step_sounds[next_step]
	next_step = (next_step + 1) % step_sounds.size()
	play()

func _on_animation_changed() -> void:
	if animated_sprite.animation not in [&"run", &"run_armed"]:
		stop()

func _physics_process(_delta: float) -> void:
	if playing and not _is_running_on_ground():
		stop()
