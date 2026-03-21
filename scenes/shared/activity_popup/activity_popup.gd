extends Node
## Activity popup — shows card info and hosts mini-interaction scenes.
## Slide-in animation on show, fade-out on hide.

signal activity_done(slot_id: String, completed: bool)

@onready var popup_layer: CanvasLayer = $".."
@onready var dimmer: ColorRect = $"../Dimmer"
@onready var panel: PanelContainer = $"../Panel"
@onready var emoji_label: Label = $"../Panel/VBox/Header/EmojiLabel"
@onready var title_label: Label = $"../Panel/VBox/Header/TitleLabel"
@onready var close_btn: Button = $"../Panel/VBox/Header/CloseBtn"
@onready var description: Label = $"../Panel/VBox/Description"
@onready var interaction_container: Control = $"../Panel/VBox/InteractionContainer"
@onready var skip_btn: Button = $"../Panel/VBox/ButtonRow/SkipBtn"
@onready var done_btn: Button = $"../Panel/VBox/ButtonRow/DoneBtn"

var _current_slot_id: String = ""
var _current_interaction: Node = null
var _interaction_completed: bool = false
var _hide_tween: Tween = null


func _ready() -> void:
	close_btn.pressed.connect(_on_close)
	skip_btn.pressed.connect(_on_skip)
	done_btn.pressed.connect(_on_done)
	hide_popup()
	ThemeManager.apply_ui_scale_to_tree($"..")
	GameState.ui_scale_changed.connect(func(_s): ThemeManager.apply_ui_scale_to_tree($".."))


func show_popup(card: Dictionary, day_num: int) -> void:
	_current_slot_id = card.slot_id
	_interaction_completed = false
	emoji_label.text = card.emoji
	title_label.text = card.title
	description.text = card.text

	skip_btn.visible = true
	done_btn.visible = true
	done_btn.text = "Готово"

	if _current_interaction:
		_current_interaction.queue_free()
		_current_interaction = null

	var scene_path := GameData.get_interaction_scene(card.slot_id, day_num)
	if scene_path and ResourceLoader.exists(scene_path):
		var scene := load(scene_path) as PackedScene
		if scene:
			_current_interaction = scene.instantiate()
			interaction_container.add_child(_current_interaction)
			if _current_interaction.has_signal("completed"):
				_current_interaction.completed.connect(_on_interaction_completed)
			if _current_interaction.has_signal("failed"):
				_current_interaction.failed.connect(_on_skip)

	popup_layer.visible = true
	TimeSystem.pause()

	# Animate in: dimmer fade + panel slide up with spring
	dimmer.modulate.a = 0.0
	panel.modulate.a = 0.0
	panel.position.y += 80.0
	var orig_y := panel.position.y - 80.0
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(dimmer, "modulate:a", 1.0, 0.25)
	tween.tween_property(panel, "modulate:a", 1.0, 0.3).set_delay(0.05)
	tween.tween_property(panel, "position:y", orig_y, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func hide_popup() -> void:
	popup_layer.visible = false
	if _current_interaction:
		_current_interaction.queue_free()
		_current_interaction = null


func _animate_hide_and(callback: Callable) -> void:
	if _hide_tween and _hide_tween.is_running():
		return
	_hide_tween = create_tween()
	_hide_tween.set_parallel(true)
	_hide_tween.tween_property(dimmer, "modulate:a", 0.0, 0.2)
	_hide_tween.tween_property(panel, "modulate:a", 0.0, 0.15)
	_hide_tween.tween_property(panel, "position:y", panel.position.y + 60.0, 0.2).set_ease(Tween.EASE_IN)
	_hide_tween.chain().tween_callback(func():
		hide_popup()
		callback.call()
	)


func _on_interaction_completed() -> void:
	_interaction_completed = true
	skip_btn.visible = false
	done_btn.text = "Готово ✓"


func _on_done() -> void:
	_animate_hide_and(func():
		activity_done.emit(_current_slot_id, true)
		TimeSystem.resume()
	)


func _on_close() -> void:
	_animate_hide_and(func():
		activity_done.emit(_current_slot_id, _interaction_completed)
		TimeSystem.resume()
	)


func _on_skip() -> void:
	_animate_hide_and(func():
		activity_done.emit(_current_slot_id, false)
		TimeSystem.resume()
	)
