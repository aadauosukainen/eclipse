extends AudioStreamPlayer

@export var death_stream: AudioStream
# The rainforest source is roughly 30 dB quieter than the piano recording.
@export var normal_volume_boost_db: float = 38.0
@export var death_pitch_scale: float = 0.9

var has_died := false
var music_volume: float = 44.0


func set_music_volume(value: float) -> void:
	music_volume = value
	if value == 0.0:
		volume_linear = 0.0
	else:
		volume_db = lerpf(-50.0, 0.0, value / 100.0)
		if not has_died:
			volume_db = minf(volume_db + normal_volume_boost_db, 30.0)


func _on_player_died() -> void:
	if has_died:
		return
	has_died = true
	stream = death_stream
	pitch_scale = death_pitch_scale
	set_music_volume(music_volume)
	play()
