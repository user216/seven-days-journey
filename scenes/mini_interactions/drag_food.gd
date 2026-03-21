extends MiniInteractionBase
## Drag 4 food items onto a plate — procedurally drawn, no emoji dependency.

var food_items: Array[Dictionary] = []
var plate_rect: Rect2
var placed_count: int = 0
var target: int = 4
var _dragging_idx: int = -1
var _drag_offset: Vector2 = Vector2.ZERO

# Food types with distinct colors and shapes (drawn procedurally)
const FOOD_TYPES := [
	{"name": "Яблоко", "color": Color(0.85, 0.2, 0.15), "shape": "apple"},
	{"name": "Хлеб", "color": Color(0.82, 0.65, 0.3), "shape": "bread"},
	{"name": "Салат", "color": Color(0.35, 0.7, 0.3), "shape": "salad"},
	{"name": "Каша", "color": Color(0.9, 0.82, 0.55), "shape": "bowl"},
	{"name": "Сыр", "color": Color(0.95, 0.85, 0.3), "shape": "cheese"},
	{"name": "Морковь", "color": Color(0.95, 0.55, 0.15), "shape": "carrot"},
	{"name": "Яйцо", "color": Color(0.98, 0.95, 0.85), "shape": "egg"},
	{"name": "Суп", "color": Color(0.85, 0.5, 0.2), "shape": "bowl"},
]

var _plate_sprite: Sprite2D
var _plate_tex: Texture2D = preload("res://assets/mini_interactions/plate.svg")


func _setup() -> void:
	duration = 10.0
	plate_rect = Rect2(size.x * 0.52, size.y * 0.3, size.x * 0.38, size.x * 0.38)

	# Plate sprite
	_plate_sprite = Sprite2D.new()
	_plate_sprite.texture = _plate_tex
	_plate_sprite.position = plate_rect.get_center()
	var plate_s: float = plate_rect.size.x / 120.0
	_plate_sprite.scale = Vector2(plate_s, plate_s)
	add_child(_plate_sprite)

	var rng := RandomNumberGenerator.new()
	rng.seed = 999
	var used_indices: Array[int] = []
	for i in range(target):
		var idx := rng.randi_range(0, FOOD_TYPES.size() - 1)
		while idx in used_indices:
			idx = rng.randi_range(0, FOOD_TYPES.size() - 1)
		used_indices.append(idx)
		var pos := Vector2(size.x * 0.14, size.y * 0.15 + i * 110)
		food_items.append({
			"pos": pos,
			"food": FOOD_TYPES[idx],
			"placed": false,
			"radius": 40.0,
		})


func _draw_food_shape(center: Vector2, food: Dictionary) -> void:
	var c: Color = food.color
	var shape: String = food.shape
	var r := 28.0

	match shape:
		"apple":
			draw_circle(center, r, c)
			draw_circle(center + Vector2(0, -2), r - 4, c.lightened(0.15))
			# Stem
			draw_line(center + Vector2(0, -r + 2), center + Vector2(3, -r - 8),
				Color(0.4, 0.25, 0.1), 3.0)
			# Leaf
			draw_circle(center + Vector2(8, -r - 2), 6.0, Color(0.3, 0.65, 0.2))
			# Highlight
			draw_circle(center + Vector2(-8, -8), 6.0, Color(1, 1, 1, 0.3))
		"bread":
			# Loaf shape — rounded rect
			draw_rect(Rect2(center.x - r, center.y - r * 0.5, r * 2, r), c, true)
			draw_rect(Rect2(center.x - r + 4, center.y - r * 0.5 + 4, r * 2 - 8, r - 8),
				c.lightened(0.12), true)
			# Crust lines
			draw_line(center + Vector2(-r * 0.5, -4), center + Vector2(r * 0.5, -4),
				c.darkened(0.15), 2.0)
			draw_line(center + Vector2(-r * 0.3, 2), center + Vector2(r * 0.3, 2),
				c.darkened(0.1), 1.5)
			# Highlight
			draw_circle(center + Vector2(-6, -6), 5.0, Color(1, 1, 1, 0.2))
		"salad":
			# Bowl
			draw_circle(center + Vector2(0, 4), r, Color(0.92, 0.9, 0.85))
			# Greens
			for ang in range(0, 360, 45):
				var rad := deg_to_rad(float(ang))
				var leaf_pos := center + Vector2(cos(rad), sin(rad)) * (r * 0.5)
				draw_circle(leaf_pos, 10.0, c.lerp(Color(0.2, 0.6, 0.15), float(ang) / 360.0))
			draw_circle(center, 8.0, Color(0.85, 0.2, 0.15, 0.6))  # tomato center
		"bowl":
			# Bowl shape
			draw_circle(center + Vector2(0, 4), r, Color(0.92, 0.88, 0.82))
			draw_circle(center + Vector2(0, 2), r - 4, c)
			draw_circle(center + Vector2(0, 0), r - 8, c.lightened(0.1))
			# Steam wisps
			for si in range(3):
				var sx := center.x - 12.0 + si * 12.0
				var sy := center.y - r + 4
				draw_line(Vector2(sx, sy), Vector2(sx + 3, sy - 12),
					Color(1, 1, 1, 0.3), 1.5)
		"cheese":
			# Wedge — triangle with holes
			var pts := PackedVector2Array([
				center + Vector2(-r, r * 0.5),
				center + Vector2(r, r * 0.3),
				center + Vector2(-r * 0.3, -r * 0.6),
			])
			draw_colored_polygon(pts, c)
			draw_colored_polygon(pts, c.lightened(0.08))
			# Holes
			draw_circle(center + Vector2(-5, 5), 5.0, c.darkened(0.15))
			draw_circle(center + Vector2(8, -2), 3.5, c.darkened(0.12))
			draw_circle(center + Vector2(-2, -8), 4.0, c.darkened(0.1))
		"carrot":
			# Conical carrot
			var pts := PackedVector2Array([
				center + Vector2(-12, -r * 0.7),
				center + Vector2(12, -r * 0.7),
				center + Vector2(2, r * 0.8),
			])
			draw_colored_polygon(pts, c)
			# Lines
			draw_line(center + Vector2(-6, -10), center + Vector2(6, -10), c.darkened(0.12), 1.5)
			draw_line(center + Vector2(-4, 0), center + Vector2(4, 0), c.darkened(0.1), 1.5)
			# Green top
			draw_line(center + Vector2(0, -r * 0.7), center + Vector2(-8, -r * 0.7 - 14),
				Color(0.3, 0.65, 0.2), 3.0)
			draw_line(center + Vector2(0, -r * 0.7), center + Vector2(5, -r * 0.7 - 12),
				Color(0.35, 0.7, 0.25), 2.5)
		"egg":
			# Oval egg shape
			draw_circle(center, r * 0.85, c)
			draw_circle(center + Vector2(0, 2), r * 0.8, c.lightened(0.05))
			# Highlight
			draw_circle(center + Vector2(-6, -6), 7.0, Color(1, 1, 1, 0.35))

	# Label below
	var font := ThemeDB.fallback_font
	draw_string(font, center + Vector2(-30, r + 18), food.name,
		HORIZONTAL_ALIGNMENT_CENTER, 60, ThemeManager.font_size(14), ThemeManager.TEXT_BROWN)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), ThemeManager.LIGHT_GOLD)

	# Hint text
	var font := ThemeDB.fallback_font
	if placed_count == 0:
		draw_string(font, Vector2(size.x * 0.5 - 140, size.y * 0.08),
			"Перетащите еду на тарелку",
			HORIZONTAL_ALIGNMENT_CENTER, 280, ThemeManager.font_size(18), ThemeManager.HINT_KHAKI)

	for i in range(food_items.size()):
		var f: Dictionary = food_items[i]
		if not f.placed:
			_draw_food_shape(f.pos, f.food)

	# Counter
	draw_string(font, Vector2(size.x * 0.5 - 40, size.y - 30),
		"%d / %d" % [placed_count, target],
		HORIZONTAL_ALIGNMENT_CENTER, -1, ThemeManager.font_size(32), ThemeManager.TEXT_BROWN)


func _gui_input(event: InputEvent) -> void:
	if not is_active:
		return

	if event is InputEventMouseButton:
		if event.pressed:
			for i in range(food_items.size()):
				if not food_items[i].placed:
					if event.position.distance_to(food_items[i].pos) < food_items[i].radius * 1.5:
						_dragging_idx = i
						_drag_offset = food_items[i].pos - event.position
						break
		else:
			if _dragging_idx >= 0:
				var f: Dictionary = food_items[_dragging_idx]
				if plate_rect.has_point(f.pos):
					f.placed = true
					placed_count += 1
					if placed_count >= target:
						complete_interaction()
				_dragging_idx = -1
				queue_redraw()

	elif event is InputEventMouseMotion and _dragging_idx >= 0:
		food_items[_dragging_idx].pos = event.position + _drag_offset
		queue_redraw()
