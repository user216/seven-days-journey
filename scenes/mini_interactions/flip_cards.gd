extends MiniInteractionBase
## Tap face-down cards to flip and reveal food/lecture items.

var cards: Array[Dictionary] = []
var flipped_count: int = 0
var target_count: int = 3

var _card_back_tex: Texture2D = preload("res://assets/mini_interactions/card_back.svg")
var _card_front_tex: Texture2D = preload("res://assets/mini_interactions/card_front.svg")
var _card_sprites: Array[Sprite2D] = []


func _setup() -> void:
	duration = 8.0
	var card_w := size.x * 0.25
	var card_h := size.y * 0.35
	var spacing := (size.x - card_w * target_count) / float(target_count + 1)
	var emojis := ["🥗", "🍎", "🥣"]
	for i in range(target_count):
		var r := Rect2(spacing + i * (card_w + spacing), size.y * 0.3, card_w, card_h)
		cards.append({
			"rect": r,
			"emoji": emojis[i % emojis.size()],
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


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), ThemeManager.MINT_SAGE)

	var font := ThemeDB.fallback_font
	for i in range(cards.size()):
		var c: Dictionary = cards[i]
		if c.flipped:
			# Switch sprite to front texture
			if i < _card_sprites.size():
				_card_sprites[i].texture = _card_front_tex
			var r: Rect2 = c.rect
			draw_string(font, Vector2(r.position.x + r.size.x * 0.35, r.position.y + r.size.y * 0.55),
				c.emoji, HORIZONTAL_ALIGNMENT_CENTER, -1, ThemeManager.font_size(48), ThemeManager.TEXT_BROWN)

	draw_string(font, Vector2(size.x * 0.5 - 40, size.y - 30),
		"%d/%d" % [flipped_count, target_count],
		HORIZONTAL_ALIGNMENT_CENTER, -1, ThemeManager.font_size(28), ThemeManager.TEXT_BROWN)


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
