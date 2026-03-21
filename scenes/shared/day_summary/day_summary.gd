extends Node
## Day summary screen — shown at end of each day with celebration animation.

signal next_day_pressed
signal game_finished

@onready var summary_layer: CanvasLayer = $".."
@onready var dimmer: ColorRect = $"../Dimmer"
@onready var panel: PanelContainer = $"../Panel"
@onready var title_label: Label = $"../Panel/VBox/TitleLabel"
@onready var score_label: Label = $"../Panel/VBox/ScoreLabel"
@onready var xp_label: Label = $"../Panel/VBox/XPLabel"
@onready var streak_label: Label = $"../Panel/VBox/StreakLabel"
@onready var next_btn: Button = $"../Panel/VBox/NextBtn"

var _confetti: GPUParticles2D = null


func _ready() -> void:
	next_btn.pressed.connect(_on_next)
	hide_summary()
	ThemeManager.apply_ui_scale_to_tree($"..")
	GameState.ui_scale_changed.connect(func(_s): ThemeManager.apply_ui_scale_to_tree($".."))
	_setup_confetti()


func _setup_confetti() -> void:
	_confetti = GPUParticles2D.new()
	_confetti.emitting = false
	_confetti.one_shot = true
	_confetti.amount = 60
	_confetti.lifetime = 3.0
	_confetti.explosiveness = 0.85
	_confetti.z_index = 10
	_confetti.position = Vector2(540, 200)

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 80.0
	mat.initial_velocity_min = 200.0
	mat.initial_velocity_max = 500.0
	mat.gravity = Vector3(0, 400, 0)
	mat.angular_velocity_min = -200.0
	mat.angular_velocity_max = 200.0
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(400, 10, 0)
	mat.scale_min = 0.6
	mat.scale_max = 2.0

	var ramp := Gradient.new()
	ramp.set_offset(0, 0.0)
	ramp.set_color(0, Color(0.83, 0.66, 0.26, 1.0))  # gold
	ramp.add_point(0.2, Color(0.49, 0.64, 0.27, 0.9))  # sage green
	ramp.add_point(0.5, Color(0.79, 0.53, 0.33, 0.8))  # terracotta
	ramp.add_point(0.8, Color(0.72, 0.81, 0.48, 0.5))  # light sage
	ramp.set_offset(ramp.get_point_count() - 1, 1.0)
	ramp.set_color(ramp.get_point_count() - 1, Color(0.96, 0.9, 0.72, 0.0))
	var tex := GradientTexture1D.new()
	tex.gradient = ramp
	mat.color_ramp = tex
	_confetti.process_material = mat

	# Soft circle texture
	var sz := 8
	var img := Image.create(sz, sz, false, Image.FORMAT_RGBA8)
	var center := Vector2(4, 4)
	for y in range(sz):
		for x in range(sz):
			var dist := Vector2(x, y).distance_to(center)
			var alpha := clampf(1.0 - dist / 4.0, 0.0, 1.0)
			alpha *= alpha
			img.set_pixel(x, y, Color(1.0, 1.0, 1.0, alpha))
	_confetti.texture = ImageTexture.create_from_image(img)
	$"..".add_child(_confetti)


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

	# Entrance animation
	dimmer.modulate.a = 0.0
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.85, 0.85)
	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(dimmer, "modulate:a", 1.0, 0.3)
	tween.tween_property(panel, "modulate:a", 1.0, 0.35).set_delay(0.1)
	tween.tween_property(panel, "scale", Vector2.ONE, 0.4).set_delay(0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Fire confetti after panel lands
	if _confetti:
		await get_tree().create_timer(0.5).timeout
		_confetti.restart()
		_confetti.emitting = true


func hide_summary() -> void:
	summary_layer.visible = false


func _on_next() -> void:
	hide_summary()
	if GameState.current_day >= 7:
		game_finished.emit()
	else:
		next_day_pressed.emit()
