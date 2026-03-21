extends MiniInteractionBase
## Tap face-down cards to flip and reveal wellness symbols.

var cards: Array[Dictionary] = []
var flipped_count: int = 0
var target_count: int = 3

var _card_back_tex: Texture2D = preload("res://assets/mini_interactions/card_back.svg")
var _card_front_tex: Texture2D = preload("res://assets/mini_interactions/card_front.svg")
var _card_sprites: Array[Sprite2D] = []

# Procedural card symbols (drawn, not emoji-dependent)
const CARD_SYMBOLS := [
	{"name": "Здоровье", "color": Color(0.35, 0.7, 0.3), "symbol": "leaf"},
	{"name": "Гармония", "color": Color(0.85, 0.65, 0.15), "symbol": "sun"},
	{"name": "Энергия", "color": Color(0.3, 0.6, 0.9), "symbol": "drop"},
]


func _setup() -> void:
	duration = 8.0
	var card_w := size.x * 0.27
	var card_h := size.y * 0.38
	var spacing := (size.x - card_w * target_count) / float(target_count + 1)
	for i in range(target_count):
		var r := Rect2(spacing + i * (card_w + spacing), size.y * 0.25, card_w, card_h)
		cards.append({
			"rect": r,
			"symbol": CARD_SYMBOLS[i % CARD_SYMBOLS.size()],
			"flipped": false,
		})
		var spr := Sprite2D.new()
		spr.texture = _card_back_tex
		spr.position = r.get_center()
		var sx: float = card_w / 112.0
		var sy: float = card_h / 162.0
		spr.scale = Vector2(sx, sy)
		add_child(spr)
		_card_sprites.append(spr)


func _draw_card_symbol(center: Vector2, sym: Dictionary) -> void:
	var c: Color = sym.color
	match sym.symbol:
		"leaf":
			# Leaf shape — two curved halves
			draw_circle(center, 22.0, c.lightened(0.2))
			var pts := PackedVector2Array([
				center + Vector2(0, -24),
				center + Vector2(18, -4),
				center + Vector2(0, 24),
				center + Vector2(-18, -4),
			])
			draw_colored_polygon(pts, c)
			# Center vein
			draw_line(center + Vector2(0, -18), center + Vector2(0, 18), c.darkened(0.2), 2.5)
			# Side veins
			draw_line(center + Vector2(0, -6), center + Vector2(10, -14), c.darkened(0.15), 1.5)
			draw_line(center + Vector2(0, -6), center + Vector2(-10, -14), c.darkened(0.15), 1.5)
			draw_line(center + Vector2(0, 6), center + Vector2(8, -2), c.darkened(0.12), 1.5)
			draw_line(center + Vector2(0, 6), center + Vector2(-8, -2), c.darkened(0.12), 1.5)
		"sun":
			# Sun with rays
			draw_circle(center, 16.0, c)
			draw_circle(center, 12.0, c.lightened(0.2))
			# Rays
			for ang in range(0, 360, 45):
				var rad := deg_to_rad(float(ang))
				var inner := center + Vector2(cos(rad), sin(rad)) * 18.0
				var outer := center + Vector2(cos(rad), sin(rad)) * 28.0
				draw_line(inner, outer, c, 3.0)
			# Center highlight
			draw_circle(center + Vector2(-3, -3), 5.0, Color(1, 1, 1, 0.4))
		"drop":
			# Water drop
			var pts := PackedVector2Array([
				center + Vector2(0, -22),
				center + Vector2(14, 6),
				center + Vector2(10, 16),
				center + Vector2(0, 22),
				center + Vector2(-10, 16),
				center + Vector2(-14, 6),
			])
			draw_colored_polygon(pts, c)
			draw_circle(center + Vector2(0, 8), 12.0, c.lightened(0.1))
			# Highlight
			draw_circle(center + Vector2(-4, 2), 5.0, Color(1, 1, 1, 0.4))
			draw_circle(center + Vector2(-2, -4), 3.0, Color(1, 1, 1, 0.3))

	# Label below symbol
	var font := ThemeDB.fallback_font
	draw_string(font, center + Vector2(-35, 38), sym.name,
		HORIZONTAL_ALIGNMENT_CENTER, 70, ThemeManager.font_size(14), ThemeManager.TEXT_BROWN)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), ThemeManager.MINT_SAGE)

	# Hint text
	var font := ThemeDB.fallback_font
	if flipped_count == 0:
		draw_string(font, Vector2(size.x * 0.5 - 120, size.y * 0.15),
			"Нажмите на карту",
			HORIZONTAL_ALIGNMENT_CENTER, 240, ThemeManager.font_size(20), ThemeManager.HINT_KHAKI)

	for i in range(cards.size()):
		var c: Dictionary = cards[i]
		if c.flipped:
			if i < _card_sprites.size():
				_card_sprites[i].texture = _card_front_tex
			var r: Rect2 = c.rect
			_draw_card_symbol(r.get_center(), c.symbol)

	draw_string(font, Vector2(size.x * 0.5 - 40, size.y - 30),
		"%d / %d" % [flipped_count, target_count],
		HORIZONTAL_ALIGNMENT_CENTER, -1, ThemeManager.font_size(32), ThemeManager.TEXT_BROWN)


func _gui_input(event: InputEvent) -> void:
	if not is_active:
		return
	if event is InputEventMouseButton and event.pressed:
		for c in cards:
			if not c.flipped and c.rect.has_point(event.position):
				c.flipped = true
				flipped_count += 1
				queue_redraw()
				if flipped_count >= target_count:
					complete_interaction()
				break
