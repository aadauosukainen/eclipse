extends ParallaxBackground
## Fits the editor-authored layers to the visible area without distorting them.

@export var death_tint := Color(0.55, 0.20, 0.20, 1.0)

var greyscale_material: ShaderMaterial


func _on_player_died() -> void:
	$BG1_Far/Sprite2D.modulate = death_tint
	$BG2_Mid/Sprite2D.modulate = death_tint
	if greyscale_material == null:
		greyscale_material = ShaderMaterial.new()
		greyscale_material.shader = preload("res://environment_greyscale.gdshader")
	_greyscale_environment(get_tree().current_scene)


func _greyscale_environment(node: Node) -> void:
	# Preserve the player, menu/death overlays, and the two red background layers.
	if node.is_in_group("player") or (node is CanvasLayer and node != self):
		return
	if node == $BG1_Far or node == $BG2_Mid:
		return
	if node is Sprite2D or node is AnimatedSprite2D or node is Polygon2D:
		node.material = greyscale_material
	for child in node.get_children():
		_greyscale_environment(child)


func _ready() -> void:
	scroll_ignore_camera_zoom = true
	get_viewport().size_changed.connect(_fit_layers)
	_fit_layers()


func _fit_layers() -> void:
	var viewport_size := get_viewport().get_visible_rect().size
	for child in get_children():
		var layer := child as ParallaxLayer
		if layer == null:
			continue
		var sprite := layer.get_node_or_null("Sprite2D") as Sprite2D
		if sprite == null or sprite.texture == null:
			continue
		var texture_size := sprite.texture.get_size()
		var cover_scale := maxf(viewport_size.x / texture_size.x, viewport_size.y / texture_size.y)
		sprite.scale = Vector2.ONE * cover_scale
		sprite.position = Vector2.ZERO
		# A full-width tile guarantees coverage throughout horizontal scrolling.
		layer.motion_mirroring = Vector2(texture_size.x * cover_scale, 0.0)
