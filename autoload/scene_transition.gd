extends CanvasLayer
## Scene transitions — fade, iris wipe, diamond wipe, dissolve, pattern dissolve,
## shockwave, screen flash. Includes lifecycle signals and scene history.

signal transition_started
signal scene_swapped
signal transition_finished

var _color_rect: ColorRect
var _iris_rect: ColorRect
var _iris_material: ShaderMaterial
var _diamond_rect: ColorRect
var _diamond_material: ShaderMaterial
var _dissolve_rect: ColorRect
var _dissolve_material: ShaderMaterial
var _pattern_rect: ColorRect
var _pattern_material: ShaderMaterial
var _shockwave_rect: ColorRect
var _shockwave_material: ShaderMaterial
var _flash_rect: ColorRect
var _flash_material: ShaderMaterial
var _tween: Tween

# Scene history for back navigation
var _history: Array[String] = []
const MAX_HISTORY := 5


func _ready() -> void:
	CrashLogger.breadcrumb("SceneTransition._ready")
	layer = 100

	_color_rect = ColorRect.new()
	_color_rect.color = Color(0, 0, 0, 0)
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_color_rect)

	_iris_rect = _create_shader_rect("res://shaders/iris_wipe.gdshader")
	_iris_material = _iris_rect.material as ShaderMaterial
	add_child(_iris_rect)

	_diamond_rect = _create_shader_rect("res://shaders/diamond_wipe.gdshader")
	_diamond_material = _diamond_rect.material as ShaderMaterial
	add_child(_diamond_rect)

	_dissolve_rect = _create_shader_rect("res://shaders/dissolve.gdshader")
	_dissolve_material = _dissolve_rect.material as ShaderMaterial
	add_child(_dissolve_rect)

	# Pattern dissolve (universal)
	_pattern_rect = _create_shader_rect("res://shaders/pattern_dissolve.gdshader")
	_pattern_material = _pattern_rect.material as ShaderMaterial
	add_child(_pattern_rect)

	# Shockwave post-process overlay — deferred loading
	# The shockwave shader uses hint_screen_texture which crashes Mali-G57
	# when loaded before rendering is stable. Load lazily on first use.
	_shockwave_rect = ColorRect.new()
	_shockwave_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shockwave_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_shockwave_rect.visible = false
	add_child(_shockwave_rect)
	# _shockwave_material is created lazily in shockwave()

	_flash_rect = ColorRect.new()
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.visible = false
	var flash_shader := load("res://shaders/screen_flash.gdshader") as Shader
	if flash_shader:
		_flash_material = ShaderMaterial.new()
		_flash_material.shader = flash_shader
		_flash_material.set_shader_parameter("alpha", 0.0)
		_flash_rect.material = _flash_material
	add_child(_flash_rect)


func _create_shader_rect(shader_path: String) -> ColorRect:
	var rect := ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	rect.visible = false
	var shader := load(shader_path) as Shader
	if shader:
		var mat := ShaderMaterial.new()
		mat.shader = shader
		mat.set_shader_parameter("progress", 0.0)
		rect.material = mat
	return rect


func _push_history() -> void:
	var current := get_tree().current_scene.scene_file_path if get_tree().current_scene else ""
	if current.is_empty():
		return
	_history.push_back(current)
	if _history.size() > MAX_HISTORY:
		_history.pop_front()


func has_history() -> bool:
	return _history.size() > 0


func go_back(duration: float = 0.4) -> void:
	if _history.is_empty():
		return
	var prev: String = _history.pop_back()
	# Don't push current scene to history when going back
	_do_change_scene(prev, duration, false)


func change_scene(path: String, duration: float = 0.4) -> void:
	if _tween and _tween.is_running():
		return
	_push_history()
	transition_started.emit()
	_color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_tween = create_tween()
	_tween.tween_property(_color_rect, "color:a", 1.0, duration * 0.5)
	_tween.tween_callback(func():
		get_tree().change_scene_to_file(path)
		scene_swapped.emit()
	)
	_tween.tween_interval(0.05)
	_tween.tween_property(_color_rect, "color:a", 0.0, duration * 0.5)
	_tween.tween_callback(func():
		_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		transition_finished.emit()
	)


func change_scene_iris(path: String, duration: float = 0.8) -> void:
	if not _iris_material:
		change_scene(path, duration)
		return
	_push_history()
	_wipe_transition(_iris_rect, _iris_material, path, duration)


func change_scene_diamond(path: String, duration: float = 0.8) -> void:
	if not _diamond_material:
		change_scene(path, duration)
		return
	_push_history()
	_wipe_transition(_diamond_rect, _diamond_material, path, duration)


func change_scene_dissolve(path: String, duration: float = 0.8) -> void:
	if not _dissolve_material:
		change_scene(path, duration)
		return
	_push_history()
	_wipe_transition(_dissolve_rect, _dissolve_material, path, duration)


func change_scene_pattern(path: String, duration: float = 0.8, inverted: bool = false) -> void:
	if not _pattern_material:
		change_scene(path, duration)
		return
	_pattern_material.set_shader_parameter("inverted", inverted)
	_push_history()
	_wipe_transition(_pattern_rect, _pattern_material, path, duration)


func _do_change_scene(path: String, duration: float, push_hist: bool) -> void:
	if _tween and _tween.is_running():
		return
	if push_hist:
		_push_history()
	transition_started.emit()
	_color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_tween = create_tween()
	_tween.tween_property(_color_rect, "color:a", 1.0, duration * 0.5)
	_tween.tween_callback(func():
		get_tree().change_scene_to_file(path)
		scene_swapped.emit()
	)
	_tween.tween_interval(0.05)
	_tween.tween_property(_color_rect, "color:a", 0.0, duration * 0.5)
	_tween.tween_callback(func():
		_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		transition_finished.emit()
	)


func _wipe_transition(rect: ColorRect, mat: ShaderMaterial, path: String, duration: float) -> void:
	if _tween and _tween.is_running():
		return
	transition_started.emit()
	rect.visible = true
	rect.mouse_filter = Control.MOUSE_FILTER_STOP
	mat.set_shader_parameter("progress", 0.0)
	_tween = create_tween()
	_tween.tween_method(func(v: float): mat.set_shader_parameter("progress", v),
		0.0, 1.0, duration * 0.45).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	_tween.tween_callback(func():
		get_tree().change_scene_to_file(path)
		scene_swapped.emit()
	)
	_tween.tween_interval(0.08)
	_tween.tween_method(func(v: float): mat.set_shader_parameter("progress", v),
		1.0, 0.0, duration * 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	_tween.tween_callback(func():
		rect.visible = false
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		transition_finished.emit()
	)


func reload_scene(duration: float = 0.4) -> void:
	if _tween and _tween.is_running():
		return
	transition_started.emit()
	_color_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	_tween = create_tween()
	_tween.tween_property(_color_rect, "color:a", 1.0, duration * 0.5)
	_tween.tween_callback(func():
		get_tree().reload_current_scene()
		scene_swapped.emit()
	)
	_tween.tween_interval(0.05)
	_tween.tween_property(_color_rect, "color:a", 0.0, duration * 0.5)
	_tween.tween_callback(func():
		_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		transition_finished.emit()
	)


func shockwave(center: Vector2, duration: float = 0.6) -> void:
	# Lazy-load shockwave shader on first use (hint_screen_texture crashes Mali on early load)
	if not _shockwave_material:
		var sw_shader := load("res://shaders/shockwave.gdshader") as Shader
		if not sw_shader:
			return
		_shockwave_material = ShaderMaterial.new()
		_shockwave_material.shader = sw_shader
		_shockwave_material.set_shader_parameter("size", 0.0)
		_shockwave_rect.material = _shockwave_material
	_shockwave_rect.visible = true
	_shockwave_material.set_shader_parameter("center", center)
	_shockwave_material.set_shader_parameter("size", 0.0)
	var tw := create_tween()
	tw.tween_method(func(v: float): _shockwave_material.set_shader_parameter("size", v),
		0.0, 1.2, duration).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	tw.tween_callback(func(): _shockwave_rect.visible = false)


func flash_screen(color: Color, duration: float = 0.3) -> void:
	if not _flash_material:
		return
	_flash_rect.visible = true
	_flash_material.set_shader_parameter("flash_color", color)
	_flash_material.set_shader_parameter("alpha", 0.6)
	var tw := create_tween()
	tw.tween_method(func(v: float): _flash_material.set_shader_parameter("alpha", v),
		0.6, 0.0, duration).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): _flash_rect.visible = false)
