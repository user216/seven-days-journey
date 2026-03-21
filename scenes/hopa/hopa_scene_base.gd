extends Node2D
## Core HOPA gameplay scene — background, hidden objects, tap detection, reveal, flow.

signal level_completed(scene_id: String, stats: Dictionary)
signal object_found(object_id: String)
signal timer_expired

# ── Preloads ─────────────────────────────────────────────────────

const HUD_SCRIPT := preload("res://scenes/hopa/ui/hopa_hud.gd")
const DIALOG_SCRIPT := preload("res://scenes/hopa/ui/story_dialog.gd")
const HINT_SYSTEM_SCRIPT := preload("res://scenes/hopa/hint_system.gd")

var _burst_shader: Shader = null

# ── Level data ───────────────────────────────────────────────────

var _level_data: Dictionary = {}
var _scene_id: String = ""

# ── Object tracking ──────────────────────────────────────────────

var _object_nodes: Dictionary = {}    # {object_id: Area2D}
var _found_objects: Array[String] = []
var _total_objects: int = 0

# ── Timing ───────────────────────────────────────────────────────

var _time_remaining: float = 180.0
var _timer_active: bool = false
var _hints_used: int = 0

# ── Child nodes ──────────────────────────────────────────────────

var _background: Sprite2D
var _objects_container: Node2D
var _hud: CanvasLayer
var _dialog: CanvasLayer
var _hint_system: HopaHintSystem
var _burst_rect: ColorRect
var _burst_layer: CanvasLayer
var _ambient_particles: GPUParticles2D

# ── Gameplay state ───────────────────────────────────────────────

var _gameplay_active: bool = false
var _level_start_time: float = 0.0


func _ready() -> void:
	_burst_shader = load("res://shaders/hopa_discovery_burst.gdshader") as Shader
	_load_and_start()


func _process(delta: float) -> void:
	if not _timer_active:
		return

	_time_remaining -= delta
	_hud.update_timer(_time_remaining)
	_hud.set_hint_cooldown(_hint_system.get_cooldown_remaining())

	if _time_remaining <= 0:
		_timer_active = false
		_gameplay_active = false
		timer_expired.emit()
		_on_time_up()


# ── Level loading ────────────────────────────────────────────────

func _load_and_start() -> void:
	# Determine which level to load
	_scene_id = GameState.get("hopa_current_level") if "hopa_current_level" in GameState else ""
	if _scene_id.is_empty():
		_scene_id = HopaData.LEVEL_ORDER[0]

	var json_path := "res://scenes/hopa/levels/%s.json" % _scene_id
	_level_data = HopaLevelLoader.load_level(json_path)

	if _level_data.is_empty():
		push_error("HopaScene: failed to load level: %s" % _scene_id)
		return

	_time_remaining = float(_level_data.get("time_limit", HopaData.DEFAULT_TIME_LIMIT))
	_create_background()
	_create_objects()
	_create_hud()
	_create_hint_system()
	_create_dialog()
	_create_burst_layer()
	_create_ambient_particles()
	_start_level_flow()


# ── Background ───────────────────────────────────────────────────

func _create_background() -> void:
	_background = Sprite2D.new()
	_background.name = "Background"
	_background.centered = false

	var tex: Texture2D = _level_data.get("background_texture")
	if tex != null:
		_background.texture = tex
		# Apply depth shader
		var depth_shader := load("res://shaders/hopa_scene_depth.gdshader") as Shader
		if depth_shader:
			var mat := ShaderMaterial.new()
			mat.shader = depth_shader
			_background.material = mat
	else:
		# Placeholder background
		_background.texture = _create_placeholder_bg()

	add_child(_background)
	move_child(_background, 0)


func _create_placeholder_bg() -> ImageTexture:
	var img := Image.create(1080, 1920, false, Image.FORMAT_RGBA8)
	var bg_color: Color = PlaceholderFactory.create_background_color(_scene_id)
	img.fill(bg_color)
	return ImageTexture.create_from_image(img)


# ── Objects ──────────────────────────────────────────────────────

func _create_objects() -> void:
	_objects_container = Node2D.new()
	_objects_container.name = "ObjectsContainer"
	add_child(_objects_container)

	var objects: Array = _level_data.get("objects", [])
	_total_objects = objects.size()

	for i in range(objects.size()):
		var obj: Dictionary = objects[i]
		var obj_id: String = obj.get("id", "obj_%d" % i)
		var area := _create_object_node(obj, i)
		area.name = obj_id
		_objects_container.add_child(area)
		_object_nodes[obj_id] = area


func _create_object_node(obj: Dictionary, idx: int) -> Area2D:
	var area := Area2D.new()
	area.position = obj.get("position", Vector2(540, 960))
	area.rotation = obj.get("rotation", 0.0)
	area.input_pickable = true
	area.set_meta("object_data", obj)

	# Collision shape
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = obj.get("hint_radius", 60.0)
	shape.shape = circle
	area.add_child(shape)

	# Sprite
	var sprite := Sprite2D.new()
	sprite.name = "Sprite"
	var tex: Texture2D = obj.get("texture")
	if tex != null:
		sprite.texture = tex
	else:
		# Placeholder
		sprite.texture = PlaceholderFactory.create_object_texture(
			obj.get("id", ""), obj.get("name", "?"), idx)

	var obj_scale: float = obj.get("scale", 1.0)
	sprite.scale = Vector2(obj_scale, obj_scale)
	sprite.modulate.a = HopaData.DEFAULT_OBJECTS_ALPHA
	area.add_child(sprite)

	return area


# ── HUD ──────────────────────────────────────────────────────────

func _create_hud() -> void:
	_hud = CanvasLayer.new()
	_hud.set_script(HUD_SCRIPT)
	add_child(_hud)

	var day := HopaData.get_day_number(_scene_id)
	var obj_names: Array = []
	for obj in _level_data.get("objects", []):
		obj_names.append({"id": obj.get("id", ""), "name": obj.get("name", "")})
	_hud.setup(day, obj_names)
	_hud.hint_requested.connect(_on_hint_requested)
	_hud.pause_requested.connect(_on_pause_requested)


# ── Hint system ──────────────────────────────────────────────────

func _create_hint_system() -> void:
	_hint_system = HopaHintSystem.new()
	_hint_system.cooldown = float(_level_data.get("hint_cooldown", HopaData.DEFAULT_HINT_COOLDOWN))
	add_child(_hint_system)


# ── Dialog ───────────────────────────────────────────────────────

func _create_dialog() -> void:
	_dialog = CanvasLayer.new()
	_dialog.set_script(DIALOG_SCRIPT)
	add_child(_dialog)


# ── Burst effect ─────────────────────────────────────────────────

func _create_burst_layer() -> void:
	_burst_layer = CanvasLayer.new()
	_burst_layer.layer = 40

	_burst_rect = ColorRect.new()
	_burst_rect.anchors_preset = Control.PRESET_FULL_RECT
	_burst_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_burst_rect.visible = false

	if _burst_shader:
		var mat := ShaderMaterial.new()
		mat.shader = _burst_shader
		mat.set_shader_parameter("progress", 0.0)
		_burst_rect.material = mat

	_burst_layer.add_child(_burst_rect)
	add_child(_burst_layer)


# ── Ambient particles ────────────────────────────────────────────

func _create_ambient_particles() -> void:
	_ambient_particles = GPUParticles2D.new()
	_ambient_particles.amount = 30
	_ambient_particles.lifetime = 4.0
	_ambient_particles.z_index = 5

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.initial_velocity_min = 10.0
	mat.initial_velocity_max = 25.0
	mat.gravity = Vector3(0, -8, 0)
	mat.spread = 180.0
	mat.scale_min = 0.3
	mat.scale_max = 0.8
	mat.color = Color(0.99, 0.98, 0.93, 0.2)
	mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	mat.emission_box_extents = Vector3(540, 960, 0)
	_ambient_particles.process_material = mat

	_ambient_particles.texture = PlaceholderFactory.make_soft_circle(8, Color(1, 1, 1, 0.3))
	_ambient_particles.position = Vector2(540, 960)
	add_child(_ambient_particles)


# ── Level flow ───────────────────────────────────────────────────

func _start_level_flow() -> void:
	# Show story_before dialog
	var story_lines = _level_data.get("story_before", "")
	if story_lines is String and not story_lines.is_empty():
		story_lines = [story_lines]

	# Also try HopaData
	if story_lines is Array and story_lines.is_empty():
		story_lines = HopaData.get_story(_scene_id, "before")

	if story_lines is Array and not story_lines.is_empty():
		_dialog.show_dialog(story_lines)
		await _dialog.dialog_finished
		await get_tree().create_timer(0.3).timeout

	# Start gameplay
	_gameplay_active = true
	_timer_active = true
	_level_start_time = Time.get_ticks_msec() / 1000.0


# ── Input handling ───────────────────────────────────────────────

func _unhandled_input(event: InputEvent) -> void:
	if not _gameplay_active:
		return
	if event is InputEventMouseButton and event.pressed:
		_handle_tap(event.position)


func _handle_tap(pos: Vector2) -> void:
	# Check against all unfound object areas
	for obj_id in _object_nodes:
		if obj_id in _found_objects:
			continue
		var area: Area2D = _object_nodes[obj_id]
		var local_pos := area.to_local(pos)
		var shape: CollisionShape2D = area.get_child(0) as CollisionShape2D
		if shape and shape.shape is CircleShape2D:
			var radius: float = shape.shape.radius
			if local_pos.length() <= radius:
				_on_object_tapped(obj_id)
				return

	# Wrong tap
	_play_wrong_tap_feedback()


func _on_object_tapped(obj_id: String) -> void:
	if obj_id in _found_objects:
		return

	_found_objects.append(obj_id)
	_hint_system.cancel_glow()

	var area: Area2D = _object_nodes[obj_id]
	var sprite: Sprite2D = area.get_node("Sprite") as Sprite2D

	# Play reveal animation
	if sprite:
		_play_reveal(sprite, area.position, obj_id)

	# Play burst effect
	_play_discovery_burst(area.global_position)

	# Update HUD
	_hud.update_found_count(_found_objects.size(), _total_objects)
	_hud.mark_object_found(obj_id)

	# Check for key item
	var obj_data: Dictionary = area.get_meta("object_data")
	if obj_data.get("is_key_item", false):
		_hud.add_inventory_item(obj_id, sprite.texture if sprite else null)

	# Haptic feedback
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(50)

	object_found.emit(obj_id)

	# Check if all found
	if _found_objects.size() >= _total_objects:
		await get_tree().create_timer(0.8).timeout
		_on_all_objects_found()


# ── Reveal animation ─────────────────────────────────────────────

func _play_reveal(sprite: Sprite2D, world_pos: Vector2, obj_id: String) -> void:
	# 1. White flash
	sprite.modulate = Color.WHITE
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.1)

	# 2. Scale bounce
	var orig_scale := sprite.scale
	tween.tween_property(sprite, "scale", orig_scale * 1.4, 0.15) \
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(sprite, "scale", orig_scale, 0.1) \
		.set_ease(Tween.EASE_IN)

	# 3. Sparkle particles
	_spawn_sparkles(world_pos)

	# 4. Tween to found list position
	var target: Vector2 = _hud.get_object_found_position(obj_id)
	tween.tween_property(sprite, "global_position", target, 0.4) \
		.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.parallel().tween_property(sprite, "scale", orig_scale * 0.3, 0.4)

	# 5. Fade out at destination
	tween.tween_property(sprite, "modulate:a", 0.0, 0.2)


func _spawn_sparkles(pos: Vector2) -> void:
	var particles := GPUParticles2D.new()
	particles.one_shot = true
	particles.emitting = true
	particles.amount = 20
	particles.lifetime = 0.8
	particles.position = pos

	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, -1, 0)
	mat.spread = 180.0
	mat.initial_velocity_min = 40.0
	mat.initial_velocity_max = 100.0
	mat.gravity = Vector3(0, 50, 0)
	mat.scale_min = 0.5
	mat.scale_max = 1.2
	mat.color = Color(0.83, 0.66, 0.26, 0.8)  # gold
	particles.process_material = mat
	particles.texture = PlaceholderFactory.make_soft_circle(6, Color(0.83, 0.66, 0.26))

	add_child(particles)
	# Auto-cleanup
	var timer := get_tree().create_timer(1.5)
	timer.timeout.connect(func():
		if is_instance_valid(particles):
			particles.queue_free()
	)


# ── Discovery burst ──────────────────────────────────────────────

func _play_discovery_burst(world_pos: Vector2) -> void:
	if _burst_rect.material == null:
		return

	var viewport_size := get_viewport_rect().size
	var norm_pos := world_pos / viewport_size
	var mat: ShaderMaterial = _burst_rect.material as ShaderMaterial
	mat.set_shader_parameter("center", norm_pos)
	mat.set_shader_parameter("progress", 0.0)
	_burst_rect.visible = true

	var tween := create_tween()
	tween.tween_method(func(val: float):
		mat.set_shader_parameter("progress", val),
		0.0, 1.0, 0.6
	)
	tween.tween_callback(func():
		_burst_rect.visible = false
	)


# ── Wrong tap feedback ───────────────────────────────────────────

func _play_wrong_tap_feedback() -> void:
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(30)

	# Brief red flash overlay
	var flash := ColorRect.new()
	flash.anchors_preset = Control.PRESET_FULL_RECT
	flash.color = Color(0.8, 0.2, 0.1, 0.0)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 100
	add_child(flash)

	var tween := create_tween()
	tween.tween_property(flash, "color:a", 0.12, 0.08)
	tween.tween_property(flash, "color:a", 0.0, 0.15)
	tween.tween_callback(func(): flash.queue_free())


# ── All objects found ────────────────────────────────────────────

func _on_all_objects_found() -> void:
	_timer_active = false
	_gameplay_active = false

	# Trigger puzzle if defined
	var puzzles: Array = _level_data.get("puzzles", [])
	if not puzzles.is_empty():
		var puzzle_cfg: Dictionary = puzzles[0]
		var puzzle_type: String = puzzle_cfg.get("type", "")
		var puzzle_scene_path: String = HopaData.PUZZLE_SCENES.get(puzzle_type, "")
		if not puzzle_scene_path.is_empty() and ResourceLoader.exists(puzzle_scene_path):
			var puzzle_scene := load(puzzle_scene_path) as PackedScene
			if puzzle_scene:
				var puzzle_node := puzzle_scene.instantiate()
				if puzzle_node.has_method("set_puzzle_data"):
					puzzle_node.set_puzzle_data(puzzle_cfg.get("data", {}))
				add_child(puzzle_node)
				puzzle_node.completed.connect(_on_puzzle_completed)
				puzzle_node.failed.connect(_on_puzzle_failed)
				return

	# No puzzle — go directly to story_after
	_show_story_after()


func _on_puzzle_completed() -> void:
	_show_story_after()


func _on_puzzle_failed() -> void:
	# On puzzle fail, still proceed but note it
	_show_story_after()


# ── Post-level flow ──────────────────────────────────────────────

func _show_story_after() -> void:
	var story_lines = _level_data.get("story_after", "")
	if story_lines is String and not story_lines.is_empty():
		story_lines = [story_lines]
	if story_lines is Array and story_lines.is_empty():
		story_lines = HopaData.get_story(_scene_id, "after")

	if story_lines is Array and not story_lines.is_empty():
		_dialog.show_dialog(story_lines)
		await _dialog.dialog_finished
		await get_tree().create_timer(0.3).timeout

	_finish_level()


func _finish_level() -> void:
	var elapsed := Time.get_ticks_msec() / 1000.0 - _level_start_time
	var stats: Dictionary = {
		"scene_id": _scene_id,
		"time_seconds": elapsed,
		"objects_found": _found_objects.size(),
		"hints_used": _hints_used,
	}

	# Update GameState if available
	if GameState.has_method("complete_hopa_level"):
		GameState.complete_hopa_level(_scene_id, elapsed, _found_objects.size(), _hints_used)

	level_completed.emit(_scene_id, stats)

	# Transition to next level or back to menu
	var next_scene: String = HopaData.get_next_level(_scene_id)
	if not next_scene.is_empty():
		if "hopa_current_level" in GameState:
			GameState.hopa_current_level = next_scene
		SceneTransition.change_scene_iris("res://scenes/hopa/hopa_scene_base.tscn")
	else:
		# All levels complete — back to menu
		SceneTransition.change_scene("res://scenes/main_menu/main_menu.tscn")


# ── Timer expired ────────────────────────────────────────────────

func _on_time_up() -> void:
	_gameplay_active = false
	# Show how many objects were found, offer retry
	_dialog.show_dialog([
		"Время вышло!",
		"Найдено %d из %d предметов." % [_found_objects.size(), _total_objects],
		"Попробуйте ещё раз.",
	])
	await _dialog.dialog_finished
	SceneTransition.reload_scene()


# ── Hint ─────────────────────────────────────────────────────────

func _on_hint_requested() -> void:
	if not _hint_system.is_available():
		return

	var unfound: Array = []
	for obj_id in _object_nodes:
		if obj_id not in _found_objects:
			unfound.append({"id": obj_id, "node": _object_nodes[obj_id]})

	_hint_system.use_hint(unfound)
	_hints_used += 1


func _on_pause_requested() -> void:
	_timer_active = false
	_gameplay_active = false
	# Simple pause: show dialog
	_dialog.show_dialog(["Пауза. Нажмите чтобы продолжить."])
	await _dialog.dialog_finished
	_gameplay_active = true
	_timer_active = true
