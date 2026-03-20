extends MiniInteractionBase
## Tap 3 empty glasses to fill them with water.

var glasses: Array[Dictionary] = []
var filled_count: int = 0
var target: int = 3

var _glass_tex: Texture2D = preload("res://assets/mini_interactions/glass_empty.svg")
var _glass_sprites: Array[Sprite2D] = []


func _setup() -> void:
	duration = 8.0
	var glass_w := 60.0
	var glass_h := 80.0
	var spacing := (size.x - glass_w * target) / float(target + 1)
	for i in range(target):
		var r := Rect2(spacing + i * (glass_w + spacing), size.y * 0.4, glass_w, glass_h)
		glasses.append({
			"rect": r,
			"filled": false,
			"fill_anim": 0.0,
		})
		var spr := Sprite2D.new()
		spr.texture = _glass_tex
		spr.position = r.get_center()
		var sx: float = glass_w / 80.0
		var sy: float = glass_h / 120.0
		spr.scale = Vector2(sx, sy)
		add_child(spr)
		_glass_sprites.append(spr)


func _process_interaction(delta: float) -> void:
	for g in glasses:
		if g.filled and g.fill_anim < 1.0:
			g.fill_anim = minf(g.fill_anim + delta * 3.0, 1.0)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), ThemeManager.WATER_SOFT)

	for g in glasses:
		var r: Rect2 = g.rect
		# Water fill (procedural — animated)
		if g.fill_anim > 0.0:
			var fill_h: float = r.size.y * g.fill_anim
			var fill_rect := Rect2(
				r.position.x + 3, r.position.y + r.size.y - fill_h,
				r.size.x - 6, fill_h - 3
			)
			draw_rect(fill_rect, ThemeManager.SOFT_TEAL)

	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(size.x * 0.5 - 40, size.y * 0.8),
		"💧 %d/%d" % [filled_count, target],
		HORIZONTAL_ALIGNMENT_CENTER, -1, ThemeManager.font_size(32), ThemeManager.TEXT_BROWN)


func _gui_input(event: InputEvent) -> void:
	if not is_active:
		return
	if event is InputEventMouseButton and event.pressed:
		for g in glasses:
			if not g.filled and g.rect.has_point(event.position):
				g.filled = true
				filled_count += 1
				if filled_count >= target:
					# Slight delay for animation
					await get_tree().create_timer(0.4).timeout
					complete_interaction()
				break
