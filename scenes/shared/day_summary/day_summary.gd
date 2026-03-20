extends Node
## Day summary screen — shown at end of each day.

signal next_day_pressed
signal game_finished

@onready var summary_layer: CanvasLayer = $".."
@onready var title_label: Label = $"../Panel/VBox/TitleLabel"
@onready var score_label: Label = $"../Panel/VBox/ScoreLabel"
@onready var xp_label: Label = $"../Panel/VBox/XPLabel"
@onready var streak_label: Label = $"../Panel/VBox/StreakLabel"
@onready var next_btn: Button = $"../Panel/VBox/NextBtn"


func _ready() -> void:
	next_btn.pressed.connect(_on_next)
	hide_summary()
	ThemeManager.apply_ui_scale_to_tree($"..")
	GameState.ui_scale_changed.connect(func(_s): ThemeManager.apply_ui_scale_to_tree($".."))


func show_summary(day: int) -> void:
	var score := GameState.get_daily_score(day)
	var xp_data := GameState.calculate_xp()

	title_label.text = "День %d завершён!" % day
	score_label.text = "Выполнено: %d/%d" % [score, GameData.TOTAL_CARDS_PER_DAY]
	xp_label.text = "Всего XP: %d (Ур. %d — %s)" % [xp_data.total, xp_data.level, xp_data.level_name]
	streak_label.text = "Серия: %d дней" % GameState.streak_current

	if day >= 7:
		next_btn.text = "Завершить практикум"
	else:
		next_btn.text = "День %d →" % (day + 1)

	summary_layer.visible = true


func hide_summary() -> void:
	summary_layer.visible = false


func _on_next() -> void:
	hide_summary()
	if GameState.current_day >= 7:
		game_finished.emit()
	else:
		next_day_pressed.emit()
