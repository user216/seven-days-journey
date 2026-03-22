extends CanvasLayer
## Branching dialogue system — extends story_dialog pattern with portraits, speaker names,
## and choice buttons. Supports linear "say" nodes, "choice" branching, and "action" triggers.

signal dialog_finished
signal choice_made(choice_key: String)
signal action_requested(action_id: String)

# ── Config ───────────────────────────────────────────────────────

const CHAR_DELAY := 0.03
const TEXT_BOX_HEIGHT := 340.0
const PORTRAIT_SIZE := 160.0
const CHOICE_BTN_HEIGHT := 60.0

# ── State ────────────────────────────────────────────────────────

var _nodes: Array = []  # current dialogue tree nodes
var _node_idx: int = 0
var _typewriter_timer: float = 0.0
var _visible_chars: int = 0
var _total_chars: int = 0
var _typing: bool = false
var _waiting_choice: bool = false
var _dialogue_key: String = ""

# ── UI Nodes ─────────────────────────────────────────────────────

var _dimmer: ColorRect
var _text_panel: PanelContainer
var _speaker_label: Label
var _text_label: RichTextLabel
var _tap_hint: Label
var _choice_container: VBoxContainer
var _portrait_rect: TextureRect
var _portrait_container: PanelContainer


func _ready() -> void:
	layer = 50
	_build_ui()


# ── Public API ───────────────────────────────────────────────────

func show_dialogue(key: String, nodes: Array) -> void:
	## Start a dialogue tree. nodes is Array[Dictionary] with type/speaker/text/options.
	_dialogue_key = key
	_nodes = nodes
	_node_idx = 0
	_waiting_choice = false
	visible = true
	_clear_choices()
	_process_current_node()


func set_portrait_visible(show: bool) -> void:
	_portrait_container.visible = show


func set_portrait_texture(tex: Texture2D) -> void:
	_portrait_rect.texture = tex


# ── Input ────────────────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if _waiting_choice:
		return  # choices handle their own input
	if event is InputEventMouseButton and event.pressed:
		get_viewport().set_input_as_handled()
		if _typing:
			_visible_chars = _total_chars
			_text_label.visible_characters = _total_chars
			_typing = false
			_tap_hint.text = "Нажмите далее..."
		else:
			_advance()


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
		if not _waiting_choice:
			_tap_hint.text = "Нажмите далее..."


# ── Node Processing ──────────────────────────────────────────────

func _process_current_node() -> void:
	if _node_idx >= _nodes.size():
		_close()
		return

	var node: Dictionary = _nodes[_node_idx]
	var node_type: String = node.get("type", "say")

	match node_type:
		"say":
			_show_say(node)
		"choice":
			_show_choices(node)
		"action":
			var action_id: String = node.get("action", "")
			action_requested.emit(action_id)
			_advance()


func _show_say(node: Dictionary) -> void:
	_clear_choices()
	_waiting_choice = false

	var speaker: String = node.get("speaker", "hero")
	if speaker == "hero":
		_speaker_label.text = "Леонардо"
		_speaker_label.add_theme_color_override("font_color", ThemeManager.SAGE_GREEN)
	else:
		_speaker_label.text = "Вы"
		_speaker_label.add_theme_color_override("font_color", ThemeManager.GOLDEN_AMBER)
	_speaker_label.visible = true

	var text: String = node.get("text", "")
	_text_label.text = text
	_total_chars = text.length()
	_visible_chars = 0
	_text_label.visible_characters = 0
	_typewriter_timer = 0.0
	_typing = true
	_tap_hint.text = ""


func _show_choices(node: Dictionary) -> void:
	_clear_choices()
	_waiting_choice = true
	_tap_hint.text = ""

	# Show a prompt if provided
	var prompt: String = node.get("prompt", "")
	if prompt.length() > 0:
		_speaker_label.text = "Вы"
		_speaker_label.add_theme_color_override("font_color", ThemeManager.GOLDEN_AMBER)
		_text_label.text = prompt
		_text_label.visible_characters = -1
		_typing = false
	else:
		_text_label.text = ""

	var options: Array = node.get("options", [])
	for i in range(options.size()):
		var opt: Dictionary = options[i]
		var btn := Button.new()
		btn.text = opt.get("text", "...")
		btn.custom_minimum_size = Vector2(0, CHOICE_BTN_HEIGHT)
		btn.add_theme_font_size_override("font_size", ThemeManager.font_size(16))

		var style := StyleBoxFlat.new()
		style.bg_color = ThemeManager.SAGE_GREEN.darkened(0.05)
		style.bg_color.a = 0.9
		style.corner_radius_top_left = 12
		style.corner_radius_top_right = 12
		style.corner_radius_bottom_left = 12
		style.corner_radius_bottom_right = 12
		style.content_margin_left = 16.0
		style.content_margin_right = 16.0
		style.content_margin_top = 8.0
		style.content_margin_bottom = 8.0
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_color_override("font_color", Color.WHITE)

		var hover_style := style.duplicate() as StyleBoxFlat
		hover_style.bg_color = ThemeManager.SAGE_GREEN
		btn.add_theme_stylebox_override("hover", hover_style)

		var opt_copy := opt  # capture for lambda
		btn.pressed.connect(func():
			_on_choice_selected(opt_copy)
		)
		ThemeManager.apply_button_juice(btn)
		_choice_container.add_child(btn)

	_choice_container.visible = true


func _on_choice_selected(opt: Dictionary) -> void:
	_waiting_choice = false
	_clear_choices()

	var next_key: String = opt.get("next", "")
	choice_made.emit(next_key)

	if next_key.length() > 0 and next_key != _dialogue_key:
		# Branch to a different dialogue tree — caller handles this
		# by connecting to choice_made and calling show_dialogue again
		_close()
	else:
		_advance()


func _advance() -> void:
	_node_idx += 1
	_process_current_node()


func _close() -> void:
	visible = false
	_clear_choices()
	dialog_finished.emit()


func _clear_choices() -> void:
	for child in _choice_container.get_children():
		child.queue_free()
	_choice_container.visible = false


# ── UI Construction ──────────────────────────────────────────────

func _build_ui() -> void:
	# Dimmer
	_dimmer = ColorRect.new()
	_dimmer.anchors_preset = Control.PRESET_FULL_RECT
	_dimmer.color = Color(0, 0, 0, 0.5)
	_dimmer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dimmer)

	# Portrait container on left
	_portrait_container = PanelContainer.new()
	_portrait_container.position = Vector2(20, -TEXT_BOX_HEIGHT - PORTRAIT_SIZE - 20)
	_portrait_container.anchors_preset = Control.PRESET_BOTTOM_LEFT
	_portrait_container.custom_minimum_size = Vector2(PORTRAIT_SIZE, PORTRAIT_SIZE)

	var portrait_style := StyleBoxFlat.new()
	portrait_style.bg_color = ThemeManager.BG_CREAM.darkened(0.05)
	portrait_style.corner_radius_top_left = 16
	portrait_style.corner_radius_top_right = 16
	portrait_style.corner_radius_bottom_left = 16
	portrait_style.corner_radius_bottom_right = 16
	portrait_style.border_color = ThemeManager.SAGE_GREEN
	portrait_style.border_width_bottom = 2
	portrait_style.border_width_left = 2
	portrait_style.border_width_right = 2
	portrait_style.border_width_top = 2
	portrait_style.content_margin_left = 8.0
	portrait_style.content_margin_right = 8.0
	portrait_style.content_margin_top = 8.0
	portrait_style.content_margin_bottom = 8.0
	_portrait_container.add_theme_stylebox_override("panel", portrait_style)

	_portrait_rect = TextureRect.new()
	_portrait_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	_portrait_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait_container.add_child(_portrait_rect)
	_portrait_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_portrait_container)

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
	panel_style.content_margin_top = 20.0
	panel_style.content_margin_bottom = 16.0
	_text_panel.add_theme_stylebox_override("panel", panel_style)

	var vbox := VBoxContainer.new()
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 6)

	# Speaker name
	_speaker_label = Label.new()
	_speaker_label.text = ""
	_speaker_label.add_theme_font_size_override("font_size", ThemeManager.font_size(14))
	_speaker_label.add_theme_color_override("font_color", ThemeManager.SAGE_GREEN)
	_speaker_label.visible = false
	vbox.add_child(_speaker_label)

	# Main text
	_text_label = RichTextLabel.new()
	_text_label.bbcode_enabled = false
	_text_label.fit_content = true
	_text_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_text_label.add_theme_font_size_override("normal_font_size", ThemeManager.font_size(17))
	_text_label.add_theme_color_override("default_color", ThemeManager.TEXT_BROWN)
	_text_label.visible_characters = 0
	vbox.add_child(_text_label)

	# Choice buttons container
	_choice_container = VBoxContainer.new()
	_choice_container.add_theme_constant_override("separation", 8)
	_choice_container.visible = false
	vbox.add_child(_choice_container)

	# Tap hint
	_tap_hint = Label.new()
	_tap_hint.text = ""
	_tap_hint.add_theme_font_size_override("font_size", ThemeManager.font_size(13))
	_tap_hint.add_theme_color_override("font_color", ThemeManager.HINT_KHAKI)
	_tap_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vbox.add_child(_tap_hint)

	_text_panel.add_child(vbox)
	_text_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_text_panel)

	visible = false
