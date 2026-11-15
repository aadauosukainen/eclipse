extends StaticBody2D

const TEXTURE_PATH := "res://assets/ground1.png"
const ALPHA_THRESHOLD := 0.1
# Ignore tiny alpha-edge bumps so bodies don't catch and vibrate on texture detail.
const POLYGON_EPSILON := 14.0

func _ready() -> void:
	var texture := load(TEXTURE_PATH) as Texture2D
	if texture == null:
		push_error("Unable to load platform texture: " + TEXTURE_PATH)
		return

	var image := texture.get_image()
	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(image, ALPHA_THRESHOLD)

	var regions := bitmap.opaque_to_polygons(
		Rect2i(Vector2i.ZERO, image.get_size()),
		POLYGON_EPSILON
	)
	for index in range(regions.size()):
		var collision := CollisionPolygon2D.new()
		collision.name = "PlatformCollision%d" % index
		collision.build_mode = CollisionPolygon2D.BUILD_SOLIDS
		collision.polygon = regions[index]
		add_child(collision)
