extends MiniInteractionBase
## Rapid tapping — 10+ taps in 5 seconds (Day 3 Gibberish).

var tap_count: int = 0
var target_taps: int = 10
var syllables := ["бла", "тру", "ква", "пиф", "зуп", "мяв", "дрр", "фиу", "пок", "тыц"]
var shown_text: String = ""
var text_timer: float = 0.0


func _setup() -> void:
	duration = 7.0


func _process_interaction(delta: float) -> void:
	text_timer -= delta
	if text_timer <= 0:
		shown_text = ""
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), ThemeManager.BLOOM_SOFT)

	var font := ThemeDB.fallback_font

	# Central text
	if shown_text.length() > 0:
		draw_string(font, Vector2(size.x * 0.5 - 60, size.y * 0.45), shown_text,
			HORIZONTAL_ALIGNMENT_CENTER, -1, ThemeManager.font_size(48), ThemeManager.TERRACOTTA)

	# Instruction
	draw_string(font, Vector2(size.x * 0.5 - 80, size.y * 0.2),
		"Тапайте быстрее!",
		HORIZONTAL_ALIGNMENT_CENTER, -1, ThemeManager.font_size(28), ThemeManager.TEXT_BROWN)

	# Counter
	var col := ThemeManager.DEEP_LEAF if tap_count >= target_taps else ThemeManager.TEXT_BROWN
	draw_string(font, Vector2(size.x * 0.5 - 40, size.y * 0.75),
		"%d/%d" % [tap_count, target_taps],
		HORIZONTAL_ALIGNMENT_CENTER, -1, ThemeManager.font_size(36), col)

	# Progress bar
	var bar_w := size.x * 0.7
	var bar_x := size.x * 0.15
	draw_rect(Rect2(bar_x, size.y * 0.85, bar_w, 20), ThemeManager.LIGHT_GOLD)
	var fill := clampf(float(tap_count) / float(target_taps), 0, 1)
	draw_rect(Rect2(bar_x, size.y * 0.85, bar_w * fill, 20), ThemeManager.SAGE_GREEN)


func _gui_input(event: InputEvent) -> void:
	if not is_active:
		return
	if event is InputEventMouseButton and event.pressed:
		tap_count += 1
		shown_text = syllables[tap_count % syllables.size()]
		text_timer = 0.3
		if tap_count >= target_taps:
			complete_interaction()
