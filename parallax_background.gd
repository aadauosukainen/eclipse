extends ParallaxBackground
## Fits the editor-authored layers to the visible area without distorting them.


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
