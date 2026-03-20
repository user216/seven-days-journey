extends Node2D
## Top-down hero — SVG sprite character viewed from above.

var target_pos: Vector2 = Vector2.ZERO
var speed: float = 250.0
var is_walking: bool = false
var _anim_time: float = 0.0
var dress_color: Color = ThemeManager.MINT_SAGE

var _idle_tex: Texture2D = preload("res://assets/hero/top/hero_top_idle.svg")
var _walk_tex: Texture2D = preload("res://assets/hero/top/hero_top_walk.svg")
var _sprite: Sprite2D


func _ready() -> void:
	target_pos = position
	dress_color = ThemeManager.get_dress_color(GameState.current_day)

	_sprite = Sprite2D.new()
	_sprite.texture = _idle_tex
	_sprite.scale = Vector2(1.5, 1.5)
	_sprite.self_modulate = dress_color
	add_child(_sprite)


func walk_to(pos: Vector2) -> void:
	target_pos = pos
	is_walking = true
	if _sprite:
		_sprite.texture = _walk_tex


func _process(delta: float) -> void:
	_anim_time += delta
	if is_walking:
		var dir := (target_pos - position).normalized()
		var dist := position.distance_to(target_pos)
		if dist < 5.0:
			position = target_pos
			is_walking = false
			if _sprite:
				_sprite.texture = _idle_tex
		else:
			position += dir * minf(speed * delta, dist)
	# Bob animation
	if _sprite:
		var bob: float = sin(_anim_time * 6.0) * 2.0 if is_walking else 0.0
		_sprite.position.y = bob
