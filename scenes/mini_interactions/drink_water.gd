extends MiniInteractionBase
## Tap 3 empty glasses to fill them with water.

var glasses: Array[Dictionary] = []
var filled_count: int = 0
var target: int = 3

var _glass_tex: Texture2D = preload("res://assets/mini_interactions/glass_empty.svg")
var _glass_sprites: Array[Sprite2D] = []


func _setup() -> void:
	duration = 8.0
	var glass_w := 80.0
	var glass_h := 110.0
	var spacing := (size.x - glass_w * target) / float(target + 1)
	for i in range(target):
		var r := Rect2(spacing + i * (glass_w + spacing), size.y * 0.32, glass_w, glass_h)
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
	# Warm cream background for contrast with blue water
	draw_rect(Rect2(Vector2.ZERO, size), ThemeManager.BG_CREAM)

	# Hint text
	var font := ThemeDB.fallback_font
	if filled_count == 0:
		draw_string(font, Vector2(size.x * 0.5 - 120, size.y * 0.2),
			"Нажмите на стакан",
			HORIZONTAL_ALIGNMENT_CENTER, 240, ThemeManager.font_size(20), ThemeManager.HINT_KHAKI)

	for g in glasses:
		var r: Rect2 = g.rect
		# Water fill — vivid blue for contrast against cream bg
		if g.fill_anim > 0.0:
			var fill_h: float = r.size.y * g.fill_anim * 0.85
			var fill_rect := Rect2(
				r.position.x + 4, r.position.y + r.size.y - fill_h,
				r.size.x - 8, fill_h - 4
			)
			draw_rect(fill_rect, Color(0.35, 0.65, 0.88, 0.85))
			# Light highlight on water surface
			if g.fill_anim > 0.3:
				var surface_y := r.position.y + r.size.y - fill_h + 2
				draw_rect(Rect2(r.position.x + 8, surface_y, r.size.x - 16, 4),
					Color(0.6, 0.85, 1.0, 0.5))

	# Counter at bottom
	draw_string(font, Vector2(size.x * 0.5 - 40, size.y * 0.85),
		"%d / %d" % [filled_count, target],
		HORIZONTAL_ALIGNMENT_CENTER, -1, ThemeManager.font_size(36), ThemeManager.TEXT_BROWN)


func _gui_input(event: InputEvent) -> void:
	if not is_active:
		return
	if event is InputEventMouseButton and event.pressed:
		for g in glasses:
			if not g.filled and g.rect.has_point(event.position):
				g.filled = true
				filled_count += 1
				if filled_count >= target:
					await get_tree().create_timer(0.4).timeout
					complete_interaction()
				break
