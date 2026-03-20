extends MiniInteractionBase
## Swipe curtain from left to right to close the window.

var curtain_x: float = 0.0
var target_x: float = 0.0
var _dragging: bool = false

var _window_sprite: Sprite2D
var _window_tex: Texture2D = preload("res://assets/mini_interactions/window_frame.svg")


func _setup() -> void:
	duration = 8.0
	target_x = size.x

	# Window with night sky
	_window_sprite = Sprite2D.new()
	_window_sprite.texture = _window_tex
	_window_sprite.position = size * 0.5
	var sx: float = size.x / 400.0
	var sy: float = size.y / 500.0
	_window_sprite.scale = Vector2(sx, sy)
	add_child(_window_sprite)


func _draw() -> void:
	# Curtain (procedural — position changes)
	var curtain_rect := Rect2(0, 0, curtain_x, size.y)
	draw_rect(curtain_rect, ThemeManager.TERRACOTTA)

	# Curtain folds
	for i in range(int(curtain_x / 30)):
		var fold_x := float(i) * 30.0
		draw_line(Vector2(fold_x, 0), Vector2(fold_x, size.y),
			Color(0, 0, 0, 0.1), 2.0)

	# Handle
	draw_circle(Vector2(curtain_x, size.y * 0.5), 20, ThemeManager.GOLDEN_AMBER)
	draw_circle(Vector2(curtain_x, size.y * 0.5), 10, Color("#e0bc60"))

	# Progress hint
	var pct := int(curtain_x / target_x * 100)
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(size.x * 0.5 - 30, size.y - 20),
		"%d%%" % pct, HORIZONTAL_ALIGNMENT_CENTER, -1, ThemeManager.font_size(24), Color.WHITE)


func _gui_input(event: InputEvent) -> void:
	if not is_active:
		return

	if event is InputEventMouseButton:
		var handle_pos := Vector2(curtain_x, size.y * 0.5)
		if event.pressed and event.position.distance_to(handle_pos) < 60:
			_dragging = true
		else:
			_dragging = false

	elif event is InputEventMouseMotion and _dragging:
		curtain_x = clampf(event.position.x, 0, target_x)
		queue_redraw()
		if curtain_x >= target_x * 0.95:
			complete_interaction()
