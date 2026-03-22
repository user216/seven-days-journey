extends Node
## Real-time clock — activities locked until their time arrives (default).
## Developer mode: all past activities immediately available.

signal time_changed(real_time_minutes: float)
signal activity_time_reached(slot_id: String, card: Dictionary)
signal day_ended()

# ── State ─────────────────────────────────────────────────────────

var paused: bool = false
var _triggered_slots: Dictionary = {}  # slot_id -> true
var _current_day_cards: Array[Dictionary] = []
var _time_windows: Dictionary = {}  # slot_id -> {start: float, end: float}
var _last_checked_minute: int = -1
var _check_timer: float = 0.0
var _day_ended_fired: bool = false
var _day_start_time: float = 0.0

const DAY_END_GRACE_SECONDS := 60.0

const MIN_WINDOW_MINUTES := 10.0

# ── Lifecycle ─────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if paused:
		return
	_check_timer += delta
	if _check_timer < 1.0:
		return
	_check_timer = 0.0

	var now := _get_real_minutes()
	var current_minute := int(now)
	if current_minute == _last_checked_minute:
		return
	_last_checked_minute = current_minute
	time_changed.emit(now)

	# Trigger newly-arrived activities
	for card in _current_day_cards:
		var card_minutes: float = GameData.time_to_minutes(card.time)
		if now >= card_minutes and card.slot_id not in _triggered_slots:
			_triggered_slots[card.slot_id] = true
			activity_time_reached.emit(card.slot_id, card)

	var elapsed := Time.get_ticks_msec() / 1000.0 - _day_start_time
	if now >= 1320.0 and not _day_ended_fired and not GameState.developer_mode and elapsed >= DAY_END_GRACE_SECONDS:
		_day_ended_fired = true
		day_ended.emit()


# ── Public API ────────────────────────────────────────────────────

func start_day(day_num: int) -> void:
	_triggered_slots = {}
	_current_day_cards = GameData.get_all_cards_for_day(day_num)
	_compute_time_windows()
	_last_checked_minute = -1
	_day_ended_fired = false
	_day_start_time = Time.get_ticks_msec() / 1000.0
	paused = false

	var now := _get_real_minutes()
	for card in _current_day_cards:
		var card_minutes: float = GameData.time_to_minutes(card.time)
		if now >= card_minutes:
			_triggered_slots[card.slot_id] = true
			activity_time_reached.emit(card.slot_id, card)


func get_activity_state(slot_id: String) -> String:
	## Returns: "completed", "current", "available_late", "locked"
	## In normal mode: current = in window, available_late = past window, locked = future
	## In dev mode: current = past time, locked = future
	if GameState.is_activity_completed(GameState.current_day, slot_id):
		return "completed"
	if GameState.developer_mode:
		if slot_id in _triggered_slots:
			return "current"
		return "locked"
	var window: Dictionary = _time_windows.get(slot_id, {})
	if not window:
		return "locked"
	var now := _get_real_minutes()
	if now < window.start:
		return "locked"
	elif now < window.end:
		return "current"
	else:
		# Past window — still tappable but shown as "late"
		return "available_late"


func pause() -> void:
	paused = true


func resume() -> void:
	paused = false
	_last_checked_minute = -1


func get_time_string() -> String:
	var dict := Time.get_time_dict_from_system()
	return "%02d:%02d" % [dict.hour, dict.minute]


func get_time_of_day_factor() -> float:
	var now := _get_real_minutes()
	return clampf((now - 270.0) / 1050.0, 0.0, 1.0)


func get_next_activity() -> Dictionary:
	var now := _get_real_minutes()
	for card in _current_day_cards:
		var card_minutes: float = GameData.time_to_minutes(card.time)
		if now < card_minutes:
			return card
	return {}


func get_current_phase() -> String:
	var now := _get_real_minutes()
	if now < 300.0: return "night"
	elif now < 360.0: return "dawn"
	elif now < 480.0: return "morning"
	elif now < 720.0: return "day"
	elif now < 1020.0: return "afternoon"
	elif now < 1200.0: return "evening"
	else: return "night"


func is_activity_triggered(slot_id: String) -> bool:
	return slot_id in _triggered_slots


func is_activity_available_now(slot_id: String) -> bool:
	var state := get_activity_state(slot_id)
	return state == "current" or state == "available_late"


func get_real_minutes() -> float:
	return _get_real_minutes()


# ── Internal ──────────────────────────────────────────────────────

func _compute_time_windows() -> void:
	_time_windows.clear()
	var sorted_times: Array[float] = []
	var time_to_slots: Dictionary = {}  # float -> Array of slot_ids

	for card in _current_day_cards:
		var t: float = GameData.time_to_minutes(card.time)
		if t not in time_to_slots:
			time_to_slots[t] = []
			sorted_times.append(t)
		time_to_slots[t].append(card.slot_id)

	sorted_times.sort()

	for idx in range(sorted_times.size()):
		var start_t: float = sorted_times[idx]
		var end_t: float
		if idx + 1 < sorted_times.size():
			end_t = sorted_times[idx + 1]
		else:
			end_t = 1440.0  # midnight for last activity
		# Enforce minimum window
		if end_t - start_t < MIN_WINDOW_MINUTES:
			end_t = start_t + MIN_WINDOW_MINUTES
		for slot_id in time_to_slots[start_t]:
			_time_windows[slot_id] = {"start": start_t, "end": end_t}


func _get_real_minutes() -> float:
	var dict := Time.get_time_dict_from_system()
	return float(dict.hour) * 60.0 + float(dict.minute) + float(dict.second) / 60.0
