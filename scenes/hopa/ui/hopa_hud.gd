extends CanvasLayer
## HOPA HUD — timer, found counter, object list, hint button, inventory bar.
## Built entirely in code (no separate .tscn).

signal hint_requested
signal pause_requested

# ── State ────────────────────────────────────────────────────────

var _object_labels: Dictionary = {}  # {object_id: Label}
var _inventory_icons: Array[TextureRect] = []

# ── Nodes ────────────────────────────────────────────────────────

var _timer_label: Label
var _found_label: Label
var _day_label: Label
var _hint_btn: Button
var _hint_cooldown_label: Label
var _pause_btn: Button
var _object_list_container: VBoxContainer
var _inventory_bar: HBoxContainer
var _top_panel: PanelContainer
var _bottom_panel: PanelContainer


func _ready() -> void:
	layer = 10
	_build_ui()


# ── Public API ───────────────────────────────────────────────────

func setup(day: int, object_names: Array) -> void:
	_day_label.text = "День %d" % day
	_found_label.text = "0/%d" % object_names.size()
	for obj in object_names:
		var id: String = obj.get("id", "")
		var name: String = obj.get("name", "")
		var lbl := Label.new()
		lbl.text = name
		lbl.add_theme_font_size_override("font_size", ThemeManager.font_size(16))
		lbl.add_theme_color_override("font_color", ThemeManager.BG_CREAM)
		_object_list_container.add_child(lbl)
		_object_labels[id] = lbl


func update_timer(seconds_left: float) -> void:
	var mins := int(seconds_left) / 60
	var secs := int(seconds_left) % 60
	_timer_label.text = "%d:%02d" % [mins, secs]
	if seconds_left < 30.0:
		_timer_label.add_theme_color_override("font_color", ThemeManager.WARM_DANGER)
	else:
		_timer_label.add_theme_color_override("font_color", ThemeManager.BG_CREAM)


func update_found_count(found: int, total: int) -> void:
	_found_label.text = "%d/%d" % [found, total]


func mark_object_found(object_id: String) -> void:
	if object_id in _object_labels:
		var lbl: Label = _object_labels[object_id]
		lbl.add_theme_color_override("font_color", ThemeManager.SAGE_GREEN)
		lbl.text = "[%s]" % lbl.text  # Visual strikethrough substitute


func add_inventory_item(object_id: String, tex: Texture2D) -> void:
	_inventory_bar.visible = true
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(48, 48)
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.texture = tex
	if tex == null:
		# Placeholder: small colored rect
		icon.texture = PlaceholderFactory.make_soft_circle(24, ThemeManager.GOLDEN_AMBER)
	_inventory_bar.add_child(icon)
	_inventory_icons.append(icon)


func set_hint_cooldown(remaining: float) -> void:
	if remaining > 0:
		_hint_btn.disabled = true
		_hint_cooldown_label.text = "%ds" % ceili(remaining)
		_hint_cooldown_label.visible = true
	else:
		_hint_btn.disabled = false
		_hint_cooldown_label.visible = false


func get_object_found_position(object_id: String) -> Vector2:
	## Returns global position of the found-list label for tween target.
	if object_id in _object_labels:
		return _object_labels[object_id].global_position + Vector2(40, 10)
	return Vector2(980, 400)


# ── UI Construction ──────────────────────────────────────────────

func _build_ui() -> void:
	# ── Top bar ──────────────────────────────────────────────
	_top_panel = PanelContainer.new()
	_top_panel.anchors_preset = Control.PRESET_TOP_WIDE
	_top_panel.offset_bottom = 80.0

	var top_bg := StyleBoxFlat.new()
	top_bg.bg_color = Color(0, 0, 0, 0.3)
	top_bg.content_margin_left = 20.0
	top_bg.content_margin_right = 20.0
	top_bg.content_margin_top = 10.0
	top_bg.content_margin_bottom = 10.0
	_top_panel.add_theme_stylebox_override("panel", top_bg)

	var top_hbox := HBoxContainer.new()
	top_hbox.alignment = BoxContainer.ALIGNMENT_CENTER

	_timer_label = Label.new()
	_timer_label.text = "3:00"
	_timer_label.add_theme_font_size_override("font_size", ThemeManager.font_size(24))
	_timer_label.add_theme_color_override("font_color", ThemeManager.BG_CREAM)
	_timer_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(_timer_label)

	_found_label = Label.new()
	_found_label.text = "0/0"
	_found_label.add_theme_font_size_override("font_size", ThemeManager.font_size(22))
	_found_label.add_theme_color_override("font_color", ThemeManager.LIGHT_GOLD)
	_found_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_found_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	top_hbox.add_child(_found_label)

	_day_label = Label.new()
	_day_label.text = "День 1"
	_day_label.add_theme_font_size_override("font_size", ThemeManager.font_size(18))
	_day_label.add_theme_color_override("font_color", ThemeManager.HINT_KHAKI)
	_day_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_day_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(_day_label)

	_top_panel.add_child(top_hbox)
	add_child(_top_panel)

	# ── Right side: object list ──────────────────────────────
	var list_panel := PanelContainer.new()
	list_panel.anchor_left = 0.78
	list_panel.anchor_right = 1.0
	list_panel.anchor_top = 0.06
	list_panel.anchor_bottom = 0.55
	list_panel.offset_left = 0.0
	list_panel.offset_right = -10.0
	list_panel.offset_top = 10.0

	var list_bg := StyleBoxFlat.new()
	list_bg.bg_color = Color(0, 0, 0, 0.25)
	list_bg.corner_radius_top_left = 12
	list_bg.corner_radius_bottom_left = 12
	list_bg.corner_radius_top_right = 12
	list_bg.corner_radius_bottom_right = 12
	list_bg.content_margin_left = 12.0
	list_bg.content_margin_right = 12.0
	list_bg.content_margin_top = 8.0
	list_bg.content_margin_bottom = 8.0
	list_panel.add_theme_stylebox_override("panel", list_bg)

	var scroll := ScrollContainer.new()
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL

	_object_list_container = VBoxContainer.new()
	_object_list_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_object_list_container)
	list_panel.add_child(scroll)
	add_child(list_panel)

	# ── Bottom bar ───────────────────────────────────────────
	_bottom_panel = PanelContainer.new()
	_bottom_panel.anchors_preset = Control.PRESET_BOTTOM_WIDE
	_bottom_panel.offset_top = -100.0

	var bottom_bg := StyleBoxFlat.new()
	bottom_bg.bg_color = Color(0, 0, 0, 0.3)
	bottom_bg.content_margin_left = 20.0
	bottom_bg.content_margin_right = 20.0
	bottom_bg.content_margin_top = 10.0
	bottom_bg.content_margin_bottom = 20.0
	_bottom_panel.add_theme_stylebox_override("panel", bottom_bg)

	var bottom_hbox := HBoxContainer.new()
	bottom_hbox.alignment = BoxContainer.ALIGNMENT_CENTER

	_hint_btn = Button.new()
	_hint_btn.text = "Подсказка"
	_hint_btn.custom_minimum_size = Vector2(200, 80)
	_hint_btn.add_theme_font_size_override("font_size", ThemeManager.font_size(18))
	ThemeManager.style_button(_hint_btn, ThemeManager.GOLDEN_AMBER, 12)
	_hint_btn.pressed.connect(func(): hint_requested.emit())
	bottom_hbox.add_child(_hint_btn)

	_hint_cooldown_label = Label.new()
	_hint_cooldown_label.text = ""
	_hint_cooldown_label.visible = false
	_hint_cooldown_label.add_theme_font_size_override("font_size", ThemeManager.font_size(16))
	_hint_cooldown_label.add_theme_color_override("font_color", ThemeManager.HINT_KHAKI)
	bottom_hbox.add_child(_hint_cooldown_label)

	# Spacer
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_hbox.add_child(spacer)

	# Inventory bar
	_inventory_bar = HBoxContainer.new()
	_inventory_bar.visible = false
	_inventory_bar.add_theme_constant_override("separation", 8)
	bottom_hbox.add_child(_inventory_bar)

	# Spacer
	var spacer2 := Control.new()
	spacer2.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bottom_hbox.add_child(spacer2)

	_pause_btn = Button.new()
	_pause_btn.text = "||"
	_pause_btn.custom_minimum_size = Vector2(80, 80)
	_pause_btn.add_theme_font_size_override("font_size", ThemeManager.font_size(20))
	ThemeManager.style_button(_pause_btn, ThemeManager.EARTHY_BROWN, 12)
	_pause_btn.pressed.connect(func(): pause_requested.emit())
	bottom_hbox.add_child(_pause_btn)

	_bottom_panel.add_child(bottom_hbox)
	add_child(_bottom_panel)
