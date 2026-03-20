extends Node2D
## Vertical climb level — platforms from dawn (bottom) to night (top).
## Time-blocking: platforms locked until real time matches scheduled time.

var platforms: Array[Dictionary] = []
var _hero: Node2D = null
var _activity_popup = null
var _day_summary = null
var _day_cards: Array[Dictionary] = []
var _current_platform: int = 0
var _anim_time: float = 0.0

const PLATFORM_HEIGHT := 300.0
const PLATFORM_WIDTH := 250.0

var _vine_tex: Texture2D = preload("res://assets/environment/vine_segment.svg")
var _platform_tex: Texture2D = preload("res://assets/environment/platform.svg")
var _flower_textures := [
	preload("res://assets/nature/flower_5petal.svg"),
	preload("res://assets/nature/flower_4petal.svg"),
]


func _ready() -> void:
	_build_level()
	TimeSystem.activity_time_reached.connect(_on_activity_time)
	TimeSystem.time_changed.connect(_on_time_changed)
	TimeSystem.day_ended.connect(_on_day_ended)
	TimeSystem.start_day(GameState.current_day)


func _build_level() -> void:
	_day_cards = GameData.get_all_cards_for_day(GameState.current_day)

	# Build platforms bottom to top (first card at bottom)
	var total_height: float = _day_cards.size() * PLATFORM_HEIGHT
	for i in range(_day_cards.size()):
		var card := _day_cards[i]
		var y := total_height - i * PLATFORM_HEIGHT
		var x := 200.0 + (i % 3) * 250.0  # zigzag
		platforms.append({
			"pos": Vector2(x, y),
			"card": card,
			"state": "locked",  # locked, available_late, current, completed
			"bridge_visible": false,
		})

	# Hero starts on bottom platform
	_hero = Node2D.new()
	_hero.set_script(preload("res://scenes/vertical_climb/hero/climb_hero.gd"))
	if platforms.size() > 0:
		_hero.position = platforms[0].pos + Vector2(PLATFORM_WIDTH * 0.5, -30)
	add_child(_hero)

	# Camera follows hero vertically
	var cam := Camera2D.new()
	cam.position_smoothing_enabled = true
	cam.position_smoothing_speed = 4.0
	_hero.add_child(cam)
	cam.make_current()

	# UI
	add_child(preload("res://scenes/shared/hud/hud.tscn").instantiate())

	var popup_inst := preload("res://scenes/shared/activity_popup/activity_popup.tscn").instantiate()
	add_child(popup_inst)
	_activity_popup = popup_inst.get_node("PopupScript")
	_activity_popup.activity_done.connect(_on_activity_done)

	var sum_inst := preload("res://scenes/shared/day_summary/day_summary.tscn").instantiate()
	add_child(sum_inst)
	_day_summary = sum_inst.get_node("SummaryScript")
	_day_summary.next_day_pressed.connect(func(): GameState.advance_day(); get_tree().reload_current_scene())
	_day_summary.game_finished.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn"))

	add_child(preload("res://scenes/shared/level_up/level_up.tscn").instantiate())
	add_child(preload("res://scenes/shared/achievement_toast/achievement_toast.tscn").instantiate())

	# Side vine sprites
	var total_h: float = _day_cards.size() * PLATFORM_HEIGHT
	for i in range(int(total_h / 200)):
		var vy := float(i) * 200.0
		# Left vine
		var lv := Sprite2D.new()
		lv.texture = _vine_tex
		lv.position = Vector2(50, vy + 100)
		lv.scale = Vector2(1.0, 1.0)
		lv.z_index = -1
		add_child(lv)
		# Right vine
		var rv := Sprite2D.new()
		rv.texture = _vine_tex
		rv.position = Vector2(950, vy + 100)
		rv.scale = Vector2(1.0, 1.0)
		rv.z_index = -1
		add_child(rv)


func _process(delta: float) -> void:
	_anim_time += delta
	queue_redraw()


func _refresh_platform_states() -> void:
	for i in range(platforms.size()):
		var p: Dictionary = platforms[i]
		var sid: String = p.card.slot_id
		p.state = TimeSystem.get_activity_state(sid)


func _draw() -> void:
	# Vertical sky gradient — night at top, dawn at bottom
	var total_h: float = (platforms.size() + 2) * PLATFORM_HEIGHT
	for i in range(20):
		var t := float(i) / 20.0
		var colors: Array = ThemeManager.get_sky_colors(1.0 - t)  # inverted: bottom=dawn
		var y := total_h * t - 200
		draw_rect(Rect2(-500, y, 2000, total_h / 20.0 + 2), colors[0])

	# Stars at top
	if platforms.size() > 0:
		ProceduralDrawing.draw_stars(self, Rect2(-200, -200, 1500, PLATFORM_HEIGHT * 3), 30, 0.7, 42)

	# Platforms
	var font := ThemeDB.fallback_font
	for i in range(platforms.size()):
		var p: Dictionary = platforms[i]
		var pos: Vector2 = p.pos
		var card: Dictionary = p.card

		# Platform color based on state
		var platform_color := ThemeManager.EARTHY_BROWN
		match p.state:
			"locked":
				platform_color = Color(0.5, 0.5, 0.5, 0.5)
			"available_late":
				platform_color = ThemeManager.GOLDEN_AMBER.darkened(0.3)
			"current":
				# Pulse glow effect
				var pulse: float = 0.8 + sin(_anim_time * 3.0) * 0.2
				platform_color = Color(
					ThemeManager.GOLDEN_AMBER.r,
					ThemeManager.GOLDEN_AMBER.g,
					ThemeManager.GOLDEN_AMBER.b,
					pulse
				)
				# Glow ring around current platform
				var glow_alpha: float = 0.15 + sin(_anim_time * 2.0) * 0.1
				draw_rect(
					Rect2(pos.x - 10, pos.y - 40, PLATFORM_WIDTH + 20, 75),
					Color(ThemeManager.GOLDEN_AMBER.r, ThemeManager.GOLDEN_AMBER.g,
						ThemeManager.GOLDEN_AMBER.b, glow_alpha)
				)
			"completed":
				platform_color = ThemeManager.DEEP_LEAF

		draw_rect(Rect2(pos.x, pos.y, PLATFORM_WIDTH, 25), platform_color)

		# Activity marker
		var emoji_text: String = card.get("emoji", "")
		var title_text: String = card.get("title", "")
		if title_text.length() > 15:
			title_text = title_text.substr(0, 15) + "…"

		if p.state == "locked":
			# Lock icon and dimmed text
			draw_string(font, pos + Vector2(10, -10), "🔒",
				HORIZONTAL_ALIGNMENT_LEFT, -1, ThemeManager.font_size(24))
			draw_string(font, pos + Vector2(50, -10), title_text,
				HORIZONTAL_ALIGNMENT_LEFT, 200, ThemeManager.font_size(16), Color(0.5, 0.5, 0.5, 0.6))
			# Time label
			var time_str: String = card.get("time", "")
			draw_string(font, pos + Vector2(PLATFORM_WIDTH - 60, -10), time_str,
				HORIZONTAL_ALIGNMENT_RIGHT, 60, ThemeManager.font_size(14), Color(0.5, 0.5, 0.5, 0.8))
		else:
			draw_string(font, pos + Vector2(10, -10), emoji_text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, ThemeManager.font_size(28))
			var title_color: Color = ThemeManager.TEXT_BROWN
			if p.state == "completed":
				title_color = Color(1, 1, 1, 0.9)
			elif p.state == "available_late":
				title_color = ThemeManager.TEXT_BROWN.darkened(0.2)
			draw_string(font, pos + Vector2(50, -10), title_text,
				HORIZONTAL_ALIGNMENT_LEFT, 200, ThemeManager.font_size(16), title_color)
			# Checkmark for completed
			if p.state == "completed":
				draw_string(font, pos + Vector2(PLATFORM_WIDTH - 30, -10), "✅",
					HORIZONTAL_ALIGNMENT_LEFT, -1, ThemeManager.font_size(20))
			# Late indicator
			elif p.state == "available_late":
				draw_string(font, pos + Vector2(PLATFORM_WIDTH - 30, -10), "⏰",
					HORIZONTAL_ALIGNMENT_LEFT, -1, ThemeManager.font_size(18))

		# Bridge/vine to next platform
		if p.bridge_visible and i + 1 < platforms.size():
			var next_pos: Vector2 = platforms[i + 1].pos
			var bridge_start := pos + Vector2(PLATFORM_WIDTH * 0.5, 0)
			var bridge_end := next_pos + Vector2(PLATFORM_WIDTH * 0.5, 25)
			draw_line(bridge_start, bridge_end, ThemeManager.SAGE_GREEN, 4.0)


func _on_activity_time(_slot_id: String, _card: Dictionary) -> void:
	_refresh_platform_states()
	queue_redraw()


func _on_time_changed(_real_time_minutes: float) -> void:
	_refresh_platform_states()
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var world_pos := get_global_mouse_position()
		for i in range(platforms.size()):
			var p: Dictionary = platforms[i]
			if p.state in ["current", "available_late"]:
				var rect := Rect2(p.pos.x, p.pos.y - 50, PLATFORM_WIDTH, 75)
				if rect.has_point(world_pos):
					# Move hero to platform
					_hero.jump_to(p.pos + Vector2(PLATFORM_WIDTH * 0.5, -30))
					_current_platform = i
					await get_tree().create_timer(0.3).timeout
					_activity_popup.show_popup(p.card, GameState.current_day)
					return


func _on_activity_done(slot_id: String, completed: bool) -> void:
	if completed:
		GameState.complete_activity(GameState.current_day, slot_id)
	else:
		GameState.miss_activity(GameState.current_day, slot_id)

	for i in range(platforms.size()):
		if platforms[i].card.slot_id == slot_id:
			if completed:
				platforms[i].bridge_visible = true
			break

	_refresh_platform_states()
	SaveManager.save_game()
	queue_redraw()


func _on_day_ended() -> void:
	_day_summary.show_summary(GameState.current_day)
