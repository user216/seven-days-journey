extends Node
## CrashLogger — device diagnostics + error capture + log retrieval + breadcrumb trail.
## First autoload (before ShaderWarmup) so it catches everything.
## Writes to user://crash_log.txt on each launch.
## NewPipe-style: detects previous crash and shows report dialog on next launch.
##
## Breadcrumb trail: autoloads and key startup points call CrashLogger.breadcrumb("label")
## to write tiny markers to user://breadcrumbs.txt. On crash, the trail shows exactly
## how far initialization got before the native crash.

const LOG_PATH := "user://crash_log.txt"
const SESSION_STATE_PATH := "user://session_state.txt"
const BREADCRUMB_PATH := "user://breadcrumbs.txt"
const PREV_BREADCRUMB_PATH := "user://prev_breadcrumbs.txt"
const MAX_ERRORS := 50

var _errors: Array[String] = []
var _device_info: String = ""
var _session_start: String = ""
var _previous_crash_detected: bool = false
var _crash_report_text: String = ""
var _breadcrumb_count: int = 0


func _ready() -> void:
	_session_start = Time.get_datetime_string_from_system(false, true)
	_previous_crash_detected = _check_previous_crash()
	_device_info = _collect_device_info()
	_write_session_header()
	_mark_session_running()
	# Preserve previous breadcrumbs before we overwrite
	_rotate_breadcrumbs()
	# Start fresh breadcrumb trail for this session
	breadcrumb("CrashLogger._ready")
	if _previous_crash_detected:
		_crash_report_text = _build_crash_report_from_previous()
		# Defer dialog to next frame so the scene tree is fully ready
		call_deferred("_show_crash_report_dialog")


func breadcrumb(label: String) -> void:
	## Write a breadcrumb marker to disk immediately.
	## Call from autoload _ready(), shader warmup steps, scene loads, etc.
	## Each breadcrumb is flushed instantly (FileAccess.close) so it survives native crashes.
	_breadcrumb_count += 1
	var timestamp := Time.get_datetime_string_from_system(false, true)
	var line := "[%03d] %s — %s\n" % [_breadcrumb_count, timestamp, label]
	var f := FileAccess.open(BREADCRUMB_PATH, FileAccess.READ_WRITE if FileAccess.file_exists(BREADCRUMB_PATH) else FileAccess.WRITE)
	if f:
		f.seek_end()
		f.store_string(line)
		f.close()


func _rotate_breadcrumbs() -> void:
	## Move current breadcrumbs to prev_breadcrumbs (for crash report).
	if FileAccess.file_exists(BREADCRUMB_PATH):
		var f := FileAccess.open(BREADCRUMB_PATH, FileAccess.READ)
		if f:
			var content := f.get_as_text()
			f.close()
			var pf := FileAccess.open(PREV_BREADCRUMB_PATH, FileAccess.WRITE)
			if pf:
				pf.store_string(content)
				pf.close()
	# Clear for new session
	var nf := FileAccess.open(BREADCRUMB_PATH, FileAccess.WRITE)
	if nf:
		nf.store_string("")
		nf.close()


func _collect_device_info() -> String:
	var info := PackedStringArray()
	info.append("=== Device Diagnostics ===")
	info.append("Time: %s" % _session_start)
	info.append("OS: %s" % OS.get_name())
	info.append("Model: %s" % OS.get_model_name())
	info.append("Locale: %s" % OS.get_locale())

	# Screen
	var screen_size := DisplayServer.screen_get_size()
	var window_size := DisplayServer.window_get_size()
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size if get_viewport() else Vector2.ZERO
	info.append("Screen: %s" % str(screen_size))
	info.append("Window: %s" % str(window_size))
	info.append("Viewport: %s" % str(viewport_size))
	info.append("Scale: %.2f" % DisplayServer.screen_get_scale())

	# GPU / Renderer
	var ri := RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_VIDEO_MEM_USED)
	info.append("Renderer: %s" % ProjectSettings.get_setting("rendering/renderer/rendering_method", "unknown"))
	info.append("GPU: %s" % RenderingServer.get_video_adapter_name())
	info.append("GPU Vendor: %s" % RenderingServer.get_video_adapter_vendor())
	info.append("GPU Driver: %s" % RenderingServer.get_video_adapter_api_version())
	info.append("VRAM used: %d MB" % (ri / 1048576))

	# Memory
	info.append("Static mem: %d MB" % (OS.get_static_memory_usage() / 1048576))

	# Engine
	var version_file := FileAccess.open("res://VERSION", FileAccess.READ)
	var app_version := version_file.get_as_text().strip_edges() if version_file else "?"
	info.append("App version: %s" % app_version)
	info.append("Godot: %s" % Engine.get_version_info().string)
	info.append("Debug: %s" % str(OS.is_debug_build()))
	info.append("============================")
	return "\n".join(info)


func _write_session_header() -> void:
	DirAccess.make_dir_recursive_absolute("user://")
	var f := FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if f:
		f.store_string(_device_info + "\n\n")
		# Append previous crash info if exists
		var prev := _read_previous_log()
		if prev.length() > 0:
			f.store_string("--- Previous session errors ---\n")
			f.store_string(prev + "\n")
			f.store_string("--- End previous ---\n\n")
		f.store_string("--- Current session ---\n")
		f.close()


func _read_previous_log() -> String:
	var err_path := "user://last_errors.txt"
	if FileAccess.file_exists(err_path):
		var f := FileAccess.open(err_path, FileAccess.READ)
		if f:
			var content := f.get_as_text()
			f.close()
			return content
	return ""


func _check_previous_crash() -> bool:
	## Returns true if previous session did not exit cleanly.
	if not FileAccess.file_exists(SESSION_STATE_PATH):
		return false  # First ever launch
	var f := FileAccess.open(SESSION_STATE_PATH, FileAccess.READ)
	if not f:
		return false
	var state := f.get_as_text().strip_edges()
	f.close()
	return state == "running"


func _mark_session_running() -> void:
	var f := FileAccess.open(SESSION_STATE_PATH, FileAccess.WRITE)
	if f:
		f.store_string("running")
		f.close()


func _mark_session_clean() -> void:
	var f := FileAccess.open(SESSION_STATE_PATH, FileAccess.WRITE)
	if f:
		f.store_string("clean")
		f.close()


func _build_crash_report_from_previous() -> String:
	## Builds a crash report from previous session's saved data.
	var parts := PackedStringArray()
	parts.append("=== 7 Days Journey — Crash Report ===")
	parts.append("Previous session crashed unexpectedly.")
	parts.append("")
	parts.append(_device_info)
	parts.append("")

	# Breadcrumb trail from crashed session
	var trail := _read_previous_breadcrumbs()
	if trail.length() > 0:
		parts.append("--- Startup breadcrumb trail ---")
		parts.append(trail)
		parts.append("--- End breadcrumbs (crash after last entry) ---")
		parts.append("")
	else:
		parts.append("--- No breadcrumbs (crash during CrashLogger init) ---")
		parts.append("")

	# Previous session errors
	var prev_errors := _read_previous_log()
	if prev_errors.length() > 0:
		parts.append("--- Previous session errors ---")
		parts.append(prev_errors)
		parts.append("--- End errors ---")
		parts.append("")

	# Engine log (last 100 lines)
	var godot_log := "user://logs/godot.log"
	if FileAccess.file_exists(godot_log):
		var f := FileAccess.open(godot_log, FileAccess.READ)
		if f:
			var content := f.get_as_text()
			f.close()
			var lines := content.split("\n")
			if lines.size() > 100:
				lines = lines.slice(lines.size() - 100)
			parts.append("--- Engine log (last 100 lines) ---")
			parts.append("\n".join(lines))
			parts.append("--- End engine log ---")

	return "\n".join(parts)


func _read_previous_breadcrumbs() -> String:
	if FileAccess.file_exists(PREV_BREADCRUMB_PATH):
		var f := FileAccess.open(PREV_BREADCRUMB_PATH, FileAccess.READ)
		if f:
			var content := f.get_as_text().strip_edges()
			f.close()
			return content
	return ""


func _show_crash_report_dialog() -> void:
	## NewPipe-style dialog: shown automatically on launch after a crash.
	var layer := CanvasLayer.new()
	layer.layer = 100  # On top of everything

	# Semi-transparent background
	var overlay := ColorRect.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0.0, 0.0, 0.0, 0.7)
	layer.add_child(overlay)

	# Dialog panel
	var panel := PanelContainer.new()
	panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	panel.offset_left = -480
	panel.offset_right = 480
	panel.offset_top = -650
	panel.offset_bottom = 650
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.98, 0.97, 0.94)
	panel_style.corner_radius_top_left = 24
	panel_style.corner_radius_top_right = 24
	panel_style.corner_radius_bottom_left = 24
	panel_style.corner_radius_bottom_right = 24
	panel_style.content_margin_left = 32.0
	panel_style.content_margin_top = 28.0
	panel_style.content_margin_right = 32.0
	panel_style.content_margin_bottom = 28.0
	panel_style.shadow_color = Color(0, 0, 0, 0.25)
	panel_style.shadow_size = 8
	panel.add_theme_stylebox_override("panel", panel_style)
	layer.add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	panel.add_child(vbox)

	# Warning icon + title
	var title := Label.new()
	title.text = "Приложение завершилось аварийно"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color("#c47a5a"))
	title.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(title)

	var subtitle := Label.new()
	subtitle.text = "Предыдущий сеанс завершился с ошибкой.\nОтправьте отчёт, чтобы помочь исправить проблему."
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 18)
	subtitle.add_theme_color_override("font_color", Color("#3d3929"))
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(subtitle)

	# Crash report text (scrollable)
	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 600)
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var report_label := Label.new()
	report_label.text = _crash_report_text
	report_label.add_theme_font_size_override("font_size", 14)
	report_label.add_theme_color_override("font_color", Color("#3d3929"))
	report_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	report_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(report_label)

	# Buttons
	var btn_box := VBoxContainer.new()
	btn_box.add_theme_constant_override("separation", 12)
	vbox.add_child(btn_box)

	var email_btn := Button.new()
	email_btn.text = "Отправить по email"
	email_btn.custom_minimum_size = Vector2(0, 64)
	email_btn.add_theme_font_size_override("font_size", 20)
	_style_dialog_btn(email_btn, Color("#7da344"))
	email_btn.pressed.connect(func():
		DisplayServer.clipboard_set(_crash_report_text)
		send_logs_via_email()
	)
	btn_box.add_child(email_btn)

	var copy_btn := Button.new()
	copy_btn.text = "Скопировать отчёт"
	copy_btn.custom_minimum_size = Vector2(0, 64)
	copy_btn.add_theme_font_size_override("font_size", 20)
	_style_dialog_btn(copy_btn, Color("#8b7355"))
	copy_btn.pressed.connect(func():
		DisplayServer.clipboard_set(_crash_report_text)
		copy_btn.text = "Скопировано!"
		var tw := copy_btn.create_tween()
		tw.tween_callback(func(): copy_btn.text = "Скопировать отчёт").set_delay(2.0)
	)
	btn_box.add_child(copy_btn)

	var close_btn := Button.new()
	close_btn.text = "Закрыть"
	close_btn.custom_minimum_size = Vector2(0, 56)
	close_btn.add_theme_font_size_override("font_size", 18)
	_style_dialog_btn(close_btn, Color("#9e9578"))
	close_btn.pressed.connect(func(): layer.queue_free())
	btn_box.add_child(close_btn)

	# Entrance animation
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.9, 0.9)
	panel.pivot_offset = panel.size * 0.5

	get_tree().root.add_child(layer)

	# Wait a frame for layout, then animate
	await get_tree().process_frame
	panel.pivot_offset = panel.size * 0.5
	var tw := panel.create_tween()
	tw.set_parallel(true)
	tw.tween_property(panel, "modulate:a", 1.0, 0.3)
	tw.tween_property(panel, "scale", Vector2.ONE, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)


func _style_dialog_btn(btn: Button, color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 14
	style.corner_radius_top_right = 14
	style.corner_radius_bottom_left = 14
	style.corner_radius_bottom_right = 14
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	btn.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = color.lightened(0.1)
	btn.add_theme_stylebox_override("hover", hover)
	var pressed := style.duplicate() as StyleBoxFlat
	pressed.bg_color = color.darkened(0.15)
	btn.add_theme_stylebox_override("pressed", pressed)
	btn.add_theme_color_override("font_color", Color.WHITE)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)
	btn.add_theme_color_override("font_pressed_color", Color(0.95, 0.9, 0.7))


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_CRASH:
		_flush_errors()
		if what == NOTIFICATION_WM_CLOSE_REQUEST:
			_mark_session_clean()
	if what == NOTIFICATION_PREDELETE:
		_flush_errors()
		_mark_session_clean()


func log_error(msg: String) -> void:
	var timestamp := Time.get_datetime_string_from_system(false, true)
	var entry := "[%s] %s" % [timestamp, msg]
	_errors.append(entry)
	if _errors.size() > MAX_ERRORS:
		_errors.pop_front()
	# Append to crash log immediately
	var f := FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
	if f:
		f.seek_end()
		f.store_string(entry + "\n")
		f.close()


func _flush_errors() -> void:
	if _errors.is_empty():
		return
	var f := FileAccess.open("user://last_errors.txt", FileAccess.WRITE)
	if f:
		f.store_string("\n".join(_errors))
		f.close()


func get_full_log() -> String:
	## Returns the complete crash log as a string (for clipboard/share).
	var result := _device_info + "\n\n"

	# Breadcrumbs from current session
	if FileAccess.file_exists(BREADCRUMB_PATH):
		var bf := FileAccess.open(BREADCRUMB_PATH, FileAccess.READ)
		if bf:
			var bc := bf.get_as_text().strip_edges()
			bf.close()
			if bc.length() > 0:
				result += "--- Breadcrumb trail ---\n"
				result += bc + "\n"
				result += "--- End breadcrumbs ---\n\n"

	# Append the Godot engine log if available
	var godot_log := "user://logs/godot.log"
	if FileAccess.file_exists(godot_log):
		var f := FileAccess.open(godot_log, FileAccess.READ)
		if f:
			var content := f.get_as_text()
			f.close()
			# Only last 200 lines to keep it manageable
			var lines := content.split("\n")
			if lines.size() > 200:
				lines = lines.slice(lines.size() - 200)
			result += "--- Engine log (last 200 lines) ---\n"
			result += "\n".join(lines)
			result += "\n--- End engine log ---\n\n"

	# Append session errors
	if _errors.size() > 0:
		result += "--- Session errors (%d) ---\n" % _errors.size()
		result += "\n".join(_errors)
		result += "\n--- End errors ---\n"

	return result


func get_device_summary() -> String:
	## Short one-liner for display in menus.
	var gpu := RenderingServer.get_video_adapter_name()
	var model := OS.get_model_name()
	var screen := DisplayServer.screen_get_size()
	return "%s | %s | %sx%s" % [model, gpu, screen.x, screen.y]


func send_logs_via_email(recipient: String = "") -> void:
	## Opens the default email app with device info + error log pre-filled.
	## mailto: body is limited (~2000 chars), so we send essential info only.
	## Full log is also copied to clipboard as backup.
	var subject := "7 Days Journey — Crash Report (%s)" % OS.get_model_name()
	var body := _build_email_body()

	# Also copy full log to clipboard (email body is truncated)
	DisplayServer.clipboard_set(get_full_log())

	# Build mailto URI — percent-encode subject and body
	var uri := "mailto:%s?subject=%s&body=%s" % [
		recipient,
		_uri_encode(subject),
		_uri_encode(body),
	]
	OS.shell_open(uri)


func _build_email_body() -> String:
	## Compact body that fits in mailto: URI (~1500 chars target).
	var parts := PackedStringArray()
	parts.append("=== 7 Days Journey — Crash Report ===")
	parts.append("")
	parts.append("Model: %s" % OS.get_model_name())
	parts.append("OS: %s" % OS.get_name())
	parts.append("Screen: %s" % str(DisplayServer.screen_get_size()))
	parts.append("GPU: %s" % RenderingServer.get_video_adapter_name())
	parts.append("GPU Driver: %s" % RenderingServer.get_video_adapter_api_version())
	parts.append("VRAM: %d MB" % (RenderingServer.get_rendering_info(
		RenderingServer.RENDERING_INFO_VIDEO_MEM_USED) / 1048576))
	parts.append("RAM: %d MB" % (OS.get_static_memory_usage() / 1048576))

	var version_file := FileAccess.open("res://VERSION", FileAccess.READ)
	var app_ver := version_file.get_as_text().strip_edges() if version_file else "?"
	parts.append("App: v%s | Godot %s" % [app_ver, Engine.get_version_info().string])
	parts.append("Renderer: %s" % ProjectSettings.get_setting(
		"rendering/renderer/rendering_method", "?"))
	parts.append("Debug: %s" % str(OS.is_debug_build()))
	parts.append("")

	# Breadcrumb trail (compact — last 15 entries)
	if FileAccess.file_exists(PREV_BREADCRUMB_PATH):
		var bf := FileAccess.open(PREV_BREADCRUMB_PATH, FileAccess.READ)
		if bf:
			var content := bf.get_as_text().strip_edges()
			bf.close()
			if content.length() > 0:
				var lines := content.split("\n")
				if lines.size() > 15:
					lines = lines.slice(lines.size() - 15)
				parts.append("--- Breadcrumbs (last %d) ---" % lines.size())
				parts.append_array(lines)
				parts.append("--- Crashed after last entry ---")
				parts.append("")

	# Last errors (up to 20 lines to stay within URI limits)
	if _errors.size() > 0:
		parts.append("--- Errors (%d total, last 20) ---" % _errors.size())
		var start := maxi(0, _errors.size() - 20)
		for i in range(start, _errors.size()):
			parts.append(_errors[i])
		parts.append("--- End ---")
	else:
		parts.append("(No errors captured this session)")

	# Engine log — last 30 lines
	var godot_log := "user://logs/godot.log"
	if FileAccess.file_exists(godot_log):
		var f := FileAccess.open(godot_log, FileAccess.READ)
		if f:
			var content := f.get_as_text()
			f.close()
			var lines := content.split("\n")
			if lines.size() > 30:
				lines = lines.slice(lines.size() - 30)
			parts.append("")
			parts.append("--- Engine log (last 30 lines) ---")
			parts.append_array(lines)
			parts.append("--- End ---")

	parts.append("")
	parts.append("(Full log also copied to clipboard)")
	return "\n".join(parts)


func _uri_encode(text: String) -> String:
	## Percent-encode for mailto: URI. Godot doesn't have built-in URI encoding.
	return text.uri_encode()
