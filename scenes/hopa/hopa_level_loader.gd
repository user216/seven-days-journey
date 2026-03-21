class_name HopaLevelLoader
## Loads and validates HOPA level data from JSON files.

# ── Public API ───────────────────────────────────────────────────

static func load_level(json_path: String) -> Dictionary:
	## Reads a level JSON and returns a structured Dictionary.
	## Returns empty Dictionary on any failure.
	if not FileAccess.file_exists(json_path):
		push_error("HopaLevelLoader: file not found: %s" % json_path)
		return {}

	var file := FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		push_error("HopaLevelLoader: cannot open: %s" % json_path)
		return {}

	var text := file.get_as_text()
	file.close()

	var parsed = JSON.parse_string(text)
	if parsed == null or not parsed is Dictionary:
		push_error("HopaLevelLoader: invalid JSON in: %s" % json_path)
		return {}

	return _parse_level(parsed)


# ── Internal parsing ─────────────────────────────────────────────

static func _parse_level(raw: Dictionary) -> Dictionary:
	var result: Dictionary = {}

	# Required fields
	result["scene_id"] = raw.get("scene_id", "")
	result["day"] = int(raw.get("day", 0))
	result["title"] = raw.get("title", "")

	# Background
	var bg_path: String = raw.get("background", "")
	result["background_path"] = bg_path
	result["background_texture"] = _load_texture(bg_path)

	# Audio
	result["ambient_audio_path"] = raw.get("ambient_audio", "")

	# Timing
	result["time_limit"] = int(raw.get("time_limit_seconds", HopaData.DEFAULT_TIME_LIMIT))
	result["hint_cooldown"] = float(raw.get("hint_cooldown_seconds", HopaData.DEFAULT_HINT_COOLDOWN))

	# Objects
	var objects: Array[Dictionary] = []
	for obj_raw in raw.get("objects", []):
		objects.append(_parse_object(obj_raw))
	result["objects"] = objects

	# Puzzles
	result["puzzles"] = raw.get("puzzles", [])

	# Story
	result["story_before"] = raw.get("story_before", "")
	result["story_after"] = raw.get("story_after", "")

	# Navigation
	result["next_scene"] = raw.get("next_scene", "")

	return result


static func _parse_object(raw: Dictionary) -> Dictionary:
	var obj: Dictionary = {}
	obj["id"] = raw.get("id", "")
	obj["name"] = raw.get("name", "")

	# Texture
	var tex_path: String = raw.get("texture", "")
	obj["texture_path"] = tex_path
	obj["texture"] = _load_texture(tex_path)

	# Position — JSON stores as [x, y] array
	var pos_arr = raw.get("position", [540, 960])
	if pos_arr is Array and pos_arr.size() >= 2:
		obj["position"] = Vector2(float(pos_arr[0]), float(pos_arr[1]))
	else:
		obj["position"] = Vector2(540, 960)

	# Scale
	obj["scale"] = float(raw.get("scale", 1.0))

	# Rotation — JSON stores degrees, convert to radians
	obj["rotation"] = deg_to_rad(float(raw.get("rotation_deg", 0.0)))

	# Hint
	obj["hint_radius"] = float(raw.get("hint_radius", 60.0))

	# Key item flag
	obj["is_key_item"] = bool(raw.get("is_key_item", false))

	return obj


static func _load_texture(path: String) -> Texture2D:
	## Loads a texture, returning null if path is empty or resource missing.
	if path.is_empty():
		return null
	if not ResourceLoader.exists(path):
		return null
	var res = ResourceLoader.load(path)
	if res is Texture2D:
		return res
	return null
