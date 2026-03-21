extends HopaPuzzleBase
## Connect runes — draw lines between matching symbol pairs on left/right columns.

var _runes_left: Array[Dictionary] = []
var _runes_right: Array[Dictionary] = []
var _connections: Array[Dictionary] = []   # {"left": int, "right": int, "correct": bool}
var _drawing_from: int = -1                # index in left column, or -1
var _draw_end: Vector2 = Vector2.ZERO
var _matched_count: int = 0
var _total_pairs: int = 4

const RUNE_RADIUS := 40.0

# Rune symbols to match
const RUNE_DEFS: Array[Dictionary] = [
	{"name": "Земля", "color": Color(0.55, 0.4, 0.25), "glyph": "earth"},
	{"name": "Вода", "color": Color(0.3, 0.55, 0.85), "glyph": "water"},
	{"name": "Огонь", "color": Color(0.85, 0.4, 0.15), "glyph": "fire"},
	{"name": "Воздух", "color": Color(0.6, 0.75, 0.85), "glyph": "air"},
	{"name": "Дух", "color": Color(0.7, 0.55, 0.85), "glyph": "spirit"},
]


func _setup() -> void:
	duration = 120.0
	_total_pairs = mini(puzzle_data.get("pairs", 4), RUNE_DEFS.size())
	_create_runes()


func _create_runes() -> void:
	var left_x := size.x * 0.18
	var right_x := size.x * 0.82
	var start_y := size.y * 0.2
	var spacing := (size.y * 0.6) / float(_total_pairs)

	# Select runes and create pairs
	var selected: Array = []
	for i in range(_total_pairs):
		selected.append(RUNE_DEFS[i % RUNE_DEFS.size()])

	# Left column: in order
	for i in range(_total_pairs):
		_runes_left.append({
			"pos": Vector2(left_x, start_y + i * spacing),
			"rune": selected[i],
			"connected": false,
		})

	# Right column: shuffled
	var shuffled := selected.duplicate()
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(shuffled.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var temp = shuffled[i]
		shuffled[i] = shuffled[j]
		shuffled[j] = temp

	for i in range(_total_pairs):
		_runes_right.append({
			"pos": Vector2(right_x, start_y + i * spacing),
			"rune": shuffled[i],
			"connected": false,
		})


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), ThemeManager.MINT_SAGE)

	var font := ThemeDB.fallback_font

	# Title
	draw_string(font, Vector2(size.x * 0.5 - 100, size.y * 0.08),
		"Соедини пары",
		HORIZONTAL_ALIGNMENT_CENTER, 200, ThemeManager.font_size(20), ThemeManager.TEXT_BROWN)

	# Draw completed connections
	for conn in _connections:
		var from: Vector2 = _runes_left[conn.left].pos
		var to: Vector2 = _runes_right[conn.right].pos
		var color: Color = ThemeManager.SAGE_GREEN if conn.correct else Color(ThemeManager.WARM_DANGER, 0.4)
		draw_line(from, to, color, 3.0)

	# Draw active line being drawn
	if _drawing_from >= 0:
		draw_line(_runes_left[_drawing_from].pos, _draw_end, Color(ThemeManager.GOLDEN_AMBER, 0.6), 2.5)

	# Draw left runes
	for i in range(_runes_left.size()):
		_draw_rune(_runes_left[i], i == _drawing_from)

	# Draw right runes
	for i in range(_runes_right.size()):
		_draw_rune(_runes_right[i], false)

	# Counter
	draw_string(font, Vector2(size.x * 0.5 - 40, size.y - 30),
		"%d / %d" % [_matched_count, _total_pairs],
		HORIZONTAL_ALIGNMENT_CENTER, -1, ThemeManager.font_size(28), ThemeManager.TEXT_BROWN)


func _draw_rune(rune_data: Dictionary, highlighted: bool) -> void:
	var pos: Vector2 = rune_data.pos
	var r: Dictionary = rune_data.rune
	var c: Color = r.color

	# Circle background
	if rune_data.connected:
		draw_circle(pos, RUNE_RADIUS, Color(ThemeManager.SAGE_GREEN, 0.3))
	elif highlighted:
		draw_circle(pos, RUNE_RADIUS + 4, Color(ThemeManager.GOLDEN_AMBER, 0.4))
		draw_circle(pos, RUNE_RADIUS, ThemeManager.BG_CREAM)
	else:
		draw_circle(pos, RUNE_RADIUS, ThemeManager.BG_CREAM)

	draw_arc(pos, RUNE_RADIUS, 0, TAU, 32, c, 2.0)

	# Simple glyph
	match r.glyph:
		"earth":
			draw_rect(Rect2(pos - Vector2(12, 12), Vector2(24, 24)), c, false, 2.5)
			draw_line(pos + Vector2(-8, 0), pos + Vector2(8, 0), c, 2.0)
		"water":
			draw_line(pos + Vector2(-12, -8), pos + Vector2(0, 10), c, 2.5)
			draw_line(pos + Vector2(0, 10), pos + Vector2(12, -8), c, 2.5)
			draw_line(pos + Vector2(-8, 0), pos + Vector2(8, 0), c, 2.0)
		"fire":
			draw_line(pos + Vector2(-10, 10), pos + Vector2(0, -12), c, 2.5)
			draw_line(pos + Vector2(0, -12), pos + Vector2(10, 10), c, 2.5)
			draw_line(pos + Vector2(-10, 10), pos + Vector2(10, 10), c, 2.0)
		"air":
			draw_arc(pos + Vector2(0, 4), 10.0, PI, TAU, 16, c, 2.5)
			draw_line(pos + Vector2(-12, 4), pos + Vector2(12, 4), c, 2.0)
		"spirit":
			draw_circle(pos, 10.0, Color(c, 0.5))
			draw_arc(pos, 12.0, 0, TAU, 32, c, 2.0)
			draw_circle(pos, 4.0, c)

	# Label
	var font := ThemeDB.fallback_font
	draw_string(font, pos + Vector2(-25, RUNE_RADIUS + 18), r.name,
		HORIZONTAL_ALIGNMENT_CENTER, 50, ThemeManager.font_size(12), ThemeManager.TEXT_BROWN)


func _gui_input(event: InputEvent) -> void:
	if not is_active:
		return

	if event is InputEventMouseButton:
		if event.pressed:
			# Check if tapping a left rune to start drawing
			for i in range(_runes_left.size()):
				if _runes_left[i].connected:
					continue
				if event.position.distance_to(_runes_left[i].pos) <= RUNE_RADIUS:
					_drawing_from = i
					_draw_end = event.position
					queue_redraw()
					break
		else:
			# Release — check if landed on a right rune
			if _drawing_from >= 0:
				for i in range(_runes_right.size()):
					if _runes_right[i].connected:
						continue
					if event.position.distance_to(_runes_right[i].pos) <= RUNE_RADIUS:
						_try_connect(_drawing_from, i)
						break
				_drawing_from = -1
				queue_redraw()

	elif event is InputEventMouseMotion and _drawing_from >= 0:
		_draw_end = event.position
		queue_redraw()


func _try_connect(left_idx: int, right_idx: int) -> void:
	var left_rune: Dictionary = _runes_left[left_idx].rune
	var right_rune: Dictionary = _runes_right[right_idx].rune
	var correct: bool = left_rune.name == right_rune.name

	if correct:
		_runes_left[left_idx].connected = true
		_runes_right[right_idx].connected = true
		_connections.append({"left": left_idx, "right": right_idx, "correct": true})
		_matched_count += 1

		if _matched_count >= _total_pairs:
			complete_interaction()
	else:
		# Wrong — show red line briefly then remove
		_connections.append({"left": left_idx, "right": right_idx, "correct": false})
		queue_redraw()
		var tween := create_tween()
		tween.tween_interval(0.8)
		tween.tween_callback(func():
			# Remove last wrong connection
			for j in range(_connections.size() - 1, -1, -1):
				if not _connections[j].correct:
					_connections.remove_at(j)
					break
			queue_redraw()
		)
