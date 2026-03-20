extends MiniInteractionBase
## Tap the rising sun 5 times to complete.

var sun_y: float = 0.0
var tap_count: int = 0
var target_taps: int = 5
var sun_radius: float = 60.0

var _bg_sprite: Sprite2D
var _sun_sprite: Sprite2D
var _bg_tex: Texture2D = preload("res://assets/mini_interactions/sunrise_bg.svg")
var _sun_tex: Texture2D = preload("res://assets/nature/sun.svg")


func _setup() -> void:
	duration = 8.0
	sun_y = size.y * 0.8

	# Background scene
	_bg_sprite = Sprite2D.new()
	_bg_sprite.texture = _bg_tex
	_bg_sprite.position = size * 0.5
	var bg_sx: float = size.x / 540.0
	var bg_sy: float = size.y / 960.0
	_bg_sprite.scale = Vector2(bg_sx, bg_sy)
	add_child(_bg_sprite)

	# Sun sprite
	_sun_sprite = Sprite2D.new()
	_sun_sprite.texture = _sun_tex
	_sun_sprite.position = Vector2(size.x * 0.5, sun_y)
	add_child(_sun_sprite)


func _draw() -> void:
	# Update sun sprite position and scale
	if _sun_sprite:
		_sun_sprite.position = Vector2(size.x * 0.5, sun_y)
		var s: float = sun_radius / 60.0
		_sun_sprite.scale = Vector2(s, s)

	# Tap counter
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(size.x * 0.5 - 40, 40), "%d/%d" % [tap_count, target_taps],
		HORIZONTAL_ALIGNMENT_CENTER, -1, ThemeManager.font_size(32), ThemeManager.TEXT_BROWN)


func _gui_input(event: InputEvent) -> void:
	if not is_active:
		return
	if event is InputEventMouseButton and event.pressed:
		var sun_center := Vector2(size.x * 0.5, sun_y)
		if event.position.distance_to(sun_center) < sun_radius * 2.0:
			tap_count += 1
			sun_y -= (size.y * 0.5) / float(target_taps)
			sun_radius += 5.0
			queue_redraw()
			if tap_count >= target_taps:
				complete_interaction()
