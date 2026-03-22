extends Node
## HTTP sync with bot's gamification API — hybrid data source.
## Fetches real user progress when available, falls back to local GameState.

signal sync_completed(data: Dictionary)
signal sync_failed(error: String)

# ── Config ───────────────────────────────────────────────────────

const DEFAULT_API_URL := "https://7daysjourney.duckdns.org"
const TIMEOUT := 10.0

var _base_url: String = ""
var _user_id: String = ""
var _http: HTTPRequest


func _ready() -> void:
	_base_url = _get_base_url()
	_http = HTTPRequest.new()
	_http.timeout = TIMEOUT
	add_child(_http)


# ── Public API ───────────────────────────────────────────────────

func set_user_id(uid: String) -> void:
	_user_id = uid


func fetch_progress() -> void:
	## Fetch gamification data from bot API. Emits sync_completed or sync_failed.
	if _user_id.is_empty():
		sync_failed.emit("no_user_id")
		return

	var url := "%s/api/miniapp/gamification?user_id=%s" % [_base_url, _user_id]
	_http.request_completed.connect(_on_fetch_completed, CONNECT_ONE_SHOT)
	var err := _http.request(url)
	if err != OK:
		sync_failed.emit("request_error_%d" % err)


func post_water() -> void:
	## Post water intake to bot API (fire-and-forget).
	if _user_id.is_empty():
		return
	var url := "%s/api/miniapp/water?user_id=%s" % [_base_url, _user_id]
	var body := JSON.stringify({"action": "add"})
	_http.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)


func post_breathing(duration_seconds: int) -> void:
	## Post breathing session to bot API (fire-and-forget).
	if _user_id.is_empty():
		return
	var url := "%s/api/miniapp/breathing?user_id=%s" % [_base_url, _user_id]
	var body := JSON.stringify({"duration_seconds": duration_seconds})
	_http.request(url, ["Content-Type: application/json"], HTTPClient.METHOD_POST, body)


func get_local_progress() -> Dictionary:
	## Build progress data from local GameState (offline fallback).
	var xp_data := GameState.calculate_xp()
	return {
		"source": "local",
		"xp": xp_data.total,
		"level": xp_data.level,
		"level_name": xp_data.level_name,
		"day": GameState.current_day,
		"daily_score": GameState.get_daily_score(GameState.current_day),
		"weekly_score": GameState.get_weekly_score(),
		"streak": GameState.streak_current,
		"best_streak": GameState.streak_best,
		"achievements": GameState.achievements_earned.duplicate(),
		"water_glasses": GameState.water_glasses,
		"breathing_sessions": GameState.breathing_sessions,
	}


# ── Internal ─────────────────────────────────────────────────────

func _on_fetch_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result != HTTPRequest.RESULT_SUCCESS or response_code != 200:
		sync_failed.emit("http_%d_%d" % [result, response_code])
		return

	var json_str := body.get_string_from_utf8()
	var parsed = JSON.parse_string(json_str)
	if parsed is Dictionary:
		parsed["source"] = "api"
		sync_completed.emit(parsed)
	else:
		sync_failed.emit("parse_error")


func _get_base_url() -> String:
	# Check OS environment for override
	if OS.has_environment("BOT_API_URL"):
		return OS.get_environment("BOT_API_URL")
	# Check command-line arguments
	for arg in OS.get_cmdline_args():
		if arg.begins_with("--api-url="):
			return arg.substr(10)
	return DEFAULT_API_URL
