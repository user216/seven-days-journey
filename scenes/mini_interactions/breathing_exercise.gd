extends MiniInteractionBase
## Breathing exercise: inhale 2s, hold 2s, exhale 2s × 2 cycles.

var breath_phase: int = 0  # 0=inhale, 1=hold, 2=exhale
var breath_cycle: int = 0
var phase_elapsed: float = 0.0
var total_cycles: int = 2
var phase_duration: float = 2.0
var circle_scale: float = 0.3
var phase_names: Array[String] = ["Вдох...", "Задержка...", "Выдох..."]


func _setup() -> void:
	duration = 15.0  # generous timeout


func _process_interaction(delta: float) -> void:
	phase_elapsed += delta
	var t := clampf(phase_elapsed / phase_duration, 0.0, 1.0)

	match breath_phase:
		0:  # inhale — grow
			circle_scale = lerpf(0.3, 1.0, t)
		1:  # hold — stay full
			circle_scale = 1.0
		2:  # exhale — shrink
			circle_scale = lerpf(1.0, 0.3, t)

	if phase_elapsed >= phase_duration:
		_next_phase()

	queue_redraw()


func _next_phase() -> void:
	phase_elapsed = 0.0
	breath_phase += 1
	if breath_phase > 2:
		breath_phase = 0
		breath_cycle += 1
		if breath_cycle >= total_cycles:
			complete_interaction()
			return


func _draw() -> void:
	var center := size * 0.5
	var max_radius := minf(size.x, size.y) * 0.3
	var current_radius := max_radius * circle_scale

	# Outer ring
	draw_arc(center, max_radius + 5, 0, TAU, 64,
		Color(ThemeManager.SAGE_GREEN.r, ThemeManager.SAGE_GREEN.g,
		ThemeManager.SAGE_GREEN.b, 0.2), 3.0)

	# Breathing circle
	var alpha := 0.3 + circle_scale * 0.7
	var col := Color(ThemeManager.MINT_SAGE.r, ThemeManager.MINT_SAGE.g,
		ThemeManager.MINT_SAGE.b, alpha)
	draw_circle(center, current_radius, col)

	# Phase label
	var font := ThemeDB.fallback_font
	var label: String = phase_names[breath_phase] if breath_phase < 3 else ""
	draw_string(font, Vector2(center.x - 60, center.y + max_radius + 50), label,
		HORIZONTAL_ALIGNMENT_CENTER, -1, ThemeManager.font_size(32), ThemeManager.TEXT_BROWN)

	# Cycle counter
	draw_string(font, Vector2(center.x - 40, 40),
		"Цикл %d/%d" % [breath_cycle + 1, total_cycles],
		HORIZONTAL_ALIGNMENT_CENTER, -1, ThemeManager.font_size(24), ThemeManager.HINT_KHAKI)
