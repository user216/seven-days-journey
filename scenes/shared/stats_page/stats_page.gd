extends Node
## Stats & Achievements page — shows XP breakdown, streaks, activity progress, earned badges.

signal close_pressed

@onready var stats_layer: CanvasLayer = $".."
@onready var vbox: VBoxContainer = $"../ScrollContainer/VBox"


func _ready() -> void:
	hide_page()
	ThemeManager.apply_ui_scale_to_tree($"..")
	GameState.ui_scale_changed.connect(func(_s): ThemeManager.apply_ui_scale_to_tree($".."))


func show_page() -> void:
	_build_content()
	stats_layer.visible = true


func hide_page() -> void:
	stats_layer.visible = false


func _build_content() -> void:
	# Clear previous content
	for child in vbox.get_children():
		child.queue_free()

	# Title + close button
	var header := HBoxContainer.new()
	header.alignment = BoxContainer.ALIGNMENT_CENTER

	var title := Label.new()
	title.text = "Статистика и Достижения"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", ThemeManager.font_size(28))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)

	var close_btn := Button.new()
	close_btn.text = " ✕ "
	close_btn.custom_minimum_size = Vector2(80, 80)
	close_btn.add_theme_font_size_override("font_size", ThemeManager.font_size(28))
	close_btn.pressed.connect(func():
		hide_page()
		close_pressed.emit()
	)
	header.add_child(close_btn)
	vbox.add_child(header)

	# XP & Level section
	_add_section_header("Уровень и опыт")
	var xp := GameState.calculate_xp()
	_add_stat_row("Уровень", "%d — %s" % [xp.level, xp.level_name])
	_add_stat_row("Всего XP", "%d" % xp.total)
	_add_stat_row("До следующего", "%d / %d" % [xp.xp_in_level, xp.xp_for_level])

	# XP Progress bar
	var xp_bar := ProgressBar.new()
	xp_bar.custom_minimum_size = Vector2(0, 30)
	xp_bar.max_value = 100
	xp_bar.value = xp.progress_pct
	xp_bar.show_percentage = false
	vbox.add_child(xp_bar)

	# Activity stats
	_add_section_header("Активности")
	_add_stat_row("День", "%d / 7" % GameState.current_day)
	_add_stat_row("Выполнено сегодня", "%d / 16" % GameState.get_daily_score(GameState.current_day))
	_add_stat_row("Всего за неделю", "%d / 112" % GameState.get_weekly_score())
	_add_stat_row("Идеальных дней", "%d" % GameState.get_perfect_days())

	# Streak
	_add_section_header("Серия")
	_add_stat_row("Текущая серия", "%d дн." % GameState.streak_current)
	_add_stat_row("Лучшая серия", "%d дн." % GameState.streak_best)

	# XP Breakdown
	_add_section_header("Источники XP")
	var reactions := GameState.get_weekly_score()
	_add_stat_row("Реакции (%d x %d)" % [reactions, GameData.XP_PER_REACTION],
		"%d XP" % (reactions * GameData.XP_PER_REACTION))
	_add_stat_row("Серия (%d x %d)" % [GameState.streak_current, GameData.XP_PER_STREAK_DAY],
		"%d XP" % (GameState.streak_current * GameData.XP_PER_STREAK_DAY))
	_add_stat_row("Достижения (%d x %d)" % [GameState.achievements_earned.size(), GameData.XP_PER_ACHIEVEMENT],
		"%d XP" % (GameState.achievements_earned.size() * GameData.XP_PER_ACHIEVEMENT))
	_add_stat_row("Идеальные дни (%d x %d)" % [GameState.get_perfect_days(), GameData.XP_PER_PERFECT_DAY],
		"%d XP" % (GameState.get_perfect_days() * GameData.XP_PER_PERFECT_DAY))

	# Achievements
	_add_section_header("Достижения (%d / %d)" % [GameState.achievements_earned.size(), GameData.ACHIEVEMENTS.size()])

	for a in GameData.ACHIEVEMENTS:
		var earned := a.key in GameState.achievements_earned
		_add_achievement_row(a, earned)

	# Bottom spacing
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(spacer)


func _add_section_header(text: String) -> void:
	var sep := HSeparator.new()
	vbox.add_child(sep)
	var lbl := Label.new()
	lbl.text = text
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", ThemeManager.font_size(22))
	lbl.add_theme_color_override("font_color", ThemeManager.GOLDEN_AMBER)
	vbox.add_child(lbl)


func _add_stat_row(label_text: String, value_text: String) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 44)

	var lbl := Label.new()
	lbl.text = label_text
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lbl.add_theme_font_size_override("font_size", ThemeManager.font_size(18))
	row.add_child(lbl)

	var val := Label.new()
	val.text = value_text
	val.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	val.add_theme_font_size_override("font_size", ThemeManager.font_size(18))
	val.add_theme_color_override("font_color", Color.WHITE)
	row.add_child(val)

	vbox.add_child(row)


func _add_achievement_row(achievement: Dictionary, earned: bool) -> void:
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(0, 70)
	if not earned:
		panel.modulate = Color(0.5, 0.5, 0.5, 0.6)

	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0, 60)

	# Badge icon (drawn as colored circle with initial letter)
	var badge := Label.new()
	if earned:
		badge.text = " * "
		badge.add_theme_color_override("font_color", ThemeManager.GOLDEN_AMBER)
	else:
		badge.text = " ? "
		badge.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	badge.add_theme_font_size_override("font_size", ThemeManager.font_size(28))
	row.add_child(badge)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var title_lbl := Label.new()
	title_lbl.text = achievement.title
	title_lbl.add_theme_font_size_override("font_size", ThemeManager.font_size(18))
	if earned:
		title_lbl.add_theme_color_override("font_color", Color.WHITE)
	info.add_child(title_lbl)

	var desc_lbl := Label.new()
	desc_lbl.text = achievement.description
	desc_lbl.add_theme_font_size_override("font_size", ThemeManager.font_size(15))
	desc_lbl.add_theme_color_override("font_color", Color(0.65, 0.65, 0.65))
	info.add_child(desc_lbl)

	row.add_child(info)

	if earned:
		var check := Label.new()
		check.text = "+"
		check.add_theme_font_size_override("font_size", ThemeManager.font_size(22))
		check.add_theme_color_override("font_color", ThemeManager.SAGE_GREEN)
		row.add_child(check)

	panel.add_child(row)
	vbox.add_child(panel)
