class_name ProceduralDrawing
## Static helpers for drawing nature objects procedurally — enhanced quality.


static func draw_tree(canvas: CanvasItem, base: Vector2, height: float,
		trunk_color: Color, leaf_color: Color, seed_val: int = 0) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	# Roots
	for r in range(3):
		var rx := rng.randf_range(-height * 0.15, height * 0.15)
		var ry := rng.randf_range(3, 8)
		canvas.draw_line(base + Vector2(rx, -2), base + Vector2(rx * 1.5, ry),
			trunk_color.darkened(0.15), 2.0)

	# Trunk — tapered with bark texture
	var tw := height * 0.1
	canvas.draw_colored_polygon(PackedVector2Array([
		base + Vector2(-tw, 0),
		base + Vector2(tw, 0),
		base + Vector2(tw * 0.6, -height * 0.5),
		base + Vector2(-tw * 0.6, -height * 0.5),
	]), trunk_color)
	# Bark lines
	var bark_dark := trunk_color.darkened(0.2)
	for i in range(4):
		var by := rng.randf_range(-height * 0.05, -height * 0.45)
		var bx := rng.randf_range(-tw * 0.4, tw * 0.4)
		canvas.draw_line(base + Vector2(bx, by), base + Vector2(bx + rng.randf_range(-2, 2), by - 8),
			bark_dark, 1.0)

	# Crown — multiple layered circles with depth
	var cc := base + Vector2(0, -height * 0.55)
	var cr := height * 0.38
	# Shadow layer (behind)
	for i in range(3):
		var off := Vector2(rng.randf_range(-cr * 0.3, cr * 0.3), rng.randf_range(-cr * 0.2, cr * 0.15))
		canvas.draw_circle(cc + off + Vector2(3, 3), cr * rng.randf_range(0.7, 0.95),
			leaf_color.darkened(0.25))
	# Main foliage
	for i in range(5):
		var off := Vector2(rng.randf_range(-cr * 0.35, cr * 0.35), rng.randf_range(-cr * 0.3, cr * 0.15))
		var rad := cr * rng.randf_range(0.6, 0.9)
		canvas.draw_circle(cc + off, rad, leaf_color.lerp(Color.WHITE, rng.randf_range(0.0, 0.1)))
	# Highlight spots
	for i in range(2):
		var off := Vector2(rng.randf_range(-cr * 0.2, cr * 0.1), rng.randf_range(-cr * 0.3, -cr * 0.1))
		canvas.draw_circle(cc + off, cr * rng.randf_range(0.15, 0.25),
			leaf_color.lightened(0.2))


static func draw_flower(canvas: CanvasItem, pos: Vector2, radius: float,
		petal_color: Color, center_color: Color, petals: int = 5) -> void:
	# Stem
	canvas.draw_line(pos, pos + Vector2(0, radius * 2), ThemeManager.DEEP_LEAF, maxf(1.0, radius * 0.15))
	# Petals with slight gradient
	for i in range(petals):
		var angle := TAU / float(petals) * float(i)
		var petal_pos := pos + Vector2.from_angle(angle) * radius * 0.55
		var petal_r := radius * 0.42
		canvas.draw_circle(petal_pos, petal_r, petal_color)
		# Inner petal highlight
		canvas.draw_circle(petal_pos + Vector2.from_angle(angle) * -petal_r * 0.2,
			petal_r * 0.5, petal_color.lightened(0.15))
	# Center with detail
	canvas.draw_circle(pos, radius * 0.32, center_color)
	canvas.draw_circle(pos + Vector2(-radius * 0.05, -radius * 0.05),
		radius * 0.15, center_color.lightened(0.3))


static func draw_bush(canvas: CanvasItem, base: Vector2, width: float,
		color: Color, seed_val: int = 0) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var h := width * 0.65
	# Shadow
	canvas.draw_circle(base + Vector2(2, 2), width * 0.35, color.darkened(0.3))
	# Main body — overlapping circles
	for i in range(6):
		var off := Vector2(rng.randf_range(-width * 0.35, width * 0.35),
			rng.randf_range(-h * 0.5, 0.0))
		var r := width * rng.randf_range(0.2, 0.38)
		canvas.draw_circle(base + Vector2(0, -h * 0.3) + off, r,
			color.lerp(Color.WHITE, rng.randf_range(0.0, 0.08)))
	# Highlights
	for i in range(2):
		var off := Vector2(rng.randf_range(-width * 0.15, width * 0.15), -h * rng.randf_range(0.3, 0.5))
		canvas.draw_circle(base + off, width * rng.randf_range(0.08, 0.14),
			color.lightened(0.2))
	# Occasional small flowers
	if seed_val % 3 == 0:
		var foff := Vector2(rng.randf_range(-width * 0.2, width * 0.2), -h * 0.4)
		draw_flower(canvas, base + foff, width * 0.08,
			ThemeManager.TERRACOTTA.lightened(0.2), ThemeManager.GOLDEN_AMBER, 4)


static func draw_cloud(canvas: CanvasItem, center: Vector2, width: float,
		alpha: float = 0.7) -> void:
	var col := Color(1.0, 1.0, 1.0, alpha)
	var bright := Color(1.0, 1.0, 1.0, alpha * 0.9)
	# Main body
	canvas.draw_circle(center, width * 0.28, col)
	canvas.draw_circle(center + Vector2(-width * 0.22, 0.04 * width), width * 0.22, col)
	canvas.draw_circle(center + Vector2(width * 0.22, 0.03 * width), width * 0.24, col)
	canvas.draw_circle(center + Vector2(0, -width * 0.12), width * 0.21, col)
	# Highlight on top
	canvas.draw_circle(center + Vector2(-width * 0.05, -width * 0.15), width * 0.12, bright)
	# Bottom shadow
	canvas.draw_circle(center + Vector2(0, width * 0.08), width * 0.2,
		Color(0.85, 0.87, 0.9, alpha * 0.5))


static func draw_mountain(canvas: CanvasItem, base_left: Vector2,
		base_right: Vector2, peak_height: float, color: Color) -> void:
	var peak_x := (base_left.x + base_right.x) * 0.5
	var peak := Vector2(peak_x, base_left.y - peak_height)
	canvas.draw_colored_polygon(PackedVector2Array([base_left, peak, base_right]), color)
	# Snow cap
	var snow_y := base_left.y - peak_height * 0.75
	canvas.draw_colored_polygon(PackedVector2Array([
		Vector2(peak_x - peak_height * 0.15, snow_y),
		peak,
		Vector2(peak_x + peak_height * 0.15, snow_y),
	]), Color(1, 1, 1, 0.6))


static func draw_sun(canvas: CanvasItem, center: Vector2, radius: float,
		color: Color = Color("#f5e6b8"), ray_count: int = 12) -> void:
	# Outer glow
	canvas.draw_circle(center, radius * 1.6, Color(color.r, color.g, color.b, 0.15))
	canvas.draw_circle(center, radius * 1.3, Color(color.r, color.g, color.b, 0.25))
	# Main body
	canvas.draw_circle(center, radius, color)
	# Bright center
	canvas.draw_circle(center, radius * 0.6, color.lightened(0.3))
	# Rays
	var ray_color := Color(color.r, color.g, color.b, 0.35)
	for i in range(ray_count):
		var angle := TAU / float(ray_count) * float(i)
		var start := center + Vector2.from_angle(angle) * radius * 1.15
		var end := center + Vector2.from_angle(angle) * radius * 1.8
		canvas.draw_line(start, end, ray_color, 2.5)


static func draw_moon(canvas: CanvasItem, center: Vector2, radius: float) -> void:
	# Moon glow
	canvas.draw_circle(center, radius * 1.4, Color(0.95, 0.95, 0.85, 0.1))
	canvas.draw_circle(center, radius, Color(0.95, 0.95, 0.85))
	# Crescent shadow
	canvas.draw_circle(center + Vector2(radius * 0.3, -radius * 0.1), radius * 0.85, Color("#0d1b3e"))
	# Craters
	canvas.draw_circle(center + Vector2(-radius * 0.2, radius * 0.15), radius * 0.08,
		Color(0.85, 0.85, 0.75, 0.4))
	canvas.draw_circle(center + Vector2(-radius * 0.35, -radius * 0.1), radius * 0.05,
		Color(0.85, 0.85, 0.75, 0.3))


static func draw_stars(canvas: CanvasItem, rect: Rect2, count: int,
		alpha: float = 0.8, seed_val: int = 42) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	for i in range(count):
		var pos := Vector2(
			rng.randf_range(rect.position.x, rect.end.x),
			rng.randf_range(rect.position.y, rect.end.y))
		var sz := rng.randf_range(1.0, 3.5)
		var a := alpha * rng.randf_range(0.4, 1.0)
		canvas.draw_circle(pos, sz, Color(1, 1, 0.9, a))
		# Twinkle cross on bright stars
		if sz > 2.5:
			var tc := Color(1, 1, 0.95, a * 0.5)
			canvas.draw_line(pos + Vector2(-sz * 1.5, 0), pos + Vector2(sz * 1.5, 0), tc, 0.5)
			canvas.draw_line(pos + Vector2(0, -sz * 1.5), pos + Vector2(0, sz * 1.5), tc, 0.5)


static func draw_grass_line(canvas: CanvasItem, start_x: float, end_x: float,
		y: float, color: Color, seed_val: int = 0) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val
	var x := start_x
	while x < end_x:
		var bh := rng.randf_range(8.0, 22.0)
		var lean := rng.randf_range(-5.0, 5.0)
		var blade_color := color.lerp(Color.WHITE, rng.randf_range(0.0, 0.08))
		canvas.draw_line(Vector2(x, y), Vector2(x + lean, y - bh), blade_color, 1.5)
		# Occasional double blade
		if rng.randf() > 0.7:
			canvas.draw_line(Vector2(x + 2, y), Vector2(x + lean + 3, y - bh * 0.8),
				blade_color.darkened(0.1), 1.0)
		x += rng.randf_range(3.0, 8.0)


static func draw_butterfly(canvas: CanvasItem, pos: Vector2, size: float,
		color: Color, time: float) -> void:
	var wing_flap := sin(time * 8.0) * 0.4 + 0.6
	# Body
	canvas.draw_line(pos + Vector2(0, -size), pos + Vector2(0, size), Color("#3d3929"), 1.5)
	# Wings
	var wing_w := size * 1.5 * wing_flap
	var wing_h := size * 1.2
	# Left wing
	canvas.draw_colored_polygon(PackedVector2Array([
		pos,
		pos + Vector2(-wing_w, -wing_h * 0.5),
		pos + Vector2(-wing_w * 0.8, wing_h * 0.3),
	]), color)
	# Right wing
	canvas.draw_colored_polygon(PackedVector2Array([
		pos,
		pos + Vector2(wing_w, -wing_h * 0.5),
		pos + Vector2(wing_w * 0.8, wing_h * 0.3),
	]), color)
	# Wing dots
	canvas.draw_circle(pos + Vector2(-wing_w * 0.5, -wing_h * 0.1), size * 0.2,
		color.lightened(0.3))
	canvas.draw_circle(pos + Vector2(wing_w * 0.5, -wing_h * 0.1), size * 0.2,
		color.lightened(0.3))


static func draw_path_segment(canvas: CanvasItem, start: Vector2, end: Vector2,
		width: float, color: Color) -> void:
	canvas.draw_colored_polygon(PackedVector2Array([
		start + Vector2(0, -width * 0.5),
		end + Vector2(0, -width * 0.5),
		end + Vector2(0, width * 0.5),
		start + Vector2(0, width * 0.5),
	]), color)


static func draw_water_stream(canvas: CanvasItem, start: Vector2,
		length: float, time: float, color: Color = Color("#7cafc2")) -> void:
	var points := PackedVector2Array()
	var x := 0.0
	while x <= length:
		var wave := sin((x + time * 100.0) * 0.05) * 5.0
		points.append(start + Vector2(x, wave))
		x += 8.0
	if points.size() >= 2:
		canvas.draw_polyline(points, color, 3.0)
		# Highlight wave
		var h_points := PackedVector2Array()
		x = 0.0
		while x <= length:
			var wave := sin((x + time * 100.0 + 20.0) * 0.05) * 3.0
			h_points.append(start + Vector2(x, wave - 3))
			x += 8.0
		if h_points.size() >= 2:
			canvas.draw_polyline(h_points, color.lightened(0.3), 1.5)
