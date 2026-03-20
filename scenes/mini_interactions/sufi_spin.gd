extends MiniInteractionBase
## Draw 3 circular gestures — Sufi spinning (Day 4).

var circles_done: int = 0
var target_circles: int = 3
var path_points: PackedVector2Array = PackedVector2Array()
var _is_drawing: bool = false
var _touch_utils := TouchUtils.new()


func _setup() -> void:
	duration = 12.0


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#2a1a40"))

	# Guide circle
	var center := size * 0.5
	draw_arc(center, 120, 0, TAU, 64, Color(1, 1, 1, 0.15), 3.0)

	# Current path
	if path_points.size() >= 2:
		draw_polyline(path_points, ThemeManager.GOLDEN_AMBER, 4.0)

	# Completed circles indicator
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(size.x * 0.5 - 40, 50),
		"💫 %d/%d" % [circles_done, target_circles],
		HORIZONTAL_ALIGNMENT_CENTER, -1, ThemeManager.font_size(32), ThemeManager.LIGHT_GOLD)

	draw_string(font, Vector2(size.x * 0.5 - 70, size.y - 40),
		"Рисуйте круг",
		HORIZONTAL_ALIGNMENT_CENTER, -1, ThemeManager.font_size(24), Color(1, 1, 1, 0.6))


func _gui_input(event: InputEvent) -> void:
	if not is_active:
		return

	if event is InputEventMouseButton:
		if event.pressed:
			_is_drawing = true
			path_points = PackedVector2Array([event.position])
			_touch_utils.on_touch_start(event.position, elapsed)
		else:
			_is_drawing = false
			_touch_utils.on_touch_move(event.position)
			var gesture := _touch_utils.on_touch_end(event.position, elapsed)
			if gesture == TouchUtils.GestureType.CIRCLE or _check_circle_manual():
				circles_done += 1
				path_points = PackedVector2Array()
				if circles_done >= target_circles:
					complete_interaction()
			else:
				path_points = PackedVector2Array()
			queue_redraw()

	elif event is InputEventMouseMotion and _is_drawing:
		path_points.append(event.position)
		_touch_utils.on_touch_move(event.position)
		queue_redraw()


func _check_circle_manual() -> bool:
	if path_points.size() < 15:
		return false
	var center := Vector2.ZERO
	for p in path_points:
		center += p
	center /= float(path_points.size())
	var avg_r := 0.0
	for p in path_points:
		avg_r += center.distance_to(p)
	avg_r /= float(path_points.size())
	if avg_r < 40:
		return false
	var variance := 0.0
	for p in path_points:
		var diff := center.distance_to(p) - avg_r
		variance += diff * diff
	variance /= float(path_points.size())
	return sqrt(variance) / avg_r < 0.4
