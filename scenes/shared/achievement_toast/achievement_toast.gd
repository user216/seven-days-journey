extends Node
## Achievement unlock notification toast — bottom-positioned, queued, animated.

@onready var toast_panel: PanelContainer = $"../ToastPanel"
@onready var emoji_label: Label = $"../ToastPanel/HBox/EmojiLabel"
@onready var title_label: Label = $"../ToastPanel/HBox/VBox/TitleLabel"
@onready var desc_label: Label = $"../ToastPanel/HBox/VBox/DescLabel"

var _hide_timer: float = 0.0
var _queue: Array[Dictionary] = []
var _showing: bool = false


func _ready() -> void:
	GameState.achievement_earned.connect(_on_achievement)
	toast_panel.visible = false
	ThemeManager.apply_ui_scale_to_tree($"..")
	GameState.ui_scale_changed.connect(func(_s): ThemeManager.apply_ui_scale_to_tree($".."))


func _on_achievement(achievement: Dictionary) -> void:
	_queue.append(achievement)
	if not _showing:
		_show_next()


func _show_next() -> void:
	if _queue.is_empty():
		_showing = false
		return
	_showing = true
	var achievement: Dictionary = _queue.pop_front()
	emoji_label.text = achievement.emoji
	title_label.text = achievement.title
	desc_label.text = achievement.description
	# Slide in from below
	toast_panel.visible = true
	toast_panel.modulate.a = 0.0
	toast_panel.position.y = 60.0
	AudioManager.play("achievement")
	SceneTransition.flash_screen(Color.WHITE)
	GameState.vibrate(80)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(toast_panel, "position:y", 0.0, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(toast_panel, "modulate:a", 1.0, 0.2)
	_hide_timer = 3.0


func _process(delta: float) -> void:
	if _hide_timer > 0.0:
		_hide_timer -= delta
		if _hide_timer <= 0.0:
			# Fade out, then show next queued
			var tween := create_tween()
			tween.tween_property(toast_panel, "modulate:a", 0.0, 0.25)
			tween.tween_callback(func():
				toast_panel.visible = false
				toast_panel.position.y = 0.0
				_show_next()
			)
