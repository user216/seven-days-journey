extends CanvasLayer
## Visual novel-style dialog overlay — typewriter text, portrait, tap to advance.

signal dialog_finished

# ── Config ───────────────────────────────────────────────────────

const CHAR_DELAY := 0.03  # seconds per character
const TEXT_BOX_HEIGHT := 300.0

# ── State ────────────────────────────────────────────────────────

var _lines: Array = []
var _current_line: int = 0
var _typewriter_timer: float = 0.0
var _visible_chars: int = 0
var _total_chars: int = 0
var _typing: bool = false

# ── Nodes ────────────────────────────────────────────────────────

var _dimmer: ColorRect
var _text_panel: PanelContainer
var _text_label: RichTextLabel
var _tap_hint: Label


func _ready() -> void:
	layer = 50
	_build_ui()


# ── Public API ───────────────────────────────────────────────────

func show_dialog(lines) -> void:
	## Accepts Array[String] or a single String (split by newlines).
	if lines is String:
		_lines = [lines]
	elif lines is Array:
		_lines = lines
	else:
		_lines = [str(lines)]

	_current_line = 0
	visible = true
	_start_typing()


# ── Input ────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventMouseButton and event.pressed:
		get_viewport().set_input_as_handled()
		if _typing:
			# Complete current text instantly
			_visible_chars = _total_chars
			_text_label.visible_characters = _total_chars
			_typing = false
			_tap_hint.text = "Нажмите далее..."
		else:
			# Advance to next line
			_current_line += 1
			if _current_line >= _lines.size():
				_close()
			else:
				_start_typing()


func _process(delta: float) -> void:
	if not _typing:
		return

	_typewriter_timer += delta
	while _typewriter_timer >= CHAR_DELAY and _visible_chars < _total_chars:
		_typewriter_timer -= CHAR_DELAY
		_visible_chars += 1
		_text_label.visible_characters = _visible_chars

	if _visible_chars >= _total_chars:
		_typing = false
		_tap_hint.text = "Нажмите далее..."


# ── Internal ─────────────────────────────────────────────────────

func _start_typing() -> void:
	var text: String = _lines[_current_line]
	_text_label.text = text
	_total_chars = text.length()
	_visible_chars = 0
	_text_label.visible_characters = 0
	_typewriter_timer = 0.0
	_typing = true
	_tap_hint.text = ""


func _close() -> void:
	visible = false
	dialog_finished.emit()


# ── UI Construction ──────────────────────────────────────────────

func _build_ui() -> void:
	# Dimmer
	_dimmer = ColorRect.new()
	_dimmer.anchors_preset = Control.PRESET_FULL_RECT
	_dimmer.color = Color(0, 0, 0, 0.5)
	_dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dimmer)

	# Text panel at bottom
	_text_panel = PanelContainer.new()
	_text_panel.anchors_preset = Control.PRESET_BOTTOM_WIDE
	_text_panel.offset_top = -TEXT_BOX_HEIGHT

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = ThemeManager.BG_CREAM
	panel_style.border_color = ThemeManager.SAGE_GREEN
	panel_style.border_width_top = 3
	panel_style.corner_radius_top_left = 16
	panel_style.corner_radius_top_right = 16
	panel_style.content_margin_left = 30.0
	panel_style.content_margin_right = 30.0
	panel_style.content_margin_top = 30.0
	panel_style.content_margin_bottom = 20.0
	_text_panel.add_theme_stylebox_override("panel", panel_style)

	var vbox := VBoxContainer.new()
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL

	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = false
	_text_label.fit_content = true
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text_label.add_theme_font_size_override("normal_font_size", ThemeManager.font_size(18))
	_text_label.add_theme_color_override("default_color", ThemeManager.TEXT_BROWN)
	_text_label.visible_characters = 0
	vbox.add_child(_text_label)

	_tap_hint = Label.new()
	_tap_hint.text = ""
	_tap_hint.add_theme_font_size_override("font_size", ThemeManager.font_size(14))
	_tap_hint.add_theme_color_override("font_color", ThemeManager.HINT_KHAKI)
	_tap_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(_tap_hint)

	_text_panel.add_child(vbox)
	_text_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_text_panel)

	visible = false
