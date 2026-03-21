extends MiniInteractionBase
## Hold candle flame steady for 4 seconds (Trataka — Day 1).
## Tap candle to light it, then hold to keep flame steady.

var flame_stability: float = 0.0
var hold_time: float = 0.0
var target_hold: float = 4.0
var is_holding: bool = false
var is_lit: bool = false
var flame_offset: Vector2 = Vector2.ZERO
var _light_anim: float = 0.0  # 0→1 flame ignition animation

var _candle_sprite: Sprite2D
var _candle_tex: Texture2D = preload("res://assets/mini_interactions/candle.svg")
var _night_tex: Texture2D = preload("res://assets/mini_interactions/night_bg.svg")
var _night_sprite: Sprite2D


func _setup() -> void:
	duration = 12.0

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
	# Flame ignition animation
	if is_lit and _light_anim < 1.0:
		_light_anim = minf(_light_anim + delta * 2.5, 1.0)

	if is_lit and is_holding:
		hold_time += delta
		flame_offset = flame_offset.lerp(Vector2.ZERO, delta * 3.0)
		if hold_time >= target_hold:
			complete_interaction()
	elif is_lit:
		# Idle flame wobble when lit but not held
		flame_offset.x = sin(elapsed * 5.0) * 8.0
		flame_offset.y = cos(elapsed * 3.0) * 4.0
		hold_time = maxf(0.0, hold_time - delta * 0.5)
	queue_redraw()


func _draw() -> void:
	# Dark overlay — darkens as candle lights up
	var dark_alpha := 0.4 + 0.15 * _light_anim
	draw_rect(Rect2(Vector2.ZERO, size), Color("#1a1a3e", dark_alpha))

	var candle_base := Vector2(size.x * 0.5, size.y * 0.7)
	var font := ThemeDB.fallback_font

	if not is_lit:
		# Unlit state — show tap hint
		# Dark wick tip
		draw_circle(candle_base + Vector2(0, -72), 4, Color(0.2, 0.15, 0.1))

		draw_string(font, Vector2(size.x * 0.5 - 100, size.y * 0.2),
			"Нажмите, чтобы зажечь",
			HORIZONTAL_ALIGNMENT_CENTER, 200, ThemeManager.font_size(22), ThemeManager.LIGHT_GOLD)
		return

	# Flame (procedural — animated wobble, grows on ignition)
	var flame_scale := _light_anim
	var flame_center := candle_base + Vector2(0, -80) + flame_offset
	var stability := 1.0 - flame_offset.length() / 10.0

	# Outer glow — warm ambient light
	var glow_r := (50.0 + sin(elapsed * 4.0) * 8.0) * flame_scale
	draw_circle(flame_center, glow_r * 2.0, Color(1.0, 0.8, 0.3, 0.04 * flame_scale))
	draw_circle(flame_center, glow_r * 1.5, Color(1.0, 0.85, 0.4, 0.06 * flame_scale))
	draw_circle(flame_center, glow_r, Color(1.0, 0.9, 0.5, 0.1 + stability * 0.1) * Color(1, 1, 1, flame_scale))

	# Flame body — outer orange
	var flame_r := 18.0 * flame_scale
	var flame_color := Color(1.0, 0.65, 0.15, (0.7 + stability * 0.3) * flame_scale)
	draw_circle(flame_center, flame_r, flame_color)
	# Flame tip — elongated upward
	var tip_offset := flame_offset * 0.3
	draw_circle(flame_center + Vector2(0, -10 * flame_scale) + tip_offset,
		flame_r * 0.6, Color(1.0, 0.5, 0.1, 0.8 * flame_scale))

	# Inner bright core — yellow-white
	draw_circle(flame_center + Vector2(0, 4 * flame_scale), 12 * flame_scale,
		Color(1.0, 0.95, 0.6, 0.9 * flame_scale))
	# Hottest center — white
	draw_circle(flame_center + Vector2(0, 8 * flame_scale), 6 * flame_scale,
		Color(1.0, 1.0, 0.95, 0.7 * flame_scale))

	# Progress arc
	var pct := clampf(hold_time / target_hold, 0.0, 1.0)
	draw_arc(Vector2(size.x * 0.5, size.y * 0.25), 40, -PI / 2, -PI / 2 + TAU * pct,
		32, ThemeManager.GOLDEN_AMBER, 4.0)

	var text: String
	if not is_holding:
		text = "Удерживайте пламя"
	else:
		text = "%.1f с" % hold_time
	draw_string(font, Vector2(size.x * 0.5 - 80, size.y * 0.15), text,
		HORIZONTAL_ALIGNMENT_CENTER, -1, ThemeManager.font_size(24), ThemeManager.LIGHT_GOLD)


func _gui_input(event: InputEvent) -> void:
	if not is_active:
		return
	if event is InputEventMouseButton:
		var candle_pos := Vector2(size.x * 0.5, size.y * 0.7 - 30)
		if event.pressed and not is_lit and event.position.distance_to(candle_pos) < 120:
			# Light the candle on first tap
			is_lit = true
			return
		if is_lit:
			is_holding = event.pressed and event.position.distance_to(candle_pos) < 100
