extends MiniInteractionBase
## Drag 4 food items onto a plate.

var food_items: Array[Dictionary] = []
var plate_rect: Rect2
var placed_count: int = 0
var target: int = 4
var _dragging_idx: int = -1
var _drag_offset: Vector2 = Vector2.ZERO

const FOOD_EMOJIS := ["🥣", "🍎", "🥗", "🍞", "🥚", "🍲", "🧀", "🥕"]

var _plate_sprite: Sprite2D
var _plate_tex: Texture2D = preload("res://assets/mini_interactions/plate.svg")
var _food_tex: Texture2D = preload("res://assets/mini_interactions/food_item.svg")
var _food_sprites: Array[Sprite2D] = []


func _setup() -> void:
	duration = 10.0
	plate_rect = Rect2(size.x * 0.55, size.y * 0.35, size.x * 0.35, size.x * 0.35)

	# Plate sprite
	_plate_sprite = Sprite2D.new()
	_plate_sprite.texture = _plate_tex
	_plate_sprite.position = plate_rect.get_center()
	var plate_s: float = plate_rect.size.x / 120.0
	_plate_sprite.scale = Vector2(plate_s, plate_s)
	add_child(_plate_sprite)

	var rng := RandomNumberGenerator.new()
	rng.seed = 999
	for i in range(target):
		var pos := Vector2(size.x * 0.12, size.y * 0.15 + i * 100)
		food_items.append({
			"pos": pos,
			"emoji": FOOD_EMOJIS[rng.randi_range(0, FOOD_EMOJIS.size() - 1)],
			"placed": false,
			"radius": 35.0,
		})
		var spr := Sprite2D.new()
		spr.texture = _food_tex
		spr.position = pos
		spr.scale = Vector2(1.8, 1.8)
		add_child(spr)
		_food_sprites.append(spr)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), ThemeManager.LIGHT_GOLD)

	# Update food sprite positions
	var font := ThemeDB.fallback_font
	for i in range(food_items.size()):
		var f: Dictionary = food_items[i]
		if i < _food_sprites.size():
			_food_sprites[i].position = f.pos
			_food_sprites[i].visible = not f.placed
		if not f.placed:
			draw_string(font, f.pos + Vector2(-15, 12), f.emoji,
				HORIZONTAL_ALIGNMENT_CENTER, -1, ThemeManager.font_size(36))

	draw_string(font, Vector2(size.x * 0.5 - 40, size.y - 30),
		"%d/%d" % [placed_count, target],
		HORIZONTAL_ALIGNMENT_CENTER, -1, ThemeManager.font_size(28), ThemeManager.TEXT_BROWN)


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
