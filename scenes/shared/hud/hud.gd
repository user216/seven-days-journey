extends Node
## HUD controller — displays time, XP, level, energy, day counter, settings + stats buttons.
## Animated XP bar, floating +XP text, energy pulse, streak flame.

@onready var clock_label: Label = %"ClockLabel" if has_node("%ClockLabel") else $"../TopBar/Panel/HBoxContainer/ClockLabel"
@onready var day_label: Label = $"../TopBar/Panel/HBoxContainer/DayLabel"
@onready var xp_bar: ProgressBar = $"../TopBar/Panel/HBoxContainer/XPBar"
@onready var level_label: Label = $"../TopBar/Panel/HBoxContainer/LevelLabel"
@onready var energy_bar: ProgressBar = $"../TopBar/Panel/HBoxContainer/EnergyBar"
@onready var pause_btn: Button = $"../TopBar/Panel/HBoxContainer/PauseBtn"
@onready var stats_btn: Button = $"../TopBar/Panel/HBoxContainer/StatsBtn"

signal pause_pressed
signal stats_pressed

var _xp_tween: Tween = null


func _ready() -> void:
	TimeSystem.time_changed.connect(_on_time_changed)
	GameState.energy_changed.connect(_on_energy_changed)
	GameState.xp_gained.connect(_on_xp_gained)
	pause_btn.pressed.connect(func(): pause_pressed.emit())
	stats_btn.pressed.connect(func(): stats_pressed.emit())
	_refresh()
	ThemeManager.apply_ui_scale_to_tree($"..")
	GameState.ui_scale_changed.connect(func(_s): ThemeManager.apply_ui_scale_to_tree($".."))


func _refresh() -> void:
	clock_label.text = TimeSystem.get_time_string()
	var streak_icon := "🔥" if GameState.streak_current >= 3 else ""
	day_label.text = "%sДень %d/7" % [streak_icon, GameState.current_day]

	var xp_data := GameState.calculate_xp()
	xp_bar.value = xp_data.progress_pct
	level_label.text = "Ур. %d" % xp_data.level

	energy_bar.value = GameState.energy


func _on_time_changed(_game_time: float) -> void:
	clock_label.text = TimeSystem.get_time_string()


func _on_energy_changed(new_val: float) -> void:
	# Red flash when energy is low
	if new_val < 0.25:
		var tw := create_tween()
		tw.tween_property(energy_bar, "modulate", Color(1.4, 0.4, 0.3), 0.15)
		tw.tween_property(energy_bar, "modulate", Color.WHITE, 0.3)
	energy_bar.value = new_val


func _on_xp_gained(amount: int, _source: String) -> void:
	var xp_data := GameState.calculate_xp()

	# Animate XP bar smoothly
	if _xp_tween and _xp_tween.is_running():
		_xp_tween.kill()
	_xp_tween = create_tween()
	_xp_tween.tween_property(xp_bar, "value", xp_data.progress_pct, 0.3).set_ease(Tween.EASE_OUT)

	level_label.text = "Ур. %d" % xp_data.level

	# Floating "+N XP" label
	if amount > 0:
		_spawn_floating_xp(amount)
		AudioManager.play("xp_gain")


func _spawn_floating_xp(amount: int) -> void:
	var float_label := Label.new()
	float_label.text = "+%d XP" % amount
	float_label.add_theme_font_size_override("font_size", ThemeManager.font_size(18))
	float_label.add_theme_color_override("font_color", ThemeManager.GOLDEN_AMBER)
	float_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	float_label.position = xp_bar.global_position + Vector2(xp_bar.size.x * 0.5 - 40, -10)
	$"..".add_child(float_label)

	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(float_label, "position:y", float_label.position.y - 60.0, 0.8).set_ease(Tween.EASE_OUT)
	tw.tween_property(float_label, "modulate:a", 0.0, 0.8).set_delay(0.3)
	tw.chain().tween_callback(func(): float_label.queue_free())
