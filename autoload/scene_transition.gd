extends CanvasLayer
## Smooth scene transitions — fade to black and back.

var _color_rect: ColorRect
var _tween: Tween


func _ready() -> void:
	layer = 100
	_color_rect = ColorRect.new()
	_color_rect.color = Color(0, 0, 0, 0)
	_color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_color_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_color_rect)


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
