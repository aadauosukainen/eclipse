extends CanvasLayer

@export_range(0.03, 0.2, 0.01) var glitch_interval: float = 0.065

## Midpoint of the eyes in the cropped creature texture.
@export var eye_center := Vector2(1056.4385, 1229.745)
@export var creature_scale: float = 0.28

var glitch_time: float = 0.0
var random := RandomNumberGenerator.new()
@onready var creature: Sprite2D = $Black/EyeCenter/Creature
@onready var death_sound: AudioStreamPlayer = $DeathSound
@onready var message: Label = $Black/Message
@onready var echo_text: Label = $Black/Message/Echo

func _ready() -> void:
	random.randomize()
	get_viewport().size_changed.connect(_fit_creature)
	_fit_creature()
	visibility_changed.connect(_reset_glitch)
	_reset_glitch()

func _reset_glitch() -> void:
	if visible:
		death_sound.play()
	else:
		death_sound.stop()
	glitch_time = 0.0
	message.modulate.a = 1.0
	message.position = Vector2.ZERO
	echo_text.hide()

func _process(delta: float) -> void:
	if not visible:
		return
	glitch_time -= delta
	if glitch_time > 0.0:
		return
	glitch_time = glitch_interval * random.randf_range(0.6, 1.5)
	message.position = Vector2(random.randf_range(-12.0, 12.0), random.randf_range(-4.0, 4.0))
	message.modulate.a = random.randf_range(0.35, 1.0)
	echo_text.visible = random.randf() > 0.45
	echo_text.position = Vector2(random.randf_range(-24.0, 24.0), random.randf_range(-6.0, 6.0))

func _fit_creature() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var fit := minf(viewport_size.x / 1920.0, viewport_size.y / 1080.0)
	creature.scale = Vector2.ONE * creature_scale * fit
	creature.position = -eye_center * creature.scale
