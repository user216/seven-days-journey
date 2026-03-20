extends Node2D
## Sky layer — gradient background with SVG sun/moon/cloud sprites.

var _sun: Sprite2D
var _moon: Sprite2D
var _clouds: Array[Sprite2D] = []

var _sun_tex: Texture2D = preload("res://assets/nature/sun.svg")
var _moon_tex: Texture2D = preload("res://assets/nature/moon_crescent.svg")
var _cloud_textures := [
	preload("res://assets/nature/cloud_large.svg"),
	preload("res://assets/nature/cloud_medium.svg"),
	preload("res://assets/nature/cloud_small.svg"),
]


func _ready() -> void:
	# Sun sprite
	_sun = Sprite2D.new()
	_sun.texture = _sun_tex
	_sun.scale = Vector2(1.5, 1.5)
	add_child(_sun)

	# Moon sprite
	_moon = Sprite2D.new()
	_moon.texture = _moon_tex
	_moon.scale = Vector2(1.2, 1.2)
	add_child(_moon)

	# Cloud sprites
	var cloud_positions := [Vector2(800, 150), Vector2(2500, 180), Vector2(4200, 130), Vector2(6000, 200)]
	var cloud_scales := [2.0, 1.8, 1.5, 2.0]
	var cloud_alphas := [0.5, 0.4, 0.45, 0.35]
	for i in range(4):
		var c := Sprite2D.new()
		c.texture = _cloud_textures[i % _cloud_textures.size()]
		c.position = cloud_positions[i]
		c.scale = Vector2(cloud_scales[i], cloud_scales[i])
		c.modulate.a = cloud_alphas[i]
		add_child(c)
		_clouds.append(c)


func _process(_delta: float) -> void:
	var tf := TimeSystem.get_time_of_day_factor()

	# Sun/moon visibility and position
	if tf < 0.1 or tf > 0.9:
		_sun.visible = false
		_moon.visible = true
		_moon.position = Vector2(400, 200)
	elif tf < 0.85:
		_sun.visible = true
		_moon.visible = false
		var sun_arc_t := (tf - 0.1) / 0.75
		_sun.position.x = lerpf(200, 7000, sun_arc_t)
		_sun.position.y = 300 - sin(sun_arc_t * PI) * 200
	else:
		_sun.visible = false
		_moon.visible = false

	queue_redraw()


func _draw() -> void:
	var tf := TimeSystem.get_time_of_day_factor()
	var colors: Array = ThemeManager.get_sky_colors(tf)
	var top: Color = colors[0]
	var bottom: Color = colors[1]

	# Sky gradient (stays procedural — dynamic interpolation)
	draw_rect(Rect2(-2000, -2000, 12000, 2800), top)
	draw_rect(Rect2(-2000, 300, 12000, 600), bottom)

	# Stars at night (procedural — random dots)
	if tf < 0.1 or tf > 0.9:
		ProceduralDrawing.draw_stars(self, Rect2(-1000, -500, 10000, 600), 40, 0.6)
