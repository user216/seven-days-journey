extends Node
## HUD controller — displays time, XP, level, energy, day counter.

@onready var clock_label: Label = %"ClockLabel" if has_node("%ClockLabel") else $"../TopBar/Panel/HBoxContainer/ClockLabel"
@onready var day_label: Label = $"../TopBar/Panel/HBoxContainer/DayLabel"
@onready var xp_bar: ProgressBar = $"../TopBar/Panel/HBoxContainer/XPBar"
@onready var level_label: Label = $"../TopBar/Panel/HBoxContainer/LevelLabel"
@onready var energy_bar: ProgressBar = $"../TopBar/Panel/HBoxContainer/EnergyBar"
@onready var pause_btn: Button = $"../TopBar/Panel/HBoxContainer/PauseBtn"

signal pause_pressed


func _ready() -> void:
	TimeSystem.time_changed.connect(_on_time_changed)
	GameState.energy_changed.connect(_on_energy_changed)
	GameState.xp_gained.connect(_on_xp_gained)
	pause_btn.pressed.connect(func(): pause_pressed.emit())
	_refresh()
	ThemeManager.apply_ui_scale_to_tree($"..")
	GameState.ui_scale_changed.connect(func(_s): ThemeManager.apply_ui_scale_to_tree($".."))


func _refresh() -> void:
	clock_label.text = TimeSystem.get_time_string()
	day_label.text = "День %d/7" % GameState.current_day

	var xp_data := GameState.calculate_xp()
	xp_bar.value = xp_data.progress_pct
	level_label.text = "Ур. %d" % xp_data.level

	energy_bar.value = GameState.energy


func _on_time_changed(_game_time: float) -> void:
	clock_label.text = TimeSystem.get_time_string()


func _on_energy_changed(new_val: float) -> void:
	energy_bar.value = new_val


func _on_xp_gained(_amount: int, _source: String) -> void:
	var xp_data := GameState.calculate_xp()
	xp_bar.value = xp_data.progress_pct
	level_label.text = "Ур. %d" % xp_data.level
