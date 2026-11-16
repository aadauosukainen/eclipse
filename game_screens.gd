extends CanvasLayer

enum Screen { PLAYING, START, PAUSE, END }

@export_range(0.05, 0.5, 0.01) var fade_duration: float = 0.16

@export var music_player: AudioStreamPlayer
static var music_volume: float = 44.0

var current_screen: Screen = Screen.PLAYING
var fade_tween: Tween
var is_closing: bool = false

@onready var overlay: Control = $Overlay
@onready var artwork: Control = $Overlay/Artwork

@onready var music_slider: HSlider = $Overlay/Artwork/PauseScreen/MusicVolume/Slider
@onready var music_value: Label = $Overlay/Artwork/PauseScreen/MusicVolume/Value

func _ready() -> void:
	add_to_group("game_screens")
	music_slider.set_value_no_signal(music_volume)
	_on_music_volume_changed(music_volume)
	get_viewport().size_changed.connect(_fit_artwork)
	_fit_artwork()
	show_screen(Screen.START)

func _fit_artwork() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	var fit := minf(viewport_size.x / 1920.0, viewport_size.y / 1080.0)
	artwork.scale = Vector2.ONE * fit
	artwork.position = (viewport_size - Vector2(1920, 1080) * fit) / 2.0

func _input(event: InputEvent) -> void:
	if is_closing:
		return
	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		if current_screen == Screen.PAUSE:
			_resume()
		elif current_screen == Screen.PLAYING and not get_tree().paused:
			show_screen(Screen.PAUSE)
		get_viewport().set_input_as_handled()

func show_screen(screen: Screen) -> void:
	if is_closing:
		return
	if not overlay.visible:
		overlay.modulate.a = 0.0
	current_screen = screen
	overlay.show()
	$Overlay/Artwork/StartScreen.visible = screen == Screen.START
	$Overlay/Artwork/PauseScreen.visible = screen == Screen.PAUSE
	$Overlay/Artwork/EndScreen.visible = screen == Screen.END
	get_tree().paused = true
	match screen:
		Screen.START: $Overlay/Artwork/StartScreen/StartButton.grab_focus()
		Screen.PAUSE: $Overlay/Artwork/PauseScreen/ResumeButton.grab_focus()
		Screen.END: $Overlay/Artwork/EndScreen/RestartButton.grab_focus()
	_fade_to(1.0)

func _fade_to(alpha: float) -> Tween:
	if fade_tween != null and fade_tween.is_valid():
		fade_tween.kill()
	fade_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	fade_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	fade_tween.tween_property(overlay, "modulate:a", alpha, fade_duration)
	return fade_tween

func show_completion(elapsed: float) -> void:
	var seconds := int(elapsed)
	$Overlay/Artwork/EndScreen/TimeLabel.text = "Time: %02d:%02d.%02d" % [seconds / 60, seconds % 60, int((elapsed - floor(elapsed)) * 100)]
	show_screen(Screen.END)

func _resume() -> void:
	if is_closing:
		return
	is_closing = true
	await _fade_to(0.0).finished
	current_screen = Screen.PLAYING
	overlay.hide()
	get_tree().paused = false
	is_closing = false

func _restart() -> void:
	if is_closing:
		return
	is_closing = true
	await _fade_to(0.0).finished
	get_tree().paused = false
	get_tree().reload_current_scene()

func _next_level() -> void:
	pass

func _exit_game() -> void:
	get_tree().quit()

func _on_music_volume_changed(value: float) -> void:
	music_volume = value
	music_value.text = "%d%%" % int(value)
	if is_instance_valid(music_player):
		music_player.call("set_music_volume", value)
