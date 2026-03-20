extends Node2D
## Climbing hero for vertical mode — SVG sprite, gender-aware.
## Enhanced: bigger sprite, squash & stretch, landing bounce.

var target_pos: Vector2 = Vector2.ZERO
var speed: float = 600.0
var is_jumping: bool = false
var _anim_time: float = 0.0
var dress_color: Color = ThemeManager.MINT_SAGE

var _idle_tex: Texture2D
var _jump_tex: Texture2D
var _sprite: Sprite2D

const BASE_SCALE := 1.8
var _squash_time: float = 0.0


func _ready() -> void:
	target_pos = position
	dress_color = ThemeManager.get_dress_color(GameState.current_day)

	if GameState.gender == "male":
		_idle_tex = load("res://assets/hero/climb/hero_climb_idle_male.svg")
		_jump_tex = load("res://assets/hero/climb/hero_climb_jump_male.svg")
	else:
		_idle_tex = load("res://assets/hero/climb/hero_climb_idle.svg")
		_jump_tex = load("res://assets/hero/climb/hero_climb_jump.svg")

	_sprite = Sprite2D.new()
	_sprite.texture = _idle_tex
	_sprite.scale = Vector2(BASE_SCALE, BASE_SCALE)
	_sprite.self_modulate = dress_color
	_sprite.position = Vector2(0, -45)
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
			_squash_time = 0.3  # trigger landing squash
			if _sprite:
				_sprite.texture = _idle_tex
		else:
			var dir := diff.normalized()
			position += dir * minf(speed * delta, dist)

	# Squash & stretch animations
	if _sprite:
		var sx: float = BASE_SCALE
		var sy: float = BASE_SCALE
		if is_jumping:
			# Stretch vertically while jumping
			sy = BASE_SCALE * (1.0 + sin(_anim_time * 10.0) * 0.08)
			sx = BASE_SCALE * (1.0 - sin(_anim_time * 10.0) * 0.04)
		elif _squash_time > 0.0:
			# Landing squash (wide + short) then bounce back
			_squash_time -= delta
			var t := _squash_time / 0.3
			var squash := sin(t * PI) * 0.12
			sx = BASE_SCALE * (1.0 + squash)
			sy = BASE_SCALE * (1.0 - squash)
		else:
			# Gentle idle bobbing
			var bob := sin(_anim_time * 2.5) * 0.015
			sy = BASE_SCALE * (1.0 + bob)
		_sprite.scale = Vector2(sx, sy)
