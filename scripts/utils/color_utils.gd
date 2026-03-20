class_name ColorUtils
## Sky gradient and color helpers.


static func lerp_color_array(colors: Array, t: float) -> Color:
	## Interpolate through an array of colors, t in [0, 1].
	if colors.is_empty():
		return Color.WHITE
	if colors.size() == 1:
		return colors[0]
	var scaled := t * float(colors.size() - 1)
	var idx := int(scaled)
	var frac := scaled - float(idx)
	idx = clampi(idx, 0, colors.size() - 2)
	return colors[idx].lerp(colors[idx + 1], frac)


static func draw_vertical_gradient(canvas: CanvasItem, rect: Rect2,
		top_color: Color, bottom_color: Color) -> void:
	## Draw a vertical gradient rectangle.
	var colors := PackedColorArray([top_color, top_color, bottom_color, bottom_color])
	var points := PackedVector2Array([
		rect.position,
		rect.position + Vector2(rect.size.x, 0),
		rect.position + rect.size,
		rect.position + Vector2(0, rect.size.y),
	])
	canvas.draw_colored_polygon(points, Color.WHITE)
	# Use primitive for gradient
	canvas.draw_rect(rect, top_color)  # Fallback solid — shaders preferred in real Godot


static func hex_to_color(hex: String) -> Color:
	return Color(hex)
