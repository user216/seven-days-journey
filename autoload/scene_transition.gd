extends CanvasLayer
## Scene transitions — fade to black (default) or circle iris wipe.

var _color_rect: ColorRect
var _iris_rect: ColorRect
var _iris_material: ShaderMaterial
var _tween: Tween


func _ready() -> void:
	layer = 100

	_color_rect = ColorRect.new()
	_color_rect.color = Color(0, 0, 0, 0)
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_color_rect)

	_iris_rect = ColorRect.new()
	_iris_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_iris_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_iris_rect.visible = false
	var iris_shader := load("res://shaders/iris_wipe.gdshader") as Shader
	if iris_shader:
		_iris_material = ShaderMaterial.new()
		_iris_material.shader = iris_shader
		_iris_material.set_shader_parameter("progress", 0.0)
		_iris_rect.material = _iris_material
	add_child(_iris_rect)


func change_scene(path: String, duration: float = 0.4) -> void:
	## Fade out, switch scene, fade in.
	if _tween and _tween.is_running():
		return
	_color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_tween = create_tween()
	_tween.tween_property(_color_rect, "color:a", 1.0, duration * 0.5)
	_tween.tween_callback(func():
		get_tree().change_scene_to_file(path)
	)
	_tween.tween_interval(0.05)
	_tween.tween_property(_color_rect, "color:a", 0.0, duration * 0.5)
	_tween.tween_callback(func():
		_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	)


func change_scene_iris(path: String, duration: float = 0.8) -> void:
	## Circle iris close, switch scene, circle iris open.
	if _tween and _tween.is_running():
		return
	if not _iris_material:
		change_scene(path, duration)
		return
	_iris_rect.visible = true
	_iris_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_iris_material.set_shader_parameter("progress", 0.0)
	_tween = create_tween()
	_tween.tween_method(func(v: float): _iris_material.set_shader_parameter("progress", v),
		0.0, 1.0, duration * 0.45).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	_tween.tween_callback(func():
		get_tree().change_scene_to_file(path)
	)
	_tween.tween_interval(0.08)
	_tween.tween_method(func(v: float): _iris_material.set_shader_parameter("progress", v),
		1.0, 0.0, duration * 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_tween.tween_callback(func():
		_iris_rect.visible = false
		_iris_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	)


func reload_scene(duration: float = 0.4) -> void:
	if _tween and _tween.is_running():
		return
	_color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_tween = create_tween()
	_tween.tween_property(_color_rect, "color:a", 1.0, duration * 0.5)
	_tween.tween_callback(func():
		get_tree().reload_current_scene()
	)
	_tween.tween_interval(0.05)
	_tween.tween_property(_color_rect, "color:a", 0.0, duration * 0.5)
	_tween.tween_callback(func():
		_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	)
