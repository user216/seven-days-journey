extends MiniInteractionBase
## Drag 5 thought bubbles off screen to release them (Day 5).

var thoughts: Array[Dictionary] = []
var released: int = 0
var target: int = 5
var _dragging_idx: int = -1
var _drag_offset: Vector2 = Vector2.ZERO

var thought_texts := ["Страх", "Тревога", "Сомнение", "Суета", "Усталость"]

var _cloud_tex: Texture2D = preload("res://assets/mini_interactions/thought_cloud.svg")
var _cloud_sprites: Array[Sprite2D] = []


func _setup() -> void:
	duration = 12.0
	for i in range(target):
		var pos := Vector2(size.x * 0.5, size.y * 0.15 + i * (size.y * 0.15))
		thoughts.append({
			"pos": pos,
			"text": thought_texts[i],
			"active": true,
			"alpha": 1.0,
		})
		var spr := Sprite2D.new()
		spr.texture = _cloud_tex
		spr.position = pos
		spr.scale = Vector2(1.8, 1.8)
		add_child(spr)
		_cloud_sprites.append(spr)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#1a1a3e"))

	var font := ThemeDB.fallback_font
	for i in range(thoughts.size()):
		var t: Dictionary = thoughts[i]
		if not t.active:
			if i < _cloud_sprites.size():
				_cloud_sprites[i].visible = false
			continue
		if i < _cloud_sprites.size():
			_cloud_sprites[i].position = t.pos
			_cloud_sprites[i].modulate.a = t.alpha
		var text_alpha := Color(ThemeManager.LIGHT_GOLD.r, ThemeManager.LIGHT_GOLD.g,
			ThemeManager.LIGHT_GOLD.b, t.alpha)
		draw_string(font, t.pos + Vector2(-35, 8), t.text,
			HORIZONTAL_ALIGNMENT_CENTER, 80, ThemeManager.font_size(22), text_alpha)

	draw_string(font, Vector2(size.x * 0.5 - 60, size.y - 30),
		"Отпущено: %d/%d" % [released, target],
		HORIZONTAL_ALIGNMENT_CENTER, -1, ThemeManager.font_size(24), ThemeManager.LIGHT_GOLD)


func _gui_input(event: InputEvent) -> void:
	if not is_active:
		return

	if event is InputEventMouseButton:
		if event.pressed:
			for i in range(thoughts.size()):
				if thoughts[i].active and event.position.distance_to(thoughts[i].pos) < 70:
					_dragging_idx = i
					_drag_offset = thoughts[i].pos - event.position
					break
		else:
			if _dragging_idx >= 0:
				var t: Dictionary = thoughts[_dragging_idx]
				if t.pos.x < -30 or t.pos.x > size.x + 30 or t.pos.y < -30 or t.pos.y > size.y + 30:
					t.active = false
					released += 1
					if released >= target:
						complete_interaction()
				_dragging_idx = -1
				queue_redraw()

	elif event is InputEventMouseMotion and _dragging_idx >= 0:
		thoughts[_dragging_idx].pos = event.position + _drag_offset
		queue_redraw()
