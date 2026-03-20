extends Node
## Achievement unlock notification toast.

@onready var toast_panel: PanelContainer = $"../ToastPanel"
@onready var emoji_label: Label = $"../ToastPanel/HBox/EmojiLabel"
@onready var title_label: Label = $"../ToastPanel/HBox/VBox/TitleLabel"
@onready var desc_label: Label = $"../ToastPanel/HBox/VBox/DescLabel"

var _hide_timer: float = 0.0


func _ready() -> void:
	GameState.achievement_earned.connect(_on_achievement)
	toast_panel.visible = false
	ThemeManager.apply_ui_scale_to_tree($"..")
	GameState.ui_scale_changed.connect(func(_s): ThemeManager.apply_ui_scale_to_tree($".."))


func _on_achievement(achievement: Dictionary) -> void:
	emoji_label.text = achievement.emoji
	title_label.text = achievement.title
	desc_label.text = achievement.description
	toast_panel.visible = true
	_hide_timer = 3.0


func _process(delta: float) -> void:
	if _hide_timer > 0.0:
		_hide_timer -= delta
		if _hide_timer <= 0.0:
			toast_panel.visible = false
