extends Node
## Pause menu — save, navigation, hidden dev mode toggle.

signal resume_pressed
signal main_menu_pressed

@onready var pause_layer: CanvasLayer = $".."
@onready var title_label: Label = $"../CenterContainer/VBox/TitleLabel"
@onready var resume_btn: Button = $"../CenterContainer/VBox/ResumeBtn"
@onready var save_btn: Button = $"../CenterContainer/VBox/SaveBtn"
@onready var main_menu_btn: Button = $"../CenterContainer/VBox/MainMenuBtn"

var _title_tap_count: int = 0
var _title_tap_timer: float = 0.0
var _dev_btn: Button = null
var _scale_value_label: Label = null
var _scale_idx: int = 1

const SCALE_STEPS: Array[float] = [0.8, 1.0, 1.2, 1.5]


func _ready() -> void:
	resume_btn.pressed.connect(_on_resume)
	save_btn.pressed.connect(_on_save)
	main_menu_btn.pressed.connect(_on_main_menu)
	title_label.gui_input.connect(_on_title_input)

	# Settings section
	var sep := HSeparator.new()
	$"../CenterContainer/VBox".add_child(sep)

	var settings_header := Label.new()
	settings_header.text = "⚙ Настройки"
	settings_header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	settings_header.add_theme_font_size_override("font_size", ThemeManager.font_size(22))
	$"../CenterContainer/VBox".add_child(settings_header)

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
	minus_btn.custom_minimum_size = Vector2(80, 50)
	minus_btn.pressed.connect(_on_scale_minus)
	scale_row.add_child(minus_btn)

	_scale_value_label = Label.new()
	_scale_value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_scale_value_label.custom_minimum_size = Vector2(100, 0)
	_update_scale_label()
	scale_row.add_child(_scale_value_label)

	var plus_btn := Button.new()
	plus_btn.text = " + "
	plus_btn.custom_minimum_size = Vector2(80, 50)
	plus_btn.pressed.connect(_on_scale_plus)
	scale_row.add_child(plus_btn)

	$"../CenterContainer/VBox".add_child(scale_row)

	# Dev mode button — hidden until 5-tap reveals it
	_dev_btn = Button.new()
	_dev_btn.custom_minimum_size = Vector2(0, 60)
	_dev_btn.visible = GameState.developer_mode
	_dev_btn.pressed.connect(_on_dev_toggle)
	_update_dev_btn_text()
	$"../CenterContainer/VBox".add_child(_dev_btn)

	ThemeManager.apply_ui_scale_to_tree($"..")
	GameState.ui_scale_changed.connect(func(_s): ThemeManager.apply_ui_scale_to_tree($".."))
	hide_menu()


func show_menu() -> void:
	_update_dev_btn_text()
	_dev_btn.visible = GameState.developer_mode
	pause_layer.visible = true


func hide_menu() -> void:
	pause_layer.visible = false


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


func _find_closest_scale_idx(value: float) -> int:
	var best_idx := 0
	var best_diff := absf(SCALE_STEPS[0] - value)
	for i in range(1, SCALE_STEPS.size()):
		var diff := absf(SCALE_STEPS[i] - value)
		if diff < best_diff:
			best_diff = diff
			best_idx = i
	return best_idx
