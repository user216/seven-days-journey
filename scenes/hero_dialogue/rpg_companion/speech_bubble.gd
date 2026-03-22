extends Control
## Speech bubble for RPG companion hero — rounded rect with tail, typewriter text.

signal bubble_finished
signal bubble_tapped

const CHAR_DELAY := 0.025
const BUBBLE_PADDING := Vector2(20, 14)
const TAIL_SIZE := 12.0
const CORNER_RADIUS := 14.0
const MAX_WIDTH := 500.0

var _text: String = ""
var _typing: bool = false
var _visible_chars: int = 0
var _total_chars: int = 0
var _typewriter_timer: float = 0.0
var _label: Label
var _auto_hide_timer: float = 0.0


func _ready() -> void:
	mouse_filter = MOUSE_FILTER_STOP
	_label = Label.new()
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_label.custom_minimum_size = Vector2(100, 0)
	_label.add_theme_font_size_override("font_size", ThemeManager.font_size(15))
	_label.add_theme_color_override("font_color", ThemeManager.TEXT_BROWN)
	_label.position = BUBBLE_PADDING
	add_child(_label)
	visible = false


func show_text(text: String, auto_hide_sec: float = 0.0) -> void:
	_text = text
	_label.text = text
	# Compute size
	var font: Font = _label.get_theme_font("font")
	var font_size: int = _label.get_theme_font_size("font_size")
	var text_size := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, MAX_WIDTH - BUBBLE_PADDING.x * 2, font_size)
	_label.custom_minimum_size.x = minf(text_size.x, MAX_WIDTH - BUBBLE_PADDING.x * 2)
	custom_minimum_size = Vector2(
		text_size.x + BUBBLE_PADDING.x * 2,
		text_size.y + BUBBLE_PADDING.y * 2 + TAIL_SIZE
	)
	size = custom_minimum_size

	_total_chars = text.length()
	_visible_chars = 0
	_label.visible_characters = 0
	_typing = true
	_typewriter_timer = 0.0
	_auto_hide_timer = auto_hide_sec
	visible = true
	queue_redraw()


func hide_bubble() -> void:
	visible = false
	bubble_finished.emit()


func _process(delta: float) -> void:
	if _typing:
		_typewriter_timer += delta
		while _typewriter_timer >= CHAR_DELAY and _visible_chars < _total_chars:
			_typewriter_timer -= CHAR_DELAY
			_visible_chars += 1
			_label.visible_characters = _visible_chars
		if _visible_chars >= _total_chars:
			_typing = false

	if _auto_hide_timer > 0.0 and not _typing:
		_auto_hide_timer -= delta
		if _auto_hide_timer <= 0.0:
			hide_bubble()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		accept_event()
		if _typing:
			_visible_chars = _total_chars
			_label.visible_characters = _total_chars
			_typing = false
		else:
			bubble_tapped.emit()
			hide_bubble()


func _draw() -> void:
	if not visible:
		return
	# Bubble body
	var rect := Rect2(Vector2.ZERO, Vector2(size.x, size.y - TAIL_SIZE))
	var style := StyleBoxFlat.new()
	style.bg_color = Color.WHITE
	style.corner_radius_top_left = int(CORNER_RADIUS)
	style.corner_radius_top_right = int(CORNER_RADIUS)
	style.corner_radius_bottom_left = int(CORNER_RADIUS)
	style.corner_radius_bottom_right = int(CORNER_RADIUS)
	style.border_color = ThemeManager.SAGE_GREEN
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.draw(get_canvas_item(), rect)

	# Tail triangle pointing down-center
	var tail_center := size.x * 0.5
	var points := PackedVector2Array([
		Vector2(tail_center - TAIL_SIZE, size.y - TAIL_SIZE),
		Vector2(tail_center, size.y),
		Vector2(tail_center + TAIL_SIZE, size.y - TAIL_SIZE),
	])
	draw_colored_polygon(points, Color.WHITE)
	# Tail border
	draw_polyline(points, ThemeManager.SAGE_GREEN, 2.0)
