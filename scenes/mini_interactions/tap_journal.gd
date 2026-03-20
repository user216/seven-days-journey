extends MiniInteractionBase
## Tap 3 journal pages to "write" on them.

var pages: Array[Dictionary] = []
var tapped_count: int = 0
var target_pages: int = 3

var _page_tex: Texture2D = preload("res://assets/mini_interactions/journal_page.svg")
var _page_sprites: Array[Sprite2D] = []


func _setup() -> void:
	duration = 8.0
	var page_w := size.x * 0.7
	var page_h := size.y * 0.25
	var start_y := size.y * 0.1
	for i in range(target_pages):
		var r := Rect2(size.x * 0.15, start_y + i * (page_h + 20), page_w, page_h)
		pages.append({
			"rect": r,
			"tapped": false,
			"lines_drawn": 0,
		})
		var spr := Sprite2D.new()
		spr.texture = _page_tex
		spr.position = r.get_center()
		var sx: float = page_w / 300.0
		var sy: float = page_h / 200.0
		spr.scale = Vector2(sx, sy)
		add_child(spr)
		_page_sprites.append(spr)


func _draw() -> void:
	# Background — journal cover
	draw_rect(Rect2(Vector2.ZERO, size), ThemeManager.LIGHT_GOLD)

	for i in range(pages.size()):
		var p: Dictionary = pages[i]
		var r: Rect2 = p.rect

		# Written lines (drawn over SVG page)
		var line_count: int = p.lines_drawn
		for j in range(line_count):
			var y := r.position.y + 25 + j * 22
			var line_w := r.size.x * (0.9 if j < line_count - 1 else 0.5)
			draw_line(
				Vector2(r.position.x + 15, y),
				Vector2(r.position.x + 15 + line_w, y),
				ThemeManager.TEXT_BROWN, 1.5
			)

		if not p.tapped:
			# "Tap" hint
			var hint_font := ThemeDB.fallback_font
			draw_string(hint_font, Vector2(r.position.x + r.size.x * 0.3, r.position.y + r.size.y * 0.6),
				"Нажмите...", HORIZONTAL_ALIGNMENT_CENTER, -1, ThemeManager.font_size(24), ThemeManager.HINT_KHAKI)

	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(size.x * 0.5 - 40, size.y - 30),
		"%d/%d" % [tapped_count, target_pages],
		HORIZONTAL_ALIGNMENT_CENTER, -1, ThemeManager.font_size(28), ThemeManager.TEXT_BROWN)


func _gui_input(event: InputEvent) -> void:
	if not is_active:
		return
	if event is InputEventMouseButton and event.pressed:
		for i in range(pages.size()):
			if not pages[i].tapped and pages[i].rect.has_point(event.position):
				pages[i].tapped = true
				pages[i].lines_drawn = 5
				tapped_count += 1
				queue_redraw()
				if tapped_count >= target_pages:
					complete_interaction()
				break
