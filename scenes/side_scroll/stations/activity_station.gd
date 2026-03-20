extends Node2D
## Activity station — SVG landmark sprites with procedural platform/glow/text.

signal station_tapped(station: Node2D)

var slot_id: String = ""
var card_data: Dictionary = {}
var is_active: bool = false
var is_completed: bool = false
var _pulse_time: float = 0.0
var _landmark: Sprite2D = null

var _station_textures := {
	"wk": preload("res://assets/stations/station_sunrise.svg"),
	"wp": preload("res://assets/stations/station_shower.svg"),
	"mp": preload("res://assets/stations/station_yoga.svg"),
	"tp": preload("res://assets/stations/station_meditation.svg"),
	"pl": preload("res://assets/stations/station_journal.svg"),
	"wl": preload("res://assets/stations/station_gate.svg"),
	"nc": preload("res://assets/stations/station_food_card.svg"),
	"dc": preload("res://assets/stations/station_water.svg"),
	"bf": preload("res://assets/stations/station_meal.svg"),
	"b2": preload("res://assets/stations/station_meal.svg"),
	"lu": preload("res://assets/stations/station_meal.svg"),
	"dn": preload("res://assets/stations/station_meal.svg"),
	"lc": preload("res://assets/stations/station_books.svg"),
	"ep": preload("res://assets/stations/station_candle.svg"),
	"bp": preload("res://assets/stations/station_bath.svg"),
	"gn": preload("res://assets/stations/station_bed.svg"),
}

# Meal accent colors for tinting
var _meal_tints := {
	"bf": Color("#f5e6b8"),
	"b2": Color("#c9886e"),
	"lu": Color("#8b7355"),
	"dn": Color("#5e8a3c"),
}


func setup(card: Dictionary) -> void:
	card_data = card
	slot_id = card.slot_id
	_load_landmark()


func _load_landmark() -> void:
	var tex: Texture2D = _station_textures.get(slot_id)
	if tex:
		_landmark = Sprite2D.new()
		_landmark.texture = tex
		_landmark.position = Vector2(0, -40)
		# Apply meal tinting if applicable
		if slot_id in _meal_tints:
			_landmark.modulate = _meal_tints[slot_id]
		add_child(_landmark)


func activate() -> void:
	is_active = true
	queue_redraw()


func mark_completed() -> void:
	is_completed = true
	is_active = false
	queue_redraw()


func _process(delta: float) -> void:
	if is_active or not is_completed:
		_pulse_time += delta
		queue_redraw()


func _draw() -> void:
	# Ground platform
	_draw_ellipse(Vector2.ZERO, 50, 12, ThemeManager.EARTHY_BROWN.lightened(0.1))
	_draw_ellipse(Vector2(0, -3), 48, 11, ThemeManager.EARTHY_BROWN.lightened(0.2))

	# Active glow ring
	if is_active:
		var pulse := 0.2 + sin(_pulse_time * 3.0) * 0.15
		_draw_ellipse(Vector2(0, -3), 58, 16, Color(ThemeManager.GOLDEN_AMBER.r,
			ThemeManager.GOLDEN_AMBER.g, ThemeManager.GOLDEN_AMBER.b, pulse))

	# Completed overlay
	if is_completed:
		draw_circle(Vector2(25, -65), 14, ThemeManager.DEEP_LEAF)
		draw_circle(Vector2(25, -65), 11, ThemeManager.DEEP_LEAF.lightened(0.15))
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(17, -58), "✓", HORIZONTAL_ALIGNMENT_LEFT, -1, ThemeManager.font_size(18), Color.WHITE)

	# Title below platform
	var title: String = card_data.get("title", "")
	if title.length() > 14:
		title = title.substr(0, 14) + "…"
	var title_font := ThemeDB.fallback_font
	draw_string(title_font, Vector2(-45, 25), title,
		HORIZONTAL_ALIGNMENT_CENTER, 90, ThemeManager.font_size(13), ThemeManager.TEXT_BROWN)

	# Time label
	var time_str: String = card_data.get("time", "")
	draw_string(title_font, Vector2(-20, 38), time_str,
		HORIZONTAL_ALIGNMENT_CENTER, 40, ThemeManager.font_size(11), ThemeManager.HINT_KHAKI)


func _draw_ellipse(center: Vector2, rx: float, ry: float, color: Color, seg: int = 20) -> void:
	var pts := PackedVector2Array()
	for i in range(seg + 1):
		var a := TAU * float(i) / float(seg)
		pts.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	draw_colored_polygon(pts, color)


func _input_event(_viewport: Viewport, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and is_active:
		station_tapped.emit(self)
