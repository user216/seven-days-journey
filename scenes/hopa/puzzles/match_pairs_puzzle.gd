extends HopaPuzzleBase
## Memory card match — find matching pairs of wellness symbols.

var _cards: Array[Dictionary] = []
var _first_flipped: int = -1
var _second_flipped: int = -1
var _matched_count: int = 0
var _total_pairs: int = 6
var _checking: bool = false

const GRID_COLS := 4
const GRID_ROWS := 3
const FLIP_DELAY := 1.0

# Wellness symbol pairs
const SYMBOLS: Array[Dictionary] = [
	{"name": "Лотос", "color": Color(0.85, 0.4, 0.6), "shape": "flower"},
	{"name": "Солнце", "color": Color(0.85, 0.65, 0.15), "shape": "sun"},
	{"name": "Вода", "color": Color(0.3, 0.6, 0.9), "shape": "drop"},
	{"name": "Лист", "color": Color(0.35, 0.7, 0.3), "shape": "leaf"},
	{"name": "Звезда", "color": Color(0.7, 0.6, 0.85), "shape": "star"},
	{"name": "Сердце", "color": Color(0.85, 0.3, 0.35), "shape": "heart"},
	{"name": "Луна", "color": Color(0.75, 0.78, 0.85), "shape": "moon"},
	{"name": "Огонь", "color": Color(0.9, 0.5, 0.15), "shape": "fire"},
]


func _setup() -> void:
	duration = 120.0
	_total_pairs = mini(puzzle_data.get("pairs", 6), GRID_COLS * GRID_ROWS / 2)
	_create_cards()


func _create_cards() -> void:
	var card_w := size.x * 0.2
	var card_h := size.y * 0.22
	var start_x := (size.x - card_w * GRID_COLS - 20 * (GRID_COLS - 1)) * 0.5
	var start_y := size.y * 0.15

	# Create pairs
	var symbols_pool: Array = []
	for i in range(_total_pairs):
		var sym: Dictionary = SYMBOLS[i % SYMBOLS.size()]
		symbols_pool.append(sym)
		symbols_pool.append(sym)

	# Shuffle
	var rng := RandomNumberGenerator.new()
	rng.randomize()
	for i in range(symbols_pool.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var temp = symbols_pool[i]
		symbols_pool[i] = symbols_pool[j]
		symbols_pool[j] = temp

	for i in range(symbols_pool.size()):
		var row := i / GRID_COLS
		var col := i % GRID_COLS
		var rect := Rect2(
			start_x + col * (card_w + 20),
			start_y + row * (card_h + 20),
			card_w, card_h
		)
		_cards.append({
			"rect": rect,
			"symbol": symbols_pool[i],
			"face_up": false,
			"matched": false,
		})


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), ThemeManager.MINT_SAGE)

	var font := ThemeDB.fallback_font

	# Title
	if _matched_count == 0:
		draw_string(font, Vector2(size.x * 0.5 - 100, size.y * 0.08),
			"Найди пары",
			HORIZONTAL_ALIGNMENT_CENTER, 200, ThemeManager.font_size(20), ThemeManager.TEXT_BROWN)

	# Draw cards
	for i in range(_cards.size()):
		var card: Dictionary = _cards[i]
		var r: Rect2 = card.rect

		if card.matched:
			# Matched: green outline, faded
			draw_rect(r, Color(ThemeManager.SAGE_GREEN, 0.3), true)
			draw_rect(r, ThemeManager.SAGE_GREEN, false, 2.0)
			_draw_symbol(r.get_center(), card.symbol, 0.5)
		elif card.face_up:
			# Face up: show symbol
			draw_rect(r, ThemeManager.BG_CREAM, true)
			draw_rect(r, ThemeManager.GOLDEN_AMBER, false, 2.0)
			_draw_symbol(r.get_center(), card.symbol, 1.0)
		else:
			# Face down: card back
			draw_rect(r, ThemeManager.EARTHY_BROWN, true)
			draw_rect(r, ThemeManager.GOLDEN_AMBER, false, 1.5)
			# Decorative pattern
			draw_circle(r.get_center(), 15.0, Color(ThemeManager.GOLDEN_AMBER, 0.4))

	# Counter
	draw_string(font, Vector2(size.x * 0.5 - 40, size.y - 30),
		"%d / %d" % [_matched_count, _total_pairs],
		HORIZONTAL_ALIGNMENT_CENTER, -1, ThemeManager.font_size(28), ThemeManager.TEXT_BROWN)


func _draw_symbol(center: Vector2, sym: Dictionary, alpha: float) -> void:
	var c := Color(sym.color, alpha)
	var r := 22.0

	match sym.shape:
		"flower":
			for ang in range(0, 360, 60):
				var rad := deg_to_rad(float(ang))
				var petal := center + Vector2(cos(rad), sin(rad)) * 14.0
				draw_circle(petal, 8.0, c.lightened(0.2))
			draw_circle(center, 8.0, c)
		"sun":
			draw_circle(center, 14.0, c)
			for ang in range(0, 360, 45):
				var rad := deg_to_rad(float(ang))
				draw_line(center + Vector2(cos(rad), sin(rad)) * 16.0,
					center + Vector2(cos(rad), sin(rad)) * 24.0, c, 2.5)
		"drop":
			var pts := PackedVector2Array([
				center + Vector2(0, -r),
				center + Vector2(12, 6),
				center + Vector2(0, r),
				center + Vector2(-12, 6),
			])
			draw_colored_polygon(pts, c)
		"leaf":
			var pts := PackedVector2Array([
				center + Vector2(0, -r),
				center + Vector2(16, 0),
				center + Vector2(0, r),
				center + Vector2(-16, 0),
			])
			draw_colored_polygon(pts, c)
			draw_line(center + Vector2(0, -16), center + Vector2(0, 16), c.darkened(0.2), 2.0)
		"star":
			for i in range(5):
				var ang := deg_to_rad(float(i) * 72.0 - 90.0)
				var tip := center + Vector2(cos(ang), sin(ang)) * r
				var ang2 := deg_to_rad(float(i) * 72.0 - 90.0 + 36.0)
				var inner := center + Vector2(cos(ang2), sin(ang2)) * (r * 0.4)
				draw_line(center, tip, c, 3.0)
				draw_line(tip, inner, c, 2.0)
		"heart":
			draw_circle(center + Vector2(-8, -4), 10.0, c)
			draw_circle(center + Vector2(8, -4), 10.0, c)
			var pts := PackedVector2Array([
				center + Vector2(-16, 0),
				center + Vector2(0, 18),
				center + Vector2(16, 0),
			])
			draw_colored_polygon(pts, c)
		"moon":
			draw_circle(center, 16.0, c)
			draw_circle(center + Vector2(8, -4), 12.0, ThemeManager.MINT_SAGE)
		"fire":
			var pts := PackedVector2Array([
				center + Vector2(-10, 10),
				center + Vector2(0, -r),
				center + Vector2(10, 10),
			])
			draw_colored_polygon(pts, c)
			draw_circle(center + Vector2(0, 4), 8.0, c.lightened(0.3))


func _gui_input(event: InputEvent) -> void:
	if not is_active or _checking:
		return

	if event is InputEventMouseButton and event.pressed:
		for i in range(_cards.size()):
			var card: Dictionary = _cards[i]
			if card.matched or card.face_up:
				continue
			if card.rect.has_point(event.position):
				card.face_up = true
				queue_redraw()

				if _first_flipped < 0:
					_first_flipped = i
				else:
					_second_flipped = i
					_checking = true
					_check_match()
				break


func _check_match() -> void:
	var c1: Dictionary = _cards[_first_flipped]
	var c2: Dictionary = _cards[_second_flipped]

	if c1.symbol.name == c2.symbol.name:
		# Match!
		c1.matched = true
		c2.matched = true
		_matched_count += 1
		_first_flipped = -1
		_second_flipped = -1
		_checking = false
		queue_redraw()

		if _matched_count >= _total_pairs:
			complete_interaction()
	else:
		# No match — flip back after delay
		var tween := create_tween()
		tween.tween_interval(FLIP_DELAY)
		tween.tween_callback(func():
			c1.face_up = false
			c2.face_up = false
			_first_flipped = -1
			_second_flipped = -1
			_checking = false
			queue_redraw()
		)
