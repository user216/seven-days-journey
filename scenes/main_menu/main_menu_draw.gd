extends Control
## Procedural background drawing for main menu — mountains, trees, clouds, sun.
## This node has mouse_filter=IGNORE so it never blocks button input.

var mountains: Array[Dictionary] = []
var clouds: Array[Dictionary] = []
var trees: Array[Dictionary] = []
var anim_time: float = 0.0


func _process(delta: float) -> void:
	anim_time += delta
	for c in clouds:
		c.x += c.speed * delta
		if c.x > 1300:
			c.x = -250.0
	queue_redraw()


func _draw() -> void:
	for m in mountains:
		var c: Color = m.color
		c.a = m.alpha
		draw_colored_polygon(m.points, c)

	for t in trees:
		var trunk_c := Color("#8b7355")
		var leaf_c := Color("#5e8a3c") if t.dark else Color("#7da344")
		var tw: float = t.width * 0.12
		draw_rect(Rect2(t.x - tw, t.y - t.height * 0.4, tw * 2, t.height * 0.5), trunk_c)
		draw_circle(Vector2(t.x, t.y - t.height * 0.5), t.width * 0.5, leaf_c)
		draw_circle(Vector2(t.x, t.y - t.height * 0.7), t.width * 0.4, leaf_c.lightened(0.15))

	for c in clouds:
		var cc := Color(1, 1, 1, c.alpha)
		draw_circle(Vector2(c.x, c.y), c.rx * 0.6, cc)
		draw_circle(Vector2(c.x - c.rx * 0.3, c.y + 5), c.rx * 0.4, cc)
		draw_circle(Vector2(c.x + c.rx * 0.35, c.y + 3), c.rx * 0.45, cc)

	# Sun with rotating rays
	var sun_x := 540.0
	var sun_y := 250.0 + sin(anim_time * 0.3) * 20.0
	for i in range(5):
		var r := 120.0 - float(i) * 20.0
		var a := 0.04 + float(i) * 0.03
		draw_circle(Vector2(sun_x, sun_y), r, Color(0.83, 0.66, 0.26, a))
	draw_circle(Vector2(sun_x, sun_y), 50.0, Color(0.83, 0.66, 0.26, 0.85))
	draw_circle(Vector2(sun_x, sun_y), 36.0, Color(0.96, 0.9, 0.72, 0.5))
	for i in range(8):
		var angle := float(i) * PI / 4.0 + anim_time * 0.15
		var ray_start := Vector2(sun_x, sun_y) + Vector2(cos(angle), sin(angle)) * 55.0
		var ray_end := Vector2(sun_x, sun_y) + Vector2(cos(angle), sin(angle)) * 75.0
		draw_line(ray_start, ray_end, Color(0.83, 0.66, 0.26, 0.35), 2.5)
