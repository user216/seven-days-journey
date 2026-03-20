extends Node2D
## Environment — uses SVG sprite assets for trees, bushes, flowers, butterflies.

var _time: float = 0.0
var _butterflies: Array[Dictionary] = []

var _tree_tall := [
	preload("res://assets/nature/tree_tall_01.svg"),
	preload("res://assets/nature/tree_tall_02.svg"),
]
var _tree_med := [
	preload("res://assets/nature/tree_medium_01.svg"),
	preload("res://assets/nature/tree_medium_02.svg"),
]
var _bush_tex := [
	preload("res://assets/nature/bush_01.svg"),
	preload("res://assets/nature/bush_02.svg"),
	preload("res://assets/nature/bush_flowering.svg"),
]
var _flower_tex := [
	preload("res://assets/nature/flower_5petal.svg"),
	preload("res://assets/nature/flower_4petal.svg"),
	preload("res://assets/nature/flower_tulip.svg"),
]
var _butterfly_tex: Texture2D = preload("res://assets/nature/butterfly.svg")
var _grass_tex: Texture2D = preload("res://assets/nature/grass_tuft.svg")


func _ready() -> void:
	z_index = -1
	_spawn_nature()


func _spawn_nature() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = GameState.current_day * 100

	# Distant trees
	for i in range(25):
		var x := float(i) * 350.0 + rng.randf_range(-60, 60)
		var spr := Sprite2D.new()
		spr.texture = _tree_tall[i % _tree_tall.size()]
		spr.position = Vector2(x, 720)
		spr.scale = Vector2(1.8, 1.8)
		spr.modulate = ThemeManager.DEEP_LEAF.lerp(ThemeManager.LIGHT_SAGE, rng.randf_range(0.0, 0.3))
		spr.z_index = -3
		add_child(spr)

	# Mid-ground trees
	for i in range(20):
		var x := float(i) * 400.0 + rng.randf_range(-40, 40) + 150
		var spr := Sprite2D.new()
		spr.texture = _tree_med[i % _tree_med.size()]
		spr.position = Vector2(x, 770)
		spr.scale = Vector2(1.5, 1.5)
		spr.modulate = ThemeManager.SAGE_GREEN
		spr.z_index = -2
		add_child(spr)

	# Bushes
	for i in range(35):
		var x := float(i) * 230.0 + rng.randf_range(-30, 30)
		var spr := Sprite2D.new()
		spr.texture = _bush_tex[i % _bush_tex.size()]
		spr.position = Vector2(x, 800)
		var bush_scale := rng.randf_range(0.8, 1.4)
		spr.scale = Vector2(bush_scale, bush_scale)
		spr.z_index = -1
		add_child(spr)

	# Flowers
	var flower_colors := [ThemeManager.TERRACOTTA, ThemeManager.GOLDEN_AMBER,
		Color.MEDIUM_PURPLE, Color.LIGHT_PINK, ThemeManager.SOFT_TEAL,
		Color("#e8a0c0"), Color("#c0b0e0")]
	for i in range(50):
		var x := float(i) * 160.0 + rng.randf_range(-25, 25)
		var y := 810.0 + rng.randf_range(-8, 8)
		var spr := Sprite2D.new()
		spr.texture = _flower_tex[i % _flower_tex.size()]
		spr.position = Vector2(x, y)
		var fs := rng.randf_range(0.6, 1.2)
		spr.scale = Vector2(fs, fs)
		spr.modulate = flower_colors[i % flower_colors.size()]
		add_child(spr)

	# Grass tufts
	for i in range(200):
		var x := float(i) * 42.0 + rng.randf_range(-5, 5) - 100
		var spr := Sprite2D.new()
		spr.texture = _grass_tex
		spr.position = Vector2(x, 798 + rng.randf_range(-4, 4))
		var gs := rng.randf_range(0.5, 1.0)
		spr.scale = Vector2(gs, gs)
		spr.modulate = ThemeManager.DEEP_LEAF.lerp(ThemeManager.SAGE_GREEN, rng.randf())
		add_child(spr)

	# Butterflies (animated)
	var butterfly_colors := [Color("#e8a0c0"), ThemeManager.GOLDEN_AMBER, ThemeManager.SOFT_TEAL]
	for i in range(8):
		var base_x := float(i) * 1000.0 + 300
		var spr := Sprite2D.new()
		spr.texture = _butterfly_tex
		spr.position = Vector2(base_x, 680)
		spr.scale = Vector2(1.5, 1.5)
		spr.modulate = butterfly_colors[i % butterfly_colors.size()]
		add_child(spr)
		_butterflies.append({"sprite": spr, "base_x": base_x, "index": i})


func _process(delta: float) -> void:
	_time += delta
	for b in _butterflies:
		var spr: Sprite2D = b.sprite
		var i: int = b.index
		var bx: float = b.base_x
		spr.position.x = bx + sin(_time * 0.5 + float(i)) * 60.0
		spr.position.y = 680 + sin(_time * 0.8 + float(i) * 2.0) * 40.0
		spr.scale.x = 1.5 * (0.6 + sin(_time * 8.0 + float(i)) * 0.4)
