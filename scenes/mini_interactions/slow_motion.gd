extends MiniInteractionBase
## Drag tea cup slowly across screen — too fast = restart (Day 6).

var cup_x: float = 80.0
var target_x: float = 0.0
var max_speed: float = 200.0
var _dragging: bool = false
var _last_pos: Vector2 = Vector2.ZERO
var _current_speed: float = 0.0
var too_fast_flash: float = 0.0

var _cup_sprite: Sprite2D
var _cup_tex: Texture2D = preload("res://assets/mini_interactions/tea_cup.svg")


func _setup() -> void:
	duration = 12.0
	target_x = size.x - 80.0

	# Tea cup sprite
	_cup_sprite = Sprite2D.new()
	_cup_sprite.texture = _cup_tex
	_cup_sprite.position = Vector2(cup_x, size.y * 0.45)
	_cup_sprite.scale = Vector2(1.2, 1.2)
	add_child(_cup_sprite)


func _process_interaction(delta: float) -> void:
	if too_fast_flash > 0:
		too_fast_flash -= delta
	# Update cup sprite position
	if _cup_sprite:
		_cup_sprite.position = Vector2(cup_x, size.y * 0.45)
	queue_redraw()


func _draw() -> void:
	var bg := ThemeManager.BLOOM_SOFT if too_fast_flash <= 0 else Color("#c47a5a")
	draw_rect(Rect2(Vector2.ZERO, size), bg)

	# Table surface
	draw_rect(Rect2(0, size.y * 0.55, size.x, size.y * 0.45), ThemeManager.EARTHY_BROWN)

	# Track line
	draw_line(Vector2(80, size.y * 0.5), Vector2(target_x, size.y * 0.5),
		Color(1, 1, 1, 0.3), 2.0)

	# Steam (procedural — animated)
	var cup_center := Vector2(cup_x, size.y * 0.45)
	for i in range(3):
		var steam_x := cup_center.x - 10 + i * 10
		var wave := sin(elapsed * 3.0 + i) * 3.0
		draw_line(Vector2(steam_x, cup_center.y - 35),
			Vector2(steam_x + wave, cup_center.y - 60),
			Color(1, 1, 1, 0.3), 1.5)

	# Speed indicator
	var font := ThemeDB.fallback_font
	var speed_text: String = "Медленно..." if _current_speed < max_speed * 0.5 else "Слишком быстро!"
	var speed_col: Color = ThemeManager.DEEP_LEAF if _current_speed < max_speed else ThemeManager.WARM_DANGER
	draw_string(font, Vector2(size.x * 0.5 - 60, 50), speed_text,
		HORIZONTAL_ALIGNMENT_CENTER, -1, ThemeManager.font_size(24), speed_col)

	var pct := clampf((cup_x - 80) / (target_x - 80), 0, 1) * 100
	draw_string(font, Vector2(size.x * 0.5 - 20, size.y - 30),
		"%d%%" % int(pct), HORIZONTAL_ALIGNMENT_CENTER, -1, ThemeManager.font_size(28), ThemeManager.TEXT_BROWN)


func _gui_input(event: InputEvent) -> void:
	if not is_active:
		return

	if event is InputEventMouseButton:
		var cup_pos := Vector2(cup_x, size.y * 0.45)
		if event.pressed and event.position.distance_to(cup_pos) < 80:
			_dragging = true
			_last_pos = event.position
		else:
			_dragging = false
			_current_speed = 0.0

	elif event is InputEventMouseMotion and _dragging:
		_current_speed = event.position.distance_to(_last_pos) / get_process_delta_time() if get_process_delta_time() > 0 else 0.0
		_last_pos = event.position

		if _current_speed > max_speed:
			cup_x = 80.0
			too_fast_flash = 0.3
		else:
			cup_x = clampf(event.position.x, 80, target_x)
			if cup_x >= target_x * 0.95:
				complete_interaction()
		queue_redraw()
