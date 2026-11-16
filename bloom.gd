extends Node2D

signal destroyed

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
var is_dead: bool = false

func _ready() -> void:
	add_to_group("enemy")
	add_to_group("bloom_enemy")
	sprite.animation_finished.connect(_on_animation_finished)

func take_attack() -> void:
	if is_dead:
		return
	is_dead = true
	destroyed.emit()
	sprite.play("death")
	$DeathSound.play()

func _on_animation_finished() -> void:
	if sprite.animation == &"death":
		sprite.pause()
		remove_from_group("bloom_enemy")

