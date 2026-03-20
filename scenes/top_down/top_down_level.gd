extends Node2D
## Top-down level — bird's-eye view of house + garden with SVG room textures.

var rooms: Array[Dictionary] = []
var _hero: Node2D = null
var _activity_popup = null
var _day_summary = null
var _day_cards: Array[Dictionary] = []
var _active_room_idx: int = -1

var _room_textures := {
	"Спальня": preload("res://assets/environment/top_down/room_bedroom.svg"),
	"Ванная": preload("res://assets/environment/top_down/room_bathroom.svg"),
	"Йога-комната": preload("res://assets/environment/top_down/room_yoga.svg"),
	"Кабинет": preload("res://assets/environment/top_down/room_study.svg"),
	"Кухня": preload("res://assets/environment/top_down/room_kitchen.svg"),
	"Сад": preload("res://assets/environment/top_down/garden_plot.svg"),
}
var _flower_textures := [
	preload("res://assets/nature/flower_5petal.svg"),
	preload("res://assets/nature/flower_4petal.svg"),
	preload("res://assets/nature/flower_tulip.svg"),
]

# Room definitions: name, rect, slot_ids it handles
const ROOM_DEFS: Array[Dictionary] = [
	{"name": "Спальня", "rect": Rect2(100, 300, 250, 200), "slots": ["wk", "gn", "bp"], "color": "#e8f0da"},
	{"name": "Ванная", "rect": Rect2(380, 300, 200, 200), "slots": ["wp"], "color": "#d6eaf2"},
	{"name": "Йога-комната", "rect": Rect2(100, 530, 250, 200), "slots": ["mp", "tp", "ep"], "color": "#f5e6b8"},
	{"name": "Кабинет", "rect": Rect2(380, 530, 200, 200), "slots": ["pl", "lc"], "color": "#fefcf3"},
	{"name": "Кухня", "rect": Rect2(620, 300, 300, 200), "slots": ["bf", "b2", "lu", "dn", "nc", "dc"], "color": "#f2e0d6"},
	{"name": "Сад", "rect": Rect2(100, 780, 820, 250), "slots": ["wl"], "color": "#a8c97a"},
]


func _ready() -> void:
	_build_level()
	TimeSystem.activity_time_reached.connect(_on_activity_time)
	TimeSystem.day_ended.connect(_on_day_ended)
	TimeSystem.start_day(GameState.current_day)


func _build_level() -> void:
	_day_cards = GameData.get_all_cards_for_day(GameState.current_day)

	for rd in ROOM_DEFS:
		rooms.append({
			"name": rd.name,
			"rect": rd.rect,
			"slots": rd.slots,
			"color": Color(rd.color),
			"active_slot": "",
			"active_card": {},
			"completed_slots": [],
		})
		# Room SVG sprite
		if rd.name in _room_textures:
			var spr := Sprite2D.new()
			spr.texture = _room_textures[rd.name]
			var r: Rect2 = rd.rect
			spr.position = r.get_center()
			var tex_size := spr.texture.get_size()
			spr.scale = Vector2(r.size.x / tex_size.x, r.size.y / tex_size.y)
			spr.z_index = -1
			add_child(spr)

	# Garden flower sprites (seeded)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var flower_colors := [ThemeManager.TERRACOTTA, Color.MEDIUM_PURPLE, Color.LIGHT_PINK]
	for i in range(20):
		var gx := 120.0 + rng.randf_range(0, 780)
		var gy := 800.0 + rng.randf_range(0, 200)
		var fspr := Sprite2D.new()
		fspr.texture = _flower_textures[i % _flower_textures.size()]
		fspr.position = Vector2(gx, gy)
		fspr.scale = Vector2(0.6, 0.6)
		fspr.self_modulate = flower_colors[i % 3]
		fspr.z_index = -1
		add_child(fspr)

	# Hero
	_hero = Node2D.new()
	_hero.set_script(preload("res://scenes/top_down/hero/top_hero.gd"))
	_hero.position = Vector2(225, 400)
	add_child(_hero)

	# Camera
	var cam := Camera2D.new()
	cam.zoom = Vector2(1.5, 1.5)
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
	_day_summary.next_day_pressed.connect(func(): GameState.advance_day(); SceneTransition.reload_scene())
	_day_summary.game_finished.connect(func(): SceneTransition.change_scene("res://scenes/main_menu/main_menu.tscn"))

	add_child(preload("res://scenes/shared/level_up/level_up.tscn").instantiate())
	add_child(preload("res://scenes/shared/achievement_toast/achievement_toast.tscn").instantiate())


func _draw() -> void:
	# Grass background
	draw_rect(Rect2(0, 0, 1080, 1200), ThemeManager.LIGHT_SAGE)

	# House floor
	draw_rect(Rect2(80, 280, 960, 470), ThemeManager.BG_CREAM)
	draw_rect(Rect2(80, 280, 960, 470), ThemeManager.EARTHY_BROWN, false, 4.0)

	# Room overlays (borders, labels, active glow)
	for r in rooms:
		var rect: Rect2 = r.rect
		draw_rect(rect, ThemeManager.EARTHY_BROWN, false, 2.0)

		var font := ThemeDB.fallback_font
		draw_string(font, rect.position + Vector2(10, 25), r.name,
			HORIZONTAL_ALIGNMENT_LEFT, -1, ThemeManager.font_size(18), ThemeManager.TEXT_BROWN)

		# Active glow
		if r.active_slot.length() > 0 and r.active_slot not in r.completed_slots:
			var pulse := 0.2 + sin(TimeSystem.game_time_minutes * 0.1) * 0.1
			draw_rect(rect, Color(ThemeManager.GOLDEN_AMBER.r, ThemeManager.GOLDEN_AMBER.g,
				ThemeManager.GOLDEN_AMBER.b, pulse))
			# Activity emoji
			draw_string(font, rect.get_center() + Vector2(-15, 10), r.active_card.get("emoji", ""),
				HORIZONTAL_ALIGNMENT_CENTER, -1, ThemeManager.font_size(36))


func _on_activity_time(slot_id: String, card: Dictionary) -> void:
	for r in rooms:
		if slot_id in r.slots:
			r.active_slot = slot_id
			r.active_card = card
			queue_redraw()
			break


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		var world_pos := get_global_mouse_position()
		# Check if tapped on an active room
		for r in rooms:
			if r.active_slot.length() > 0 and r.active_slot not in r.completed_slots:
				var rect: Rect2 = r.rect
				if rect.has_point(world_pos):
					_hero.walk_to(rect.get_center())
					await get_tree().create_timer(0.5).timeout
					_activity_popup.show_popup(r.active_card, GameState.current_day)
					return
		# Otherwise move hero
		if _hero:
			_hero.walk_to(world_pos)


func _on_activity_done(slot_id: String, completed: bool) -> void:
	if completed:
		GameState.complete_activity(GameState.current_day, slot_id)
	else:
		GameState.miss_activity(GameState.current_day, slot_id)
	for r in rooms:
		if slot_id == r.active_slot:
			r.completed_slots.append(slot_id)
			r.active_slot = ""
			break
	SaveManager.save_game()
	queue_redraw()


func _on_day_ended() -> void:
	_day_summary.show_summary(GameState.current_day)
