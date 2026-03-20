extends Node2D
## Side-scroll hero — SVG sprite-based character with walk animation.

signal hero_reached_station(station_index: int)

var target_x: float = 0.0
var speed: float = 350.0
var is_walking: bool = false
var facing_right: bool = true

@onready var _sprite: AnimatedSprite2D = $AnimatedSprite2D


func _ready() -> void:
	var dress_color := ThemeManager.get_dress_color(GameState.current_day)
	_sprite.self_modulate = dress_color
	_sprite.play("idle")


func _process(delta: float) -> void:
	if is_walking:
		var dir := signf(target_x - position.x)
		facing_right = dir >= 0
		_sprite.flip_h = not facing_right
		position.x += dir * speed * delta
		if absf(position.x - target_x) < 5.0:
			position.x = target_x
			is_walking = false
			_sprite.play("idle")


func walk_to(x: float) -> void:
	target_x = x
	is_walking = true
	_sprite.play("walk")
