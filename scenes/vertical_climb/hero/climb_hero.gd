extends Node2D
## Climbing hero for vertical mode — SVG sprite, gender-aware.

var target_pos: Vector2 = Vector2.ZERO
var speed: float = 500.0
var is_jumping: bool = false
var _anim_time: float = 0.0
var dress_color: Color = ThemeManager.MINT_SAGE

var _idle_tex: Texture2D
var _jump_tex: Texture2D
var _sprite: Sprite2D


func _ready() -> void:
	target_pos = position
	dress_color = ThemeManager.get_dress_color(GameState.current_day)

	# Load gender-appropriate textures
	if GameState.gender == "male":
		_idle_tex = load("res://assets/hero/climb/hero_climb_idle_male.svg")
		_jump_tex = load("res://assets/hero/climb/hero_climb_jump_male.svg")
	else:
		_idle_tex = load("res://assets/hero/climb/hero_climb_idle.svg")
		_jump_tex = load("res://assets/hero/climb/hero_climb_jump.svg")

	_sprite = Sprite2D.new()
	_sprite.texture = _idle_tex
	_sprite.scale = Vector2(1.2, 1.2)
	_sprite.self_modulate = dress_color
	_sprite.position = Vector2(0, -30)
	add_child(_sprite)


func jump_to(pos: Vector2) -> void:
	target_pos = pos
	is_jumping = true
	if _sprite:
		_sprite.texture = _jump_tex


func _process(delta: float) -> void:
	_anim_time += delta
	if is_jumping:
		var diff := target_pos - position
		var dist := diff.length()
		if dist < 5.0:
			position = target_pos
			is_jumping = false
			if _sprite:
				_sprite.texture = _idle_tex
		else:
			var dir := diff.normalized()
			var move_speed := minf(speed * delta, dist)
			position += dir * move_speed
	# Stretch animation during jump
	if _sprite:
		var stretch: float = 1.0
		if is_jumping:
			stretch = 1.0 + sin(_anim_time * 10.0) * 0.05
		_sprite.scale = Vector2(1.2, 1.2 * stretch)
