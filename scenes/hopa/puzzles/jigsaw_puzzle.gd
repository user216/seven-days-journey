extends HopaPuzzleBase
## Jigsaw puzzle — split image into NxN grid, drag pieces to correct positions.

var _grid_cols: int = 3
var _grid_rows: int = 3
var _pieces: Array[Dictionary] = []
var _dragging_idx: int = -1
var _drag_offset: Vector2 = Vector2.ZERO
var _snapped_count: int = 0
var _total_pieces: int = 9

const SNAP_THRESHOLD := 40.0


func _setup() -> void:
	duration = 120.0
	var pieces_count: int = puzzle_data.get("pieces", 9)

	if pieces_count == 16:
		_grid_cols = 4
		_grid_rows = 4
	else:
		_grid_cols = 3
		_grid_rows = 3

	_total_pieces = _grid_cols * _grid_rows
	_create_pieces()


func _create_pieces() -> void:
	var puzzle_area := Rect2(
		size.x * 0.1, size.y * 0.15,
		size.x * 0.8, size.x * 0.8  # Square puzzle area
	)
	var piece_w := puzzle_area.size.x / float(_grid_cols)
	var piece_h := puzzle_area.size.y / float(_grid_rows)

	var rng := RandomNumberGenerator.new()
	rng.randomize()

	for row in range(_grid_rows):
		for col in range(_grid_cols):
			var idx := row * _grid_cols + col
			var target_pos := Vector2(
				puzzle_area.position.x + col * piece_w + piece_w * 0.5,
				puzzle_area.position.y + row * piece_h + piece_h * 0.5
			)
			# Start position: scattered around the bottom
			var start_pos := Vector2(
				rng.randf_range(size.x * 0.1, size.x * 0.9),
				rng.randf_range(size.y * 0.6, size.y * 0.9)
			)
			# Assign a distinct color per piece based on grid position
			var hue := float(idx) / float(_total_pieces)
			var color := Color.from_hsv(hue, 0.5, 0.8)

			_pieces.append({
				"idx": idx,
				"row": row,
				"col": col,
				"pos": start_pos,
				"target": target_pos,
				"size": Vector2(piece_w - 4, piece_h - 4),
				"snapped": false,
				"color": color,
			})


func _draw() -> void:
	# Background
	draw_rect(Rect2(Vector2.ZERO, size), ThemeManager.MINT_SAGE)

	# Title
	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(size.x * 0.5 - 100, size.y * 0.08),
		"Собери картинку",
		HORIZONTAL_ALIGNMENT_CENTER, 200, ThemeManager.font_size(20), ThemeManager.TEXT_BROWN)

	# Grid lines (target positions)
	var puzzle_area := Rect2(
		size.x * 0.1, size.y * 0.15,
		size.x * 0.8, size.x * 0.8
	)
	var grid_color := Color(ThemeManager.SAGE_GREEN, 0.3)
	var piece_w := puzzle_area.size.x / float(_grid_cols)
	var piece_h := puzzle_area.size.y / float(_grid_rows)

	# Grid outline
	draw_rect(puzzle_area, grid_color, false, 2.0)
	for i in range(1, _grid_cols):
		var x := puzzle_area.position.x + i * piece_w
		draw_line(Vector2(x, puzzle_area.position.y), Vector2(x, puzzle_area.end.y), grid_color, 1.5)
	for i in range(1, _grid_rows):
		var y := puzzle_area.position.y + i * piece_h
		draw_line(Vector2(puzzle_area.position.x, y), Vector2(puzzle_area.end.x, y), grid_color, 1.5)

	# Draw pieces (non-dragged first, then dragged on top)
	for i in range(_pieces.size()):
		if i != _dragging_idx:
			_draw_piece(i)
	if _dragging_idx >= 0:
		_draw_piece(_dragging_idx)

	# Counter
	draw_string(font, Vector2(size.x * 0.5 - 40, size.y - 30),
		"%d / %d" % [_snapped_count, _total_pieces],
		HORIZONTAL_ALIGNMENT_CENTER, -1, ThemeManager.font_size(28), ThemeManager.TEXT_BROWN)


func _draw_piece(idx: int) -> void:
	var p: Dictionary = _pieces[idx]
	var r := Rect2(p.pos - p.size * 0.5, p.size)
	var c: Color = p.color

	if p.snapped:
		c = c.lightened(0.2)
		# Draw with check mark overlay
		draw_rect(r, c, true)
		draw_rect(r, ThemeManager.SAGE_GREEN, false, 2.0)
	else:
		draw_rect(r, c, true)
		draw_rect(r, ThemeManager.EARTHY_BROWN, false, 1.5)

	# Number label
	var font := ThemeDB.fallback_font
	draw_string(font, p.pos + Vector2(-8, 6), str(p.idx + 1),
		HORIZONTAL_ALIGNMENT_CENTER, 20, ThemeManager.font_size(16), ThemeManager.TEXT_BROWN)


func _gui_input(event: InputEvent) -> void:
	if not is_active:
		return

	if event is InputEventMouseButton:
		if event.pressed:
			# Find topmost non-snapped piece under tap
			for i in range(_pieces.size() - 1, -1, -1):
				if _pieces[i].snapped:
					continue
				var p: Dictionary = _pieces[i]
				var r := Rect2(p.pos - p.size * 0.5, p.size)
				if r.has_point(event.position):
					_dragging_idx = i
					_drag_offset = p.pos - event.position
					break
		else:
			if _dragging_idx >= 0:
				_try_snap(_dragging_idx)
				_dragging_idx = -1
				queue_redraw()

	elif event is InputEventMouseMotion and _dragging_idx >= 0:
		_pieces[_dragging_idx].pos = event.position + _drag_offset
		queue_redraw()


func _try_snap(idx: int) -> void:
	var p: Dictionary = _pieces[idx]
	if p.pos.distance_to(p.target) <= SNAP_THRESHOLD:
		p.pos = p.target
		p.snapped = true
		_snapped_count += 1
		if _snapped_count >= _total_pieces:
			complete_interaction()
