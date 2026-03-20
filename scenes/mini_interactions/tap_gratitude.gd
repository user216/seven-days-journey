extends MiniInteractionBase
## Tap 5 gratitude bubbles (Day 2 evening).

var bubbles: Array[Dictionary] = []
var tapped: int = 0
var target: int = 5
var prompts := ["Солнечный свет", "Тёплый чай", "Улыбка друга", "Тихий вечер",
	"Свежий воздух", "Любимая книга", "Красивый закат"]

var _bubble_tex: Texture2D = preload("res://assets/mini_interactions/bubble.svg")
var _bubble_sprites: Array[Sprite2D] = []


func _setup() -> void:
	duration = 10.0
	var rng := RandomNumberGenerator.new()
	rng.seed = 222
	for i in range(target):
		var pos := Vector2(rng.randf_range(80, size.x - 80), size.y + 50 + i * 100)
		bubbles.append({
			"pos": pos,
			"speed": rng.randf_range(30, 60),
			"text": prompts[i % prompts.size()],
			"tapped": false,
			"radius": 50.0,
			"sway_phase": rng.randf_range(0, TAU),
		})
		var spr := Sprite2D.new()
		spr.texture = _bubble_tex
		spr.position = pos
		spr.scale = Vector2(2.0, 2.0)
		add_child(spr)
		_bubble_sprites.append(spr)


func _process_interaction(delta: float) -> void:
	for i in range(bubbles.size()):
		var b: Dictionary = bubbles[i]
		if not b.tapped:
			b.pos.y -= b.speed * delta
			b.pos.x += sin(elapsed * 2.0 + b.sway_phase) * 0.5
		if i < _bubble_sprites.size():
			_bubble_sprites[i].position = b.pos
			if b.tapped:
				_bubble_sprites[i].modulate = ThemeManager.GOLDEN_AMBER
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("#1a1a3e"))

	var font := ThemeDB.fallback_font
	for b in bubbles:
		if b.pos.y < -100:
			continue
		if b.tapped:
			draw_string(font, b.pos + Vector2(-40, 5), b.text,
				HORIZONTAL_ALIGNMENT_CENTER, 100, ThemeManager.font_size(16), ThemeManager.TEXT_BROWN)
		else:
			draw_string(font, b.pos + Vector2(-5, 8), "?",
				HORIZONTAL_ALIGNMENT_CENTER, -1, ThemeManager.font_size(28), Color.WHITE)

	draw_string(font, Vector2(size.x * 0.5 - 40, 40),
		"🙏 %d/%d" % [tapped, target],
		HORIZONTAL_ALIGNMENT_CENTER, -1, ThemeManager.font_size(28), ThemeManager.LIGHT_GOLD)


func _gui_input(event: InputEvent) -> void:
	if not is_active:
		return
	if event is InputEventMouseButton and event.pressed:
		for b in bubbles:
			if not b.tapped and event.position.distance_to(b.pos) < b.radius * 1.5:
				b.tapped = true
				tapped += 1
				if tapped >= target:
					complete_interaction()
				break
