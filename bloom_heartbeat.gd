extends Node

## The recording contains ten heartbeats. Each one drives one bloom pulse.
@export_range(1, 32, 1) var beats_per_loop: int = 10
@export_range(0.0, 1.0, 0.01) var first_beat_seconds: float = 0.22

@onready var heartbeat: AudioStreamPlayer = $Heartbeat
var pulse_sprites: Array[AnimatedSprite2D] = []
var blooms: Array[Node] = []
var started: bool = false
var finished: bool = false

func _ready() -> void:
	heartbeat.stream.loop = true
	for bloom in get_tree().get_nodes_in_group("bloom_enemy"):
		blooms.append(bloom)
		bloom.destroyed.connect(_on_bloom_destroyed)
	for sprite in get_tree().get_nodes_in_group("bloom_pulse"):
		pulse_sprites.append(sprite)
		sprite.pause()
	if blooms.is_empty():
		finished = true

func _process(_delta: float) -> void:
	if finished:
		return
	if not started:
		started = true
		heartbeat.play()
	# Follow the audible playback clock so animation cannot drift from the loop.
	var playback_time := maxf(0.0, heartbeat.get_playback_position()
		+ AudioServer.get_time_since_last_mix() - AudioServer.get_output_latency())
	var beat_duration := heartbeat.stream.get_length() / beats_per_loop
	var beat_phase := fposmod(playback_time - first_beat_seconds, beat_duration) / beat_duration
	for sprite in pulse_sprites:
		if not is_instance_valid(sprite) or sprite.animation != &"idle":
			continue
		var frames := sprite.sprite_frames
		var frame_count := frames.get_frame_count(&"idle")
		var total_duration := 0.0
		for index in frame_count:
			total_duration += frames.get_frame_duration(&"idle", index)
		# Frame 2 is the expanded bloom, reached 0.5 seconds into its 2.25s cycle.
		var frame_time := fposmod(beat_phase * total_duration + 0.5, total_duration)
		for index in frame_count:
			var duration := frames.get_frame_duration(&"idle", index)
			if frame_time < duration:
				sprite.set_frame_and_progress(index, frame_time / duration)
				break
			frame_time -= duration

func _on_bloom_destroyed() -> void:
	for bloom in blooms:
		if is_instance_valid(bloom) and not bloom.is_dead:
			return
	finished = true
	heartbeat.stop()
