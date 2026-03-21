class_name HopaHintSystem
extends Node
## Hint system — highlights a random unfound object with pulsing glow shader.

signal hint_used(object_id: String)
signal cooldown_finished

# ── Config ───────────────────────────────────────────────────────

var cooldown: float = 30.0
var glow_duration: float = 3.0

# ── State ────────────────────────────────────────────────────────

var _cooldown_remaining: float = 0.0
var _available: bool = true
var _active_glow_node: Node = null
var _active_glow_material: ShaderMaterial = null
var _glow_shader: Shader = null


func _ready() -> void:
	_glow_shader = load("res://shaders/hopa_object_highlight.gdshader") as Shader
	if _glow_shader == null:
		_glow_shader = load("res://shaders/ambient_glow.gdshader") as Shader


func _process(delta: float) -> void:
	if _cooldown_remaining > 0:
		_cooldown_remaining -= delta
		if _cooldown_remaining <= 0:
			_cooldown_remaining = 0.0
			_available = true
			cooldown_finished.emit()


# ── Public API ───────────────────────────────────────────────────

func is_available() -> bool:
	return _available


func get_cooldown_remaining() -> float:
	return _cooldown_remaining


func use_hint(unfound_objects: Array) -> void:
	## Highlights a random unfound object with pulsing glow.
	## unfound_objects: Array of Dictionaries with "node" (Area2D) and "id" keys.
	if not _available or unfound_objects.is_empty():
		return

	_available = false
	_cooldown_remaining = cooldown

	# Pick random unfound object
	var target: Dictionary = unfound_objects[randi() % unfound_objects.size()]
	var node: Node2D = target.get("node")
	var obj_id: String = target.get("id", "")

	if node == null:
		return

	# Find the Sprite2D child to apply shader to
	var sprite: Sprite2D = null
	for child in node.get_children():
		if child is Sprite2D:
			sprite = child
			break

	if sprite == null:
		# Fallback: apply to the node itself if it can hold material
		hint_used.emit(obj_id)
		return

	# Apply highlight shader
	_active_glow_material = ShaderMaterial.new()
	_active_glow_material.shader = _glow_shader
	_active_glow_material.set_shader_parameter("highlight_color", Color(0.83, 0.66, 0.26, 0.8))
	_active_glow_material.set_shader_parameter("pulse_speed", 4.0)
	_active_glow_material.set_shader_parameter("outline_width", 3.0)

	var original_material: Material = sprite.material
	sprite.material = _active_glow_material
	_active_glow_node = sprite

	hint_used.emit(obj_id)

	# Remove glow after duration
	var tween := create_tween()
	tween.tween_interval(glow_duration)
	tween.tween_callback(func():
		if is_instance_valid(sprite):
			sprite.material = original_material
		_active_glow_node = null
		_active_glow_material = null
	)


func cancel_glow() -> void:
	## Removes active glow immediately (e.g., when object is found).
	if _active_glow_node != null and is_instance_valid(_active_glow_node):
		_active_glow_node.material = null
		_active_glow_node = null
		_active_glow_material = null
