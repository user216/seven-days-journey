extends MiniInteractionBase
## Hold candle flame steady for 4 seconds (Trataka — Day 1).

var flame_stability: float = 0.0
var hold_time: float = 0.0
var target_hold: float = 4.0
var is_holding: bool = false
var flame_offset: Vector2 = Vector2.ZERO

var _candle_sprite: Sprite2D
var _candle_tex: Texture2D = preload("res://assets/mini_interactions/candle.svg")
var _night_tex: Texture2D = preload("res://assets/mini_interactions/night_bg.svg")
var _night_sprite: Sprite2D


func _setup() -> void:
	duration = 10.0

	# Night background
	_night_sprite = Sprite2D.new()
	_night_sprite.texture = _night_tex
	_night_sprite.position = size * 0.5
	var bg_sx: float = size.x / 540.0
	var bg_sy: float = size.y / 960.0
	_night_sprite.scale = Vector2(bg_sx, bg_sy)
	_night_sprite.modulate.a = 0.6
	add_child(_night_sprite)

	# Candle sprite
	_candle_sprite = Sprite2D.new()
	_candle_sprite.texture = _candle_tex
	_candle_sprite.position = Vector2(size.x * 0.5, size.y * 0.72)
	_candle_sprite.scale = Vector2(2.5, 2.5)
	add_child(_candle_sprite)


func _process_interaction(delta: float) -> void:
	if is_holding:
		hold_time += delta
		flame_offset = flame_offset.lerp(Vector2.ZERO, delta * 3.0)
		if hold_time >= target_hold:
			complete_interaction()
	else:
		flame_offset.x = sin(elapsed * 5.0) * 8.0
		flame_offset.y = cos(elapsed * 3.0) * 4.0
		hold_time = maxf(0.0, hold_time - delta * 0.5)
	queue_redraw()


func _draw() -> void:
	# Dark overlay
	draw_rect(Rect2(Vector2.ZERO, size), Color("#1a1a3e", 0.4))

	var candle_base := Vector2(size.x * 0.5, size.y * 0.7)

	# Flame (procedural — animated wobble)
	var flame_center := candle_base + Vector2(0, -80) + flame_offset
	var stability := 1.0 - flame_offset.length() / 10.0
	var flame_color := Color(1.0, 0.85, 0.3, 0.7 + stability * 0.3)
	draw_circle(flame_center, 18, flame_color)
	draw_circle(flame_center + Vector2(0, -8), 12, Color(1.0, 0.95, 0.6, 0.9))

	# Glow
	draw_circle(flame_center, 50, Color(1.0, 0.9, 0.5, 0.1 + stability * 0.1))

	# Progress
	var pct := clampf(hold_time / target_hold, 0.0, 1.0)
	draw_arc(Vector2(size.x * 0.5, size.y * 0.25), 40, -PI/2, -PI/2 + TAU * pct,
		32, ThemeManager.GOLDEN_AMBER, 4.0)

	var font := ThemeDB.fallback_font
	var text: String = "Удерживайте пламя" if not is_holding else "%.1f с" % hold_time
	draw_string(font, Vector2(size.x * 0.5 - 80, size.y * 0.15), text,
		HORIZONTAL_ALIGNMENT_CENTER, -1, ThemeManager.font_size(24), ThemeManager.LIGHT_GOLD)


func _gui_input(event: InputEvent) -> void:
	if not is_active:
		return
	if event is InputEventMouseButton:
		var flame_pos := Vector2(size.x * 0.5, size.y * 0.7 - 30)
		is_holding = event.pressed and event.position.distance_to(flame_pos) < 100
