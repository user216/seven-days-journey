extends MiniInteractionBase
## Swipe falling water droplets left or right.

var droplets: Array[Dictionary] = []
var swiped_count: int = 0
var target_count: int = 8
var _drag_start: Vector2 = Vector2.ZERO
var _dragging_idx: int = -1

var _droplet_tex: Texture2D = preload("res://assets/mini_interactions/water_droplet.svg")
var _droplet_sprites: Array[Sprite2D] = []


func _setup() -> void:
	duration = 10.0
	_spawn_droplets()


func _spawn_droplets() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	for i in range(target_count):
		var pos := Vector2(rng.randf_range(100, size.x - 100), -50.0 - i * 80.0)
		droplets.append({
			"pos": pos,
			"speed": rng.randf_range(120.0, 200.0),
			"active": true,
			"radius": 20.0,
		})
		var spr := Sprite2D.new()
		spr.texture = _droplet_tex
		spr.position = pos
		spr.scale = Vector2(1.2, 1.2)
		add_child(spr)
		_droplet_sprites.append(spr)


func _process_interaction(delta: float) -> void:
	for i in range(droplets.size()):
		var d: Dictionary = droplets[i]
		if d.active:
			d.pos.y += d.speed * delta
			if d.pos.y > size.y + 50:
				d.active = false
		if i < _droplet_sprites.size():
			_droplet_sprites[i].position = d.pos
			_droplet_sprites[i].visible = d.active
	queue_redraw()


func _draw() -> void:
	# Background water effect
	draw_rect(Rect2(Vector2.ZERO, size), ThemeManager.WATER_SOFT)

	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(size.x * 0.5 - 40, 40), "%d/%d" % [swiped_count, target_count],
		HORIZONTAL_ALIGNMENT_CENTER, -1, ThemeManager.font_size(32), ThemeManager.TEXT_BROWN)


func _gui_input(event: InputEvent) -> void:
	if not is_active:
		return
	if event is InputEventMouseButton:
		if event.pressed:
			_drag_start = event.position
			_dragging_idx = _find_droplet(event.position)
		elif _dragging_idx >= 0:
			var swipe_dist: float = event.position.x - _drag_start.x
			if absf(swipe_dist) > 40.0:
				droplets[_dragging_idx].active = false
				swiped_count += 1
				if swiped_count >= target_count:
					complete_interaction()
			_dragging_idx = -1


func _find_droplet(pos: Vector2) -> int:
	for i in range(droplets.size()):
		if droplets[i].active and pos.distance_to(droplets[i].pos) < droplets[i].radius * 2.0:
			return i
	return -1
