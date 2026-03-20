extends MiniInteractionBase
## Hold a glowing circle for 3-4 seconds to complete.

var hold_progress: float = 0.0
var hold_target: float = 3.5
var is_holding: bool = false
var circle_radius: float = 80.0


func _setup() -> void:
	duration = 8.0


func _process_interaction(delta: float) -> void:
	if is_holding:
		hold_progress += delta
		if hold_progress >= hold_target:
			complete_interaction()
	queue_redraw()


func _draw() -> void:
	var center := size * 0.5
	var progress_pct := clampf(hold_progress / hold_target, 0.0, 1.0)

	# Background glow
	var glow_alpha := 0.1 + progress_pct * 0.3
	draw_circle(center, circle_radius * 1.5, Color(ThemeManager.LIGHT_GOLD.r,
		ThemeManager.LIGHT_GOLD.g, ThemeManager.LIGHT_GOLD.b, glow_alpha))

	# Main circle
	var fill_color := ThemeManager.SAGE_GREEN.lerp(ThemeManager.GOLDEN_AMBER, progress_pct)
	draw_circle(center, circle_radius, fill_color)

	# Progress arc
	draw_arc(center, circle_radius + 10, -PI / 2, -PI / 2 + TAU * progress_pct,
		64, ThemeManager.DEEP_LEAF, 6.0)

	# Instruction
	var font := ThemeDB.fallback_font
	var text: String = "Удерживайте" if not is_holding else "%.1f с" % hold_progress
	draw_string(font, Vector2(center.x - 60, center.y + circle_radius + 50), text,
		HORIZONTAL_ALIGNMENT_CENTER, -1, ThemeManager.font_size(28), ThemeManager.TEXT_BROWN)


func _gui_input(event: InputEvent) -> void:
	if not is_active:
		return
	if event is InputEventMouseButton:
		var center := size * 0.5
		if event.position.distance_to(center) < circle_radius * 1.5:
			is_holding = event.pressed
		else:
			is_holding = false
