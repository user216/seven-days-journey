extends Control
## Gender selection screen — shown before starting a new game.

@onready var female_btn: Button = $VBox/HBox/FemaleBox/FemaleBtn
@onready var male_btn: Button = $VBox/HBox/MaleBox/MaleBtn


func _ready() -> void:
	female_btn.pressed.connect(func(): _select("female"))
	male_btn.pressed.connect(func(): _select("male"))
	ThemeManager.apply_ui_scale_to_tree(self)
	GameState.ui_scale_changed.connect(func(_s): ThemeManager.apply_ui_scale_to_tree(self))


func _select(chosen_gender: String) -> void:
	GameState.gender = chosen_gender
	GameState.start_game()
	SaveManager.save_game()
	SceneTransition.change_scene("res://scenes/vertical_climb/vertical_level.tscn")
