extends Node2D
## Companion hero for RPG garden walk mode — walks between stations with speech bubbles.

signal arrived_at_station(station_idx: int)

const WALK_SPEED := 200.0
const HERO_SCALE := Vector2(0.8, 0.8)

var _target_x: float = 0.0
var _walking: bool = false
var _sprite: Sprite2D
var _speech_bubble: Control = null
var _shadow: Sprite2D


func _ready() -> void:
	_build_hero()


func _build_hero() -> void:
	# Shadow
	_shadow = Sprite2D.new()
	var shadow_img := Image.create(40, 12, false, Image.FORMAT_RGBA8)
	var shadow_center := Vector2(20, 6)
	for y in range(12):
		for x in range(40):
			var dist := Vector2(x, y).distance_to(shadow_center) / 20.0
			var alpha := clampf(1.0 - dist, 0.0, 1.0) * 0.3
			shadow_img.set_pixel(x, y, Color(0, 0, 0, alpha))
	_shadow.texture = ImageTexture.create_from_image(shadow_img)
	_shadow.position = Vector2(0, 60)
	add_child(_shadow)

	# Hero sprite — try to load the SVG, fallback to colored circle
	_sprite = Sprite2D.new()
	var hero_gender := GameState.gender
	var hair_suffix := GameState.get_hair_style_suffix()
	var svg_path := "res://assets/hero/%s%s.svg" % [hero_gender, hair_suffix]
	var hero_tex := load(svg_path) as Texture2D
	if hero_tex:
		_sprite.texture = hero_tex
		_sprite.scale = HERO_SCALE
		# Apply tints via shader
		var tint_shader := load("res://shaders/hero_tint.gdshader") as Shader
		if tint_shader:
			var mat := ShaderMaterial.new()
			mat.shader = tint_shader
			mat.set_shader_parameter("skin_tint", GameState.get_skin_tint())
			mat.set_shader_parameter("hair_tint", GameState.get_hair_tint())
			mat.set_shader_parameter("dress_color", ThemeManager.get_dress_color(GameState.current_day))
			_sprite.material = mat
	else:
		# Fallback: circle placeholder
		var img := Image.create(80, 120, false, Image.FORMAT_RGBA8)
		var center := Vector2(40, 50)
		for y in range(120):
			for x in range(80):
				var dist := Vector2(x, y).distance_to(center) / 40.0
				if dist < 1.0:
					img.set_pixel(x, y, ThemeManager.SAGE_GREEN)
		_sprite.texture = ImageTexture.create_from_image(img)
	add_child(_sprite)


func walk_to(target_x: float) -> void:
	_target_x = target_x
	_walking = true


func show_speech(text: String, auto_hide: float = 0.0) -> Control:
	if _speech_bubble:
		_speech_bubble.queue_free()
	var bubble_script := load("res://scenes/hero_dialogue/rpg_companion/speech_bubble.gd")
	_speech_bubble = Control.new()
	_speech_bubble.set_script(bubble_script)
	_speech_bubble.position = Vector2(-150, -180)
	add_child(_speech_bubble)
	_speech_bubble.show_text(text, auto_hide)
	return _speech_bubble


func _process(delta: float) -> void:
	if not _walking:
		return

	var diff := _target_x - position.x
	if absf(diff) < 5.0:
		position.x = _target_x
		_walking = false
		_sprite.rotation = 0.0
		return

	var direction := signf(diff)
	position.x += direction * WALK_SPEED * delta

	# Walking animation: gentle bob
	_sprite.position.y = sin(position.x * 0.05) * 3.0
	# Flip to face direction
	_sprite.flip_h = direction < 0
	# Gentle tilt
	_sprite.rotation = direction * 0.03
