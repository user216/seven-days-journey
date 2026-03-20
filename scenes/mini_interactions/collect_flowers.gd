extends MiniInteractionBase
## Auto-scrolling garden, tap flowers to collect them.

var flowers: Array[Dictionary] = []
var collected: int = 0
var target: int = 5
var scroll_offset: float = 0.0
var scroll_speed: float = 100.0

var _flower_textures := [
	preload("res://assets/nature/flower_5petal.svg"),
	preload("res://assets/nature/flower_4petal.svg"),
	preload("res://assets/nature/flower_tulip.svg"),
]
var _flower_sprites: Array[Sprite2D] = []
var _bouquet_sprite: Sprite2D
var _bouquet_tex: Texture2D = preload("res://assets/mini_interactions/flower_bouquet.svg")


func _setup() -> void:
	duration = 10.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 777
	var flower_colors := [ThemeManager.TERRACOTTA, ThemeManager.GOLDEN_AMBER,
		ThemeManager.LIGHT_SAGE, Color.MEDIUM_PURPLE, Color.LIGHT_PINK]
	for i in range(10):
		var pos_x := 200.0 + i * 150.0 + rng.randf_range(-30, 30)
		var pos_y := rng.randf_range(size.y * 0.4, size.y * 0.75)
		flowers.append({
			"x": pos_x,
			"y": pos_y,
			"color": flower_colors[i % 5],
			"collected": false,
			"radius": 18.0,
		})
		var spr := Sprite2D.new()
		spr.texture = _flower_textures[i % _flower_textures.size()]
		spr.position = Vector2(pos_x, pos_y)
		spr.scale = Vector2(1.5, 1.5)
		spr.self_modulate = flower_colors[i % 5]
		add_child(spr)
		_flower_sprites.append(spr)

	# Bouquet icon top-left
	_bouquet_sprite = Sprite2D.new()
	_bouquet_sprite.texture = _bouquet_tex
	_bouquet_sprite.position = Vector2(50, 60)
	_bouquet_sprite.scale = Vector2(0.8, 0.8)
	add_child(_bouquet_sprite)


func _process_interaction(delta: float) -> void:
	scroll_offset += scroll_speed * delta
	# Update flower sprite positions
	for i in range(flowers.size()):
		if i < _flower_sprites.size():
			var screen_x: float = flowers[i].x - scroll_offset
			_flower_sprites[i].position = Vector2(screen_x, flowers[i].y)
			_flower_sprites[i].visible = not flowers[i].collected and screen_x > -50 and screen_x < size.x + 50
	queue_redraw()


func _draw() -> void:
	# Ground
	draw_rect(Rect2(0, size.y * 0.8, size.x, size.y * 0.2), ThemeManager.DEEP_LEAF)
	# Path
	draw_rect(Rect2(0, size.y * 0.75, size.x, size.y * 0.08), ThemeManager.EARTHY_BROWN)

	# Bouquet counter
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(80, 68), "Букет: %d/%d" % [collected, target],
		HORIZONTAL_ALIGNMENT_LEFT, -1, ThemeManager.font_size(28), ThemeManager.TEXT_BROWN)


func _gui_input(event: InputEvent) -> void:
	if not is_active:
		return
	if event is InputEventMouseButton and event.pressed:
		for f in flowers:
			if f.collected:
				continue
			var screen_x: float = f.x - scroll_offset
			var screen_pos := Vector2(screen_x, f.y)
			if event.position.distance_to(screen_pos) < f.radius * 2.5:
				f.collected = true
				collected += 1
				queue_redraw()
				if collected >= target:
					complete_interaction()
				break
