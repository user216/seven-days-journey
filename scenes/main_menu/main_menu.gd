extends Control
## Main menu — title, continue/new game, dev mode toggle (5-tap).

@onready var title_label: Label = $VBox/TitleLabel
@onready var subtitle_label: Label = $VBox/SubtitleLabel
@onready var continue_btn: Button = $VBox/ContinueBtn
@onready var new_game_btn: Button = $VBox/NewGameBtn

var _title_tap_count: int = 0
var _title_tap_timer: float = 0.0


func _ready() -> void:
	continue_btn.visible = SaveManager.has_save()
	continue_btn.pressed.connect(_on_continue)
	new_game_btn.pressed.connect(_on_new_game)
	title_label.gui_input.connect(_on_title_input)
	_update_dev_indicator()
	ThemeManager.apply_ui_scale_to_tree(self)
	GameState.ui_scale_changed.connect(func(_s): ThemeManager.apply_ui_scale_to_tree(self))


func _on_continue() -> void:
	if SaveManager.load_game():
		SceneTransition.change_scene("res://scenes/vertical_climb/vertical_level.tscn")


func _on_new_game() -> void:
	SceneTransition.change_scene("res://scenes/gender_select/gender_select.tscn")


func _on_title_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		_title_tap_count += 1
		_title_tap_timer = 3.0
		if _title_tap_count >= 5:
			GameState.developer_mode = not GameState.developer_mode
			SaveManager.save_game()
			_title_tap_count = 0
			_update_dev_indicator()


func _process(delta: float) -> void:
	if _title_tap_timer > 0.0:
		_title_tap_timer -= delta
		if _title_tap_timer <= 0.0:
			_title_tap_count = 0


func _update_dev_indicator() -> void:
	if GameState.developer_mode:
		subtitle_label.text = "🔧 Режим разработчика"
	else:
		subtitle_label.text = "Путь гармонии и осознанности"
