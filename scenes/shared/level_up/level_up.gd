extends Node
## Level-up celebration overlay.

@onready var level_layer: CanvasLayer = $".."
@onready var level_label: Label = $"../CenterContainer/VBox/LevelLabel"
@onready var ok_btn: Button = $"../CenterContainer/VBox/OkBtn"


func _ready() -> void:
	ok_btn.pressed.connect(hide_popup)
	GameState.level_up.connect(_on_level_up)
	hide_popup()
	ThemeManager.apply_ui_scale_to_tree($"..")
	GameState.ui_scale_changed.connect(func(_s): ThemeManager.apply_ui_scale_to_tree($".."))


func _on_level_up(new_level: int, level_name: String) -> void:
	level_label.text = "Уровень %d — %s" % [new_level, level_name]
	level_layer.visible = true


func hide_popup() -> void:
	level_layer.visible = false
