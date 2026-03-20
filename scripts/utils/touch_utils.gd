class_name TouchUtils
## Touch/swipe/hold gesture detection helpers.

enum GestureType { TAP, SWIPE_LEFT, SWIPE_RIGHT, SWIPE_UP, SWIPE_DOWN, HOLD, CIRCLE }

const SWIPE_MIN_DISTANCE := 50.0
const HOLD_MIN_DURATION := 0.3
const CIRCLE_MIN_POINTS := 20
const CIRCLE_TOLERANCE := 0.3  # How circular the path must be (0-1)

var _touch_start: Vector2 = Vector2.ZERO
var _touch_start_time: float = 0.0
var _touch_path: PackedVector2Array = PackedVector2Array()
var _is_touching: bool = false


func on_touch_start(pos: Vector2, time: float) -> void:
	_touch_start = pos
	_touch_start_time = time
	_touch_path = PackedVector2Array([pos])
	_is_touching = true


func on_touch_move(pos: Vector2) -> void:
	if _is_touching:
		_touch_path.append(pos)


func on_touch_end(pos: Vector2, time: float) -> GestureType:
	_is_touching = false
	var duration := time - _touch_start_time
	var delta := pos - _touch_start
	var distance := delta.length()

	# Check for circle gesture
	if _touch_path.size() >= CIRCLE_MIN_POINTS and _is_circular():
		return GestureType.CIRCLE

	# Check for hold
	if distance < SWIPE_MIN_DISTANCE and duration >= HOLD_MIN_DURATION:
		return GestureType.HOLD

	# Check for swipe
	if distance >= SWIPE_MIN_DISTANCE:
		if absf(delta.x) > absf(delta.y):
			return GestureType.SWIPE_RIGHT if delta.x > 0 else GestureType.SWIPE_LEFT
		else:
			return GestureType.SWIPE_DOWN if delta.y > 0 else GestureType.SWIPE_UP

	return GestureType.TAP


func _is_circular() -> bool:
	if _touch_path.size() < CIRCLE_MIN_POINTS:
		return false

	# Find center of all points
	var center := Vector2.ZERO
	for p in _touch_path:
		center += p
	center /= float(_touch_path.size())

	# Check if all points are roughly equidistant from center
	var avg_radius := 0.0
	for p in _touch_path:
		avg_radius += center.distance_to(p)
	avg_radius /= float(_touch_path.size())

	if avg_radius < 20.0:
		return false

	var variance := 0.0
	for p in _touch_path:
		var diff := center.distance_to(p) - avg_radius
		variance += diff * diff
	variance /= float(_touch_path.size())

	return sqrt(variance) / avg_radius < CIRCLE_TOLERANCE


func get_hold_duration(current_time: float) -> float:
	if _is_touching:
		return current_time - _touch_start_time
	return 0.0


func get_swipe_velocity(end_pos: Vector2, end_time: float) -> Vector2:
	var duration := end_time - _touch_start_time
	if duration < 0.01:
		return Vector2.ZERO
	return (end_pos - _touch_start) / duration
