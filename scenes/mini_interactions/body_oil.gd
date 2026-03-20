extends MiniInteractionBase
## Circular rub on 3 body areas — body oiling (Day 7).

var areas: Array[Dictionary] = []
var completed_areas: int = 0
var target: int = 3
var _current_area: int = -1
var _rub_points: PackedVector2Array = PackedVector2Array()

var _body_sprite: Sprite2D
var _body_tex: Texture2D = preload("res://assets/mini_interactions/body_silhouette.svg")


func _setup() -> void:
	duration = 12.0
	areas = [
		{"pos": Vector2(size.x * 0.5, size.y * 0.2), "label": "Плечи", "done": false, "progress": 0.0},
		{"pos": Vector2(size.x * 0.5, size.y * 0.45), "label": "Спина", "done": false, "progress": 0.0},
		{"pos": Vector2(size.x * 0.5, size.y * 0.7), "label": "Ноги", "done": false, "progress": 0.0},
	]

	# Body silhouette sprite
	_body_sprite = Sprite2D.new()
	_body_sprite.texture = _body_tex
	_body_sprite.position = Vector2(size.x * 0.5, size.y * 0.48)
	var sx: float = size.x * 0.5 / 200.0
	var sy: float = size.y * 0.8 / 400.0
	_body_sprite.scale = Vector2(sx, sy)
	add_child(_body_sprite)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), ThemeManager.BLOOM_SOFT)

	var font := ThemeDB.fallback_font

	# Areas (overlaid on body sprite)
	for a in areas:
		var col: Color
		if a.done:
			col = Color(ThemeManager.GOLDEN_AMBER.r, ThemeManager.GOLDEN_AMBER.g,
				ThemeManager.GOLDEN_AMBER.b, 0.6)
		else:
			col = Color(1, 1, 1, 0.3)
		draw_circle(a.pos, 50, col)

		# Progress ring
		if a.progress > 0 and not a.done:
			draw_arc(a.pos, 55, -PI/2, -PI/2 + TAU * a.progress,
				32, ThemeManager.SAGE_GREEN, 4.0)

		draw_string(font, a.pos + Vector2(-25, 8), a.label,
			HORIZONTAL_ALIGNMENT_CENTER, 60, ThemeManager.font_size(18), ThemeManager.TEXT_BROWN)

	draw_string(font, Vector2(size.x * 0.5 - 40, size.y - 30),
		"🌿 %d/%d" % [completed_areas, target],
		HORIZONTAL_ALIGNMENT_CENTER, -1, ThemeManager.font_size(28), ThemeManager.TEXT_BROWN)


func _gui_input(event: InputEvent) -> void:
	if not is_active:
		return

	if event is InputEventMouseButton:
		if event.pressed:
			_current_area = _find_area(event.position)
			_rub_points = PackedVector2Array([event.position])
		else:
			if _current_area >= 0 and not areas[_current_area].done:
				if _rub_points.size() >= 8:
					areas[_current_area].progress = minf(areas[_current_area].progress + 0.4, 1.0)
					if areas[_current_area].progress >= 1.0:
						areas[_current_area].done = true
						completed_areas += 1
						if completed_areas >= target:
							complete_interaction()
			_current_area = -1
			_rub_points = PackedVector2Array()
			queue_redraw()

	elif event is InputEventMouseMotion and _current_area >= 0:
		_rub_points.append(event.position)
		queue_redraw()


func _find_area(pos: Vector2) -> int:
	for i in range(areas.size()):
		if not areas[i].done and pos.distance_to(areas[i].pos) < 60:
			return i
	return -1
