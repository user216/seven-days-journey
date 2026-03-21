class_name PlaceholderFactory
## Creates procedural stand-in visuals for missing HOPA art assets.

# ── Palette for distinct placeholder objects ─────────────────────

const PLACEHOLDER_COLORS: Array[Color] = [
	Color("#7da344"),  # sage green
	Color("#d4a843"),  # golden amber
	Color("#7cafc2"),  # soft teal
	Color("#c9886e"),  # terracotta
	Color("#a8c97a"),  # light sage
	Color("#8b7355"),  # earthy brown
	Color("#b8cfe0"),  # light sky
	Color("#5e8a3c"),  # deep leaf
]

# ── Object placeholder texture ───────────────────────────────────

static func create_object_texture(obj_id: String, obj_name: String, idx: int, obj_size: int = 120) -> ImageTexture:
	## Creates a colored circle with the first letter of the object name.
	var img := Image.create(obj_size, obj_size, false, Image.FORMAT_RGBA8)
	var color: Color = PLACEHOLDER_COLORS[idx % PLACEHOLDER_COLORS.size()]
	var center := Vector2(obj_size / 2.0, obj_size / 2.0)
	var radius := obj_size / 2.0 - 4.0

	# Draw filled circle
	for y in range(obj_size):
		for x in range(obj_size):
			var dist := Vector2(x, y).distance_to(center)
			if dist <= radius:
				var alpha := 1.0 - smoothstep(radius - 2.0, radius, dist)
				img.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))
			else:
				img.set_pixel(x, y, Color(0, 0, 0, 0))

	return ImageTexture.create_from_image(img)


static func create_background_color(scene_id: String) -> Color:
	## Returns a distinct muted background color for each level.
	var colors: Dictionary = {
		"garden_morning": Color("#e8f0da"),     # mint sage
		"kitchen_pantry": Color("#f5e6b8"),      # light gold
		"meditation_room": Color("#d6eaf2"),     # water soft
		"forest_path": Color("#dce8d0"),         # forest green tint
		"tea_ceremony": Color("#f2e0d6"),        # bloom soft
		"stargazing_tower": Color("#c8d0e0"),    # night blue tint
		"sacred_garden": Color("#f0ecd8"),       # sacred cream
	}
	return colors.get(scene_id, ThemeManager.MINT_SAGE)


# ── Soft circle for particles ────────────────────────────────────

static func make_soft_circle(radius: int = 16, color: Color = Color.WHITE) -> ImageTexture:
	## Procedural soft circle texture for GPUParticles2D.
	## NEVER use PlaceholderTexture2D — always procedural ImageTexture.
	var size := radius * 2
	var img := Image.create(size, size, false, Image.FORMAT_RGBA8)
	var center := Vector2(radius, radius)

	for y in range(size):
		for x in range(size):
			var dist := Vector2(x, y).distance_to(center)
			var t := clampf(dist / float(radius), 0.0, 1.0)
			var alpha := (1.0 - t * t) * color.a
			img.set_pixel(x, y, Color(color.r, color.g, color.b, alpha))

	return ImageTexture.create_from_image(img)


static func smoothstep(edge0: float, edge1: float, x: float) -> float:
	var t := clampf((x - edge0) / (edge1 - edge0), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)
