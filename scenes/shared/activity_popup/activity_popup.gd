extends Node
## Activity popup — shows card info and hosts mini-interaction scenes.

signal activity_done(slot_id: String, completed: bool)

@onready var popup_layer: CanvasLayer = $".."
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

	# Reset buttons
	skip_btn.visible = true
	done_btn.visible = true
	done_btn.text = "Готово"

	# Clear old interaction
	if _current_interaction:
		_current_interaction.queue_free()
		_current_interaction = null

	# Load mini-interaction scene
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


func hide_popup() -> void:
	popup_layer.visible = false
	if _current_interaction:
		_current_interaction.queue_free()
		_current_interaction = null


func _on_interaction_completed() -> void:
	_interaction_completed = true
	skip_btn.visible = false
	done_btn.text = "Готово ✓"


func _on_done() -> void:
	hide_popup()
	activity_done.emit(_current_slot_id, true)
	TimeSystem.resume()


func _on_close() -> void:
	hide_popup()
	# If mini-game already completed, closing still counts as done
	activity_done.emit(_current_slot_id, _interaction_completed)
	TimeSystem.resume()


func _on_skip() -> void:
	hide_popup()
	activity_done.emit(_current_slot_id, false)
	TimeSystem.resume()
