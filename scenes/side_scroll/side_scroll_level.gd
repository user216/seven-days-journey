extends Node2D
## Side-scroll level — the main orchestrator for side-scroll mode.

const STATION_SCENE := preload("res://scenes/side_scroll/stations/activity_station.tscn")

var stations: Array[Node2D] = []
var _current_station_idx: int = -1
var _day_cards: Array[Dictionary] = []
var _hero: Node2D = null
var _camera: Camera2D = null
var _sky_node: Node2D = null
var _activity_popup = null
var _day_summary = null
var _pause_menu = null


func _ready() -> void:
	_build_day()
	TimeSystem.activity_time_reached.connect(_on_activity_time)
	TimeSystem.day_ended.connect(_on_day_ended)
	TimeSystem.start_day(GameState.current_day)


func _build_day() -> void:
	_day_cards = GameData.get_all_cards_for_day(GameState.current_day)

	# Sky background
	_sky_node = Node2D.new()
	_sky_node.set_script(preload("res://scenes/side_scroll/parallax/sky_layer.gd"))
	add_child(_sky_node)

	# Ground path
	var ground := Node2D.new()
	ground.set_script(preload("res://scenes/side_scroll/environment/procedural_tree.gd"))
	add_child(ground)

	# Spawn stations along X axis
	var station_spacing := 500.0
	for i in range(_day_cards.size()):
		var station: Node2D = STATION_SCENE.instantiate()
		station.position = Vector2(200 + i * station_spacing, 800)
		station.setup(_day_cards[i])
		station.station_tapped.connect(_on_station_tapped)
		add_child(station)
		stations.append(station)

	# Hero
	var hero_scene := preload("res://scenes/side_scroll/hero/side_hero.tscn")
	_hero = hero_scene.instantiate()
	_hero.position = Vector2(100, 800)
	add_child(_hero)

	# Camera follows hero
	_camera = Camera2D.new()
	_camera.position_smoothing_enabled = true
	_camera.position_smoothing_speed = 5.0
	_hero.add_child(_camera)
	_camera.make_current()

	# UI overlays
	var hud_scene := preload("res://scenes/shared/hud/hud.tscn")
	add_child(hud_scene.instantiate())

	var popup_scene := preload("res://scenes/shared/activity_popup/activity_popup.tscn")
	var popup_inst := popup_scene.instantiate()
	add_child(popup_inst)
	_activity_popup = popup_inst.get_node("PopupScript")
	_activity_popup.activity_done.connect(_on_activity_done)

	var summary_scene := preload("res://scenes/shared/day_summary/day_summary.tscn")
	var summary_inst := summary_scene.instantiate()
	add_child(summary_inst)
	_day_summary = summary_inst.get_node("SummaryScript")
	_day_summary.next_day_pressed.connect(_on_next_day)
	_day_summary.game_finished.connect(_on_game_finished)

	add_child(preload("res://scenes/shared/level_up/level_up.tscn").instantiate())
	add_child(preload("res://scenes/shared/achievement_toast/achievement_toast.tscn").instantiate())

	var pause_scene := preload("res://scenes/shared/pause_menu/pause_menu.tscn")
	var pause_inst := pause_scene.instantiate()
	add_child(pause_inst)
	_pause_menu = pause_inst.get_node("PauseScript")
	_pause_menu.main_menu_pressed.connect(func(): get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn"))


func _draw() -> void:
	# Ground
	var ground_y := 830.0
	var total_w: float = stations.size() * 500.0 + 400
	draw_rect(Rect2(-100, ground_y, total_w, 400), ThemeManager.DEEP_LEAF)
	# Path
	draw_rect(Rect2(-100, ground_y - 30, total_w, 30), ThemeManager.EARTHY_BROWN)


func _on_activity_time(slot_id: String, card: Dictionary) -> void:
	for i in range(stations.size()):
		if stations[i].slot_id == slot_id:
			stations[i].activate()
			_hero.walk_to(stations[i].position.x)
			_current_station_idx = i
			break


func _on_station_tapped(station: Node2D) -> void:
	if station.is_active and not station.is_completed:
		_activity_popup.show_popup(station.card_data, GameState.current_day)


func _on_activity_done(slot_id: String, completed: bool) -> void:
	if completed:
		GameState.complete_activity(GameState.current_day, slot_id)
	else:
		GameState.miss_activity(GameState.current_day, slot_id)

	for s in stations:
		if s.slot_id == slot_id:
			if completed:
				s.mark_completed()
			break

	SaveManager.save_game()


func _on_day_ended() -> void:
	_day_summary.show_summary(GameState.current_day)


func _on_next_day() -> void:
	GameState.advance_day()
	SaveManager.save_game()
	get_tree().reload_current_scene()


func _on_game_finished() -> void:
	SaveManager.save_game()
	get_tree().change_scene_to_file("res://scenes/main_menu/main_menu.tscn")


func _unhandled_input(event: InputEvent) -> void:
	# Tap right side = walk right, tap stations handled by station input
	if event is InputEventMouseButton and event.pressed:
		if _hero and not TimeSystem.paused:
			_hero.walk_to(event.global_position.x + _camera.get_screen_center_position().x - 540)
