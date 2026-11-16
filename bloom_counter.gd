extends CanvasLayer

var blooms_remaining: int = 0

@onready var remaining_label: Label = $BloomsRemaining

func _ready() -> void:
	for bloom in get_tree().get_nodes_in_group("bloom_enemy"):
		if not bloom.is_dead:
			blooms_remaining += 1
			bloom.destroyed.connect(_on_bloom_destroyed)
	_update_label()

func _on_bloom_destroyed() -> void:
	blooms_remaining = maxi(0, blooms_remaining - 1)
	_update_label()

func _update_label() -> void:
	remaining_label.text = "blooms remaining: %d" % blooms_remaining
