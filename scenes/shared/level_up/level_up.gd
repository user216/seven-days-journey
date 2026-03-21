extends Node
## Level-up celebration overlay — delayed 1.5s after activity, slide-in animation.

@onready var level_layer: CanvasLayer = $".."
@onready var center: CenterContainer = $"../CenterContainer"
@onready var level_label: Label = $"../CenterContainer/Panel/VBox/LevelLabel"
@onready var ok_btn: Button = $"../CenterContainer/Panel/VBox/OkBtn"

var _pending_level: int = 0
var _pending_name: String = ""


func _ready() -> void:
	ok_btn.pressed.connect(hide_popup)
	GameState.level_up.connect(_on_level_up)
	hide_popup()
	ThemeManager.apply_ui_scale_to_tree($"..")
	GameState.ui_scale_changed.connect(func(_s): ThemeManager.apply_ui_scale_to_tree($".."))


func _on_level_up(new_level: int, level_name: String) -> void:
	_pending_level = new_level
	_pending_name = level_name
	# Delay 1.5s so the player sees the activity result first
	await get_tree().create_timer(1.5).timeout
	_show_animated()


func _show_animated() -> void:
	level_label.text = "Уровень %d — %s" % [_pending_level, _pending_name]
	level_layer.visible = true
	# Slide in from above: start offset, tween to center
	center.modulate.a = 0.0
	center.position.y = -120.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(center, "position:y", 0.0, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(center, "modulate:a", 1.0, 0.25).set_ease(Tween.EASE_IN)


func hide_popup() -> void:
	level_layer.visible = false
	center.position.y = 0.0
	center.modulate.a = 1.0
