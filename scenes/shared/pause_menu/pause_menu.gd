extends Node
## Pause menu — save, navigation, settings, about, hidden dev mode toggle.

signal resume_pressed
signal main_menu_pressed

@onready var pause_layer: CanvasLayer = $".."
@onready var title_label: Label = $"../ScrollContainer/CenterContainer/VBox/TitleLabel"
@onready var resume_btn: Button = $"../ScrollContainer/CenterContainer/VBox/ResumeBtn"
@onready var save_btn: Button = $"../ScrollContainer/CenterContainer/VBox/SaveBtn"
@onready var main_menu_btn: Button = $"../ScrollContainer/CenterContainer/VBox/MainMenuBtn"

var _title_tap_count: int = 0
var _title_tap_timer: float = 0.0
var _dev_btn: Button = null
var _scale_value_label: Label = null
var _scale_idx: int = 1
var _about_panel: VBoxContainer = null
var _about_btn: Button = null
var _skin_label: Label = null
var _hair_label: Label = null
var _style_label: Label = null
var _sfx_btn: Button = null
var _haptic_btn: Button = null
var _volume_label: Label = null

const SCALE_STEPS: Array[float] = [0.8, 1.0, 1.2, 1.5]


func _ready() -> void:
	resume_btn.pressed.connect(_on_resume)
	save_btn.pressed.connect(_on_save)
	main_menu_btn.pressed.connect(_on_main_menu)
	title_label.gui_input.connect(_on_title_input)

	# Settings section
	var sep := HSeparator.new()
	$"../ScrollContainer/CenterContainer/VBox".add_child(sep)

	var settings_header := Label.new()
	settings_header.text = "⚙ Настройки"
	settings_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_header.add_theme_font_size_override("font_size", ThemeManager.font_size(24))
	$"../ScrollContainer/CenterContainer/VBox".add_child(settings_header)

	# Text size settings row
	_scale_idx = _find_closest_scale_idx(GameState.ui_scale)
	var scale_row := HBoxContainer.new()
	scale_row.alignment = BoxContainer.ALIGNMENT_CENTER
	scale_row.custom_minimum_size = Vector2(0, 60)

	var size_label := Label.new()
	size_label.text = "Текст: "
	scale_row.add_child(size_label)

	var minus_btn := Button.new()
	minus_btn.text = " − "
	minus_btn.custom_minimum_size = Vector2(80, 80)
	minus_btn.pressed.connect(_on_scale_minus)
	scale_row.add_child(minus_btn)

	_scale_value_label = Label.new()
	_scale_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_scale_value_label.custom_minimum_size = Vector2(100, 0)
	_update_scale_label()
	scale_row.add_child(_scale_value_label)

	var plus_btn := Button.new()
	plus_btn.text = " + "
	plus_btn.custom_minimum_size = Vector2(80, 80)
	plus_btn.pressed.connect(_on_scale_plus)
	scale_row.add_child(plus_btn)

	$"../ScrollContainer/CenterContainer/VBox".add_child(scale_row)

	# Volume slider row
	var vol_row := HBoxContainer.new()
	vol_row.alignment = BoxContainer.ALIGNMENT_CENTER
	vol_row.custom_minimum_size = Vector2(0, 60)
	var vol_lbl := Label.new()
	vol_lbl.text = "Громкость: "
	vol_row.add_child(vol_lbl)
	var vol_minus := Button.new()
	vol_minus.text = " − "
	vol_minus.custom_minimum_size = Vector2(80, 80)
	vol_minus.pressed.connect(_on_vol_minus)
	vol_row.add_child(vol_minus)
	_volume_label = Label.new()
	_volume_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_volume_label.custom_minimum_size = Vector2(100, 0)
	_update_volume_label()
	vol_row.add_child(_volume_label)
	var vol_plus := Button.new()
	vol_plus.text = " + "
	vol_plus.custom_minimum_size = Vector2(80, 80)
	vol_plus.pressed.connect(_on_vol_plus)
	vol_row.add_child(vol_plus)
	$"../ScrollContainer/CenterContainer/VBox".add_child(vol_row)

	# SFX toggle
	_sfx_btn = Button.new()
	_sfx_btn.custom_minimum_size = Vector2(0, 60)
	_sfx_btn.pressed.connect(_on_sfx_toggle)
	_update_sfx_btn()
	$"../ScrollContainer/CenterContainer/VBox".add_child(_sfx_btn)

	# Haptic toggle
	_haptic_btn = Button.new()
	_haptic_btn.custom_minimum_size = Vector2(0, 60)
	_haptic_btn.pressed.connect(_on_haptic_toggle)
	_update_haptic_btn()
	$"../ScrollContainer/CenterContainer/VBox".add_child(_haptic_btn)

	# Skin color row
	var skin_row := HBoxContainer.new()
	skin_row.alignment = BoxContainer.ALIGNMENT_CENTER
	skin_row.custom_minimum_size = Vector2(0, 80)

	var skin_lbl := Label.new()
	skin_lbl.text = "Кожа: "
	skin_row.add_child(skin_lbl)

	var skin_prev := Button.new()
	skin_prev.text = " < "
	skin_prev.custom_minimum_size = Vector2(80, 80)
	skin_prev.pressed.connect(_on_skin_prev)
	skin_row.add_child(skin_prev)

	_skin_label = Label.new()
	_skin_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_skin_label.custom_minimum_size = Vector2(120, 0)
	skin_row.add_child(_skin_label)

	var skin_next := Button.new()
	skin_next.text = " > "
	skin_next.custom_minimum_size = Vector2(80, 80)
	skin_next.pressed.connect(_on_skin_next)
	skin_row.add_child(skin_next)

	$"../ScrollContainer/CenterContainer/VBox".add_child(skin_row)
	_update_skin_label()

	# Hair color row
	var hair_row := HBoxContainer.new()
	hair_row.alignment = BoxContainer.ALIGNMENT_CENTER
	hair_row.custom_minimum_size = Vector2(0, 80)

	var hair_lbl := Label.new()
	hair_lbl.text = "Волосы: "
	hair_row.add_child(hair_lbl)

	var hair_prev := Button.new()
	hair_prev.text = " < "
	hair_prev.custom_minimum_size = Vector2(80, 80)
	hair_prev.pressed.connect(_on_hair_prev)
	hair_row.add_child(hair_prev)

	_hair_label = Label.new()
	_hair_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_hair_label.custom_minimum_size = Vector2(120, 0)
	hair_row.add_child(_hair_label)

	var hair_next := Button.new()
	hair_next.text = " > "
	hair_next.custom_minimum_size = Vector2(80, 80)
	hair_next.pressed.connect(_on_hair_next)
	hair_row.add_child(hair_next)

	$"../ScrollContainer/CenterContainer/VBox".add_child(hair_row)
	_update_hair_label()

	# Hair style/type row
	var style_row := HBoxContainer.new()
	style_row.alignment = BoxContainer.ALIGNMENT_CENTER
	style_row.custom_minimum_size = Vector2(0, 80)

	var style_lbl := Label.new()
	style_lbl.text = "Причёска: "
	style_row.add_child(style_lbl)

	var style_prev := Button.new()
	style_prev.text = " < "
	style_prev.custom_minimum_size = Vector2(80, 80)
	style_prev.pressed.connect(_on_style_prev)
	style_row.add_child(style_prev)

	_style_label = Label.new()
	_style_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_style_label.custom_minimum_size = Vector2(120, 0)
	style_row.add_child(_style_label)

	var style_next := Button.new()
	style_next.text = " > "
	style_next.custom_minimum_size = Vector2(80, 80)
	style_next.pressed.connect(_on_style_next)
	style_row.add_child(style_next)

	$"../ScrollContainer/CenterContainer/VBox".add_child(style_row)
	_update_style_label()

	# Dev mode button — hidden until 5-tap reveals it
	_dev_btn = Button.new()
	_dev_btn.custom_minimum_size = Vector2(0, 60)
	_dev_btn.visible = GameState.developer_mode
	_dev_btn.pressed.connect(_on_dev_toggle)
	_update_dev_btn_text()
	$"../ScrollContainer/CenterContainer/VBox".add_child(_dev_btn)

	# About button — toggles changelog panel
	var about_sep := HSeparator.new()
	$"../ScrollContainer/CenterContainer/VBox".add_child(about_sep)

	_about_btn = Button.new()
	_about_btn.custom_minimum_size = Vector2(0, 50)
	_about_btn.add_theme_font_size_override("font_size", ThemeManager.font_size(18))
	_about_btn.pressed.connect(_on_about_toggle)
	_update_about_btn_text(false)
	$"../ScrollContainer/CenterContainer/VBox".add_child(_about_btn)

	# About panel — hidden by default
	_about_panel = VBoxContainer.new()
	_about_panel.visible = false
	_about_panel.alignment = BoxContainer.ALIGNMENT_CENTER

	var version_str := "0.0.0"
	var vf := FileAccess.open("res://VERSION", FileAccess.READ)
	if vf:
		version_str = vf.get_as_text().strip_edges()
		vf.close()

	var version_label := Label.new()
	version_label.text = "7 Days Journey v%s" % version_str
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version_label.add_theme_font_size_override("font_size", ThemeManager.font_size(18))
	_about_panel.add_child(version_label)

	var desc_label := Label.new()
	desc_label.text = "Оздоровительная игра-путешествие\n7 дней, 16 практик в день"
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(380, 0)
	desc_label.add_theme_font_size_override("font_size", ThemeManager.font_size(14))
	desc_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.75))
	_about_panel.add_child(desc_label)

	var changes_label := Label.new()
	changes_label.text = (
		"Последние изменения:\n"
		+ "v0.7.0 — Музыка, шейдеры, настройки\n"
		+ "v0.6.6 — Кастомизация, попап, кнопки\n"
		+ "v0.6.0 — Аудио, переходы, эффекты\n"
		+ "v0.5.5 — Визуальное обновление мини-игр\n"
		+ "v0.5.4 — Уведомления, тосты, звёзды"
	)
	changes_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	changes_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	changes_label.custom_minimum_size = Vector2(380, 0)
	changes_label.add_theme_font_size_override("font_size", ThemeManager.font_size(13))
	changes_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	_about_panel.add_child(changes_label)

	$"../ScrollContainer/CenterContainer/VBox".add_child(_about_panel)

	ThemeManager.apply_ui_scale_to_tree($"..")
	GameState.ui_scale_changed.connect(func(_s): ThemeManager.apply_ui_scale_to_tree($".."))
	hide_menu()


func _update_about_btn_text(is_open: bool) -> void:
	if _about_btn:
		_about_btn.text = "О приложении ▲" if is_open else "О приложении ▼"


func _on_about_toggle() -> void:
	if _about_panel:
		_about_panel.visible = not _about_panel.visible
		_update_about_btn_text(_about_panel.visible)


func show_menu() -> void:
	_update_dev_btn_text()
	_dev_btn.visible = GameState.developer_mode
	_update_sfx_btn()
	_update_haptic_btn()
	_update_volume_label()
	# Collapse about panel on re-open
	if _about_panel:
		_about_panel.visible = false
		_update_about_btn_text(false)
	pause_layer.visible = true
	AudioManager.play("popup_open")
func hide_menu() -> void:
	pause_layer.visible = false
	AudioManager.play("popup_close")


func _process(delta: float) -> void:
	if _title_tap_timer > 0.0:
		_title_tap_timer -= delta
		if _title_tap_timer <= 0.0:
			_title_tap_count = 0


func _on_title_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_title_tap_count += 1
		_title_tap_timer = 3.0
		if _title_tap_count >= 5:
			_title_tap_count = 0
			_dev_btn.visible = true
			if not GameState.developer_mode:
				_on_dev_toggle()


func _on_dev_toggle() -> void:
	GameState.developer_mode = not GameState.developer_mode
	_update_dev_btn_text()
	SaveManager.save_game()
	# Re-evaluate time system with new mode
	TimeSystem.start_day(GameState.current_day)


func _update_dev_btn_text() -> void:
	if _dev_btn:
		if GameState.developer_mode:
			_dev_btn.text = "DEV: ON (все доступно)"
		else:
			_dev_btn.text = "DEV: OFF (по расписанию)"


func _on_resume() -> void:
	hide_menu()
	resume_pressed.emit()


func _on_save() -> void:
	SaveManager.save_game()
	save_btn.text = "Сохранено ✓"
	await get_tree().create_timer(1.5).timeout
	save_btn.text = "Сохранить"


func _on_main_menu() -> void:
	hide_menu()
	SaveManager.save_game()
	main_menu_pressed.emit()


func _on_scale_minus() -> void:
	if _scale_idx > 0:
		_scale_idx -= 1
		_apply_scale()


func _on_scale_plus() -> void:
	if _scale_idx < SCALE_STEPS.size() - 1:
		_scale_idx += 1
		_apply_scale()


func _apply_scale() -> void:
	GameState.set_ui_scale(SCALE_STEPS[_scale_idx])
	_update_scale_label()
	SaveManager.save_game()


func _update_scale_label() -> void:
	if _scale_value_label:
		_scale_value_label.text = "%d%%" % int(SCALE_STEPS[_scale_idx] * 100)


# ── Skin color ───────────────────────────────────────────────────

func _on_skin_prev() -> void:
	GameState.hero_skin_idx = wrapi(GameState.hero_skin_idx - 1, 0, GameState.SKIN_PRESETS.size())
	_update_skin_label()
	GameState.hero_appearance_changed.emit()
	SaveManager.save_game()

func _on_skin_next() -> void:
	GameState.hero_skin_idx = wrapi(GameState.hero_skin_idx + 1, 0, GameState.SKIN_PRESETS.size())
	_update_skin_label()
	GameState.hero_appearance_changed.emit()
	SaveManager.save_game()

func _update_skin_label() -> void:
	if _skin_label:
		_skin_label.text = GameState.SKIN_PRESETS[GameState.hero_skin_idx].name


# ── Hair color ───────────────────────────────────────────────────

func _on_hair_prev() -> void:
	GameState.hero_hair_idx = wrapi(GameState.hero_hair_idx - 1, 0, GameState.HAIR_PRESETS.size())
	_update_hair_label()
	GameState.hero_appearance_changed.emit()
	SaveManager.save_game()

func _on_hair_next() -> void:
	GameState.hero_hair_idx = wrapi(GameState.hero_hair_idx + 1, 0, GameState.HAIR_PRESETS.size())
	_update_hair_label()
	GameState.hero_appearance_changed.emit()
	SaveManager.save_game()

func _update_hair_label() -> void:
	if _hair_label:
		_hair_label.text = GameState.HAIR_PRESETS[GameState.hero_hair_idx].name


# ── Hair style/type ──────────────────────────────────────────────

func _on_style_prev() -> void:
	var presets := GameState.get_hair_style_presets()
	GameState.hero_hair_style_idx = wrapi(GameState.hero_hair_style_idx - 1, 0, presets.size())
	_update_style_label()
	GameState.hero_appearance_changed.emit()
	SaveManager.save_game()

func _on_style_next() -> void:
	var presets := GameState.get_hair_style_presets()
	GameState.hero_hair_style_idx = wrapi(GameState.hero_hair_style_idx + 1, 0, presets.size())
	_update_style_label()
	GameState.hero_appearance_changed.emit()
	SaveManager.save_game()

func _update_style_label() -> void:
	if _style_label:
		_style_label.text = GameState.get_hair_style_name()


func _find_closest_scale_idx(value: float) -> int:
	var best_idx := 0
	var best_diff := absf(SCALE_STEPS[0] - value)
	for i in range(1, SCALE_STEPS.size()):
		var diff := absf(SCALE_STEPS[i] - value)
		if diff < best_diff:
			best_diff = diff
			best_idx = i
	return best_idx


# ── Volume ───────────────────────────────────────────────────────

func _on_vol_minus() -> void:
	AudioManager.set_master_volume(AudioManager.get_master_volume() - 0.1)
	_update_volume_label()
	SaveManager.save_game()

func _on_vol_plus() -> void:
	AudioManager.set_master_volume(AudioManager.get_master_volume() + 0.1)
	_update_volume_label()
	SaveManager.save_game()

func _update_volume_label() -> void:
	if _volume_label:
		_volume_label.text = "%d%%" % int(AudioManager.get_master_volume() * 100)


# ── SFX toggle ──────────────────────────────────────────────────

func _on_sfx_toggle() -> void:
	AudioManager.set_sfx_enabled(not AudioManager.get_sfx_enabled())
	_update_sfx_btn()
	SaveManager.save_game()

func _update_sfx_btn() -> void:
	if _sfx_btn:
		_sfx_btn.text = "Звуки: ВКЛ ✓" if AudioManager.get_sfx_enabled() else "Звуки: ВЫКЛ"


# ── Haptic toggle ───────────────────────────────────────────────

func _on_haptic_toggle() -> void:
	GameState.haptic_enabled = not GameState.haptic_enabled
	_update_haptic_btn()
	SaveManager.save_game()

func _update_haptic_btn() -> void:
	if _haptic_btn:
		_haptic_btn.text = "Вибрация: ВКЛ ✓" if GameState.haptic_enabled else "Вибрация: ВЫКЛ"
