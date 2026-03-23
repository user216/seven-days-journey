extends Node
## Sattvic color palette, sky color interpolation, centralized Theme, button juice.

# ── Sattvic palette (from bot's CSS variables) ────────────────────

const BG_CREAM := Color("#fefcf3")
const TEXT_BROWN := Color("#3d3929")
const HINT_KHAKI := Color("#9e9578")
const SAGE_GREEN := Color("#7da344")
const LIGHT_SAGE := Color("#a8c97a")
const GOLDEN_AMBER := Color("#d4a843")
const LIGHT_GOLD := Color("#f5e6b8")
const EARTHY_BROWN := Color("#8b7355")
const DEEP_LEAF := Color("#5e8a3c")
const MINT_SAGE := Color("#e8f0da")
const SOFT_TEAL := Color("#7cafc2")
const WATER_SOFT := Color("#d6eaf2")
const TERRACOTTA := Color("#c9886e")
const BLOOM_SOFT := Color("#f2e0d6")
const LIGHT_SKY := Color("#b8cfe0")
const WARM_DANGER := Color("#c47a5a")

# ── Font scaling ─────────────────────────────────────────────────

const BASE_FONT_SCALE := 1.4

var game_theme: Theme = null


func _ready() -> void:
	CrashLogger.breadcrumb("ThemeManager._ready")
	game_theme = _build_theme()


func font_size(base: int) -> int:
	## Returns base font size scaled by global scale factors.
	return maxi(8, int(float(base) * BASE_FONT_SCALE * GameState.ui_scale))


func apply_ui_scale_to_tree(node: Node) -> void:
	## Recursively applies font size scaling and button juice to all children.
	for child in node.get_children():
		if child is Label or child is Button:
			if not child.has_meta("_base_font_size"):
				var current_size: int = child.get_theme_font_size("font_size")
				child.set_meta("_base_font_size", current_size)
			var base: int = child.get_meta("_base_font_size")
			child.add_theme_font_size_override("font_size", font_size(base))
		if child is Button:
			apply_button_juice(child)
		apply_ui_scale_to_tree(child)


func apply_button_juice(btn: Button) -> void:
	## Adds press animation + click sound to a button (idempotent).
	if btn.has_meta("_button_juiced"):
		return
	btn.set_meta("_button_juiced", true)
	btn.pivot_offset = btn.size * 0.5
	btn.resized.connect(func(): btn.pivot_offset = btn.size * 0.5)
	btn.button_down.connect(func():
		AudioManager.play("click")
		var tw := btn.create_tween()
		tw.tween_property(btn, "scale", Vector2(0.93, 0.93), 0.06).set_ease(Tween.EASE_IN)
	)
	btn.button_up.connect(func():
		var tw := btn.create_tween()
		tw.tween_property(btn, "scale", Vector2.ONE, 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	)


func _build_theme() -> Theme:
	## Builds a centralized Godot Theme resource with sattvic styling.
	var t := Theme.new()

	# Panel background
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.06, 0.88)
	panel_style.corner_radius_top_left = 24
	panel_style.corner_radius_top_right = 24
	panel_style.corner_radius_bottom_left = 24
	panel_style.corner_radius_bottom_right = 24
	panel_style.content_margin_left = 32.0
	panel_style.content_margin_top = 32.0
	panel_style.content_margin_right = 32.0
	panel_style.content_margin_bottom = 32.0
	t.set_stylebox("panel", "PanelContainer", panel_style)

	# Button normal
	var btn_normal := StyleBoxFlat.new()
	btn_normal.bg_color = SAGE_GREEN.darkened(0.1)
	btn_normal.bg_color.a = 0.9
	btn_normal.corner_radius_top_left = 16
	btn_normal.corner_radius_top_right = 16
	btn_normal.corner_radius_bottom_left = 16
	btn_normal.corner_radius_bottom_right = 16
	btn_normal.content_margin_left = 20.0
	btn_normal.content_margin_top = 14.0
	btn_normal.content_margin_right = 20.0
	btn_normal.content_margin_bottom = 14.0
	t.set_stylebox("normal", "Button", btn_normal)

	# Button hover
	var btn_hover := btn_normal.duplicate() as StyleBoxFlat
	btn_hover.bg_color = SAGE_GREEN
	t.set_stylebox("hover", "Button", btn_hover)

	# Button pressed
	var btn_pressed := btn_normal.duplicate() as StyleBoxFlat
	btn_pressed.bg_color = SAGE_GREEN.darkened(0.3)
	t.set_stylebox("pressed", "Button", btn_pressed)

	# Button disabled
	var btn_disabled := btn_normal.duplicate() as StyleBoxFlat
	btn_disabled.bg_color = HINT_KHAKI.darkened(0.3)
	btn_disabled.bg_color.a = 0.5
	t.set_stylebox("disabled", "Button", btn_disabled)

	# Button font colors
	t.set_color("font_color", "Button", Color.WHITE)
	t.set_color("font_hover_color", "Button", Color.WHITE)
	t.set_color("font_pressed_color", "Button", LIGHT_GOLD)

	# Label color
	t.set_color("font_color", "Label", BG_CREAM)

	# ProgressBar
	var bar_fill := StyleBoxFlat.new()
	bar_fill.bg_color = SAGE_GREEN
	bar_fill.corner_radius_top_left = 6
	bar_fill.corner_radius_top_right = 6
	bar_fill.corner_radius_bottom_left = 6
	bar_fill.corner_radius_bottom_right = 6
	t.set_stylebox("fill", "ProgressBar", bar_fill)

	var bar_bg := StyleBoxFlat.new()
	bar_bg.bg_color = Color(0.2, 0.2, 0.15, 0.6)
	bar_bg.corner_radius_top_left = 6
	bar_bg.corner_radius_top_right = 6
	bar_bg.corner_radius_bottom_left = 6
	bar_bg.corner_radius_bottom_right = 6
	t.set_stylebox("background", "ProgressBar", bar_bg)

	return t

# ── Hero dress colors per day ─────────────────────────────────────

const DAY_DRESS_COLORS: Array[Color] = [
	Color("#e8f0da"),  # Day 1 — mint sage
	Color("#f5e6b8"),  # Day 2 — light gold
	Color("#d6eaf2"),  # Day 3 — water soft
	Color("#f2e0d6"),  # Day 4 — bloom soft
	Color("#a8c97a"),  # Day 5 — light sage
	Color("#b8cfe0"),  # Day 6 — light sky
	Color("#d4a843"),  # Day 7 — golden amber
]

# ── Sky gradient stops ────────────────────────────────────────────
# Array of [time_factor (0-1), top_color, bottom_color]
# time_factor: 0.0 = 04:30 (dawn), 1.0 = 22:00 (night)

const SKY_STOPS: Array = [
	[0.00, Color("#0d1b3e"), Color("#1a2a5e")],    # 04:30 deep night
	[0.05, Color("#2a1a40"), Color("#4a3060")],    # 05:00 pre-dawn
	[0.10, Color("#c9886e"), Color("#f5e6b8")],    # 05:30 golden dawn
	[0.15, Color("#87CEEB"), Color("#b8cfe0")],    # 06:30 morning blue
	[0.40, Color("#87CEEB"), Color("#ADD8E6")],    # 10:30 midday
	[0.55, Color("#87CEEB"), Color("#b8cfe0")],    # 14:00 afternoon
	[0.75, Color("#d4a843"), Color("#c9886e")],    # 18:00 sunset
	[0.85, Color("#4a3060"), Color("#2a1a40")],    # 20:00 dusk
	[0.95, Color("#1a1a3e"), Color("#0d1b3e")],    # 21:30 night
	[1.00, Color("#0a0a2e"), Color("#0d1b3e")],    # 22:00 deep night
]

# ── Ambient light colors per phase ────────────────────────────────

const AMBIENT_COLORS: Dictionary = {
	"night": Color("#1a1a3e"),
	"dawn": Color("#f5e6b8"),
	"morning": Color("#fffde8"),
	"day": Color.WHITE,
	"afternoon": Color("#fff8e0"),
	"evening": Color("#f5e6b8"),
}


# ── Sky interpolation ─────────────────────────────────────────────

func get_sky_colors(time_factor: float) -> Array:
	## Returns [top_color, bottom_color] for the given time factor.
	var tf := clampf(time_factor, 0.0, 1.0)

	# Find the two surrounding stops
	var prev_stop: Array = SKY_STOPS[0]
	var next_stop: Array = SKY_STOPS[0]

	var found := false
	for i in range(len(SKY_STOPS) - 1):
		if tf >= SKY_STOPS[i][0] and tf <= SKY_STOPS[i + 1][0]:
			prev_stop = SKY_STOPS[i]
			next_stop = SKY_STOPS[i + 1]
			found = true
			break
	if not found:
		prev_stop = SKY_STOPS[SKY_STOPS.size() - 2]
		next_stop = SKY_STOPS[SKY_STOPS.size() - 1]

	var span: float = next_stop[0] - prev_stop[0]
	var t: float = 0.0
	if span > 0.001:
		t = (tf - prev_stop[0]) / span

	var top: Color = prev_stop[1].lerp(next_stop[1], t)
	var bottom: Color = prev_stop[2].lerp(next_stop[2], t)
	return [top, bottom]


func get_ambient_light(time_factor: float) -> Color:
	if time_factor < 0.05:
		return AMBIENT_COLORS["night"]
	elif time_factor < 0.12:
		return AMBIENT_COLORS["dawn"]
	elif time_factor < 0.20:
		return AMBIENT_COLORS["morning"]
	elif time_factor < 0.55:
		return AMBIENT_COLORS["day"]
	elif time_factor < 0.75:
		return AMBIENT_COLORS["afternoon"]
	elif time_factor < 0.90:
		return AMBIENT_COLORS["evening"]
	else:
		return AMBIENT_COLORS["night"]


func get_dress_color(day: int) -> Color:
	if day >= 1 and day <= 7:
		return DAY_DRESS_COLORS[day - 1]
	return LIGHT_SAGE


# ── Juice / Game Feel ────────────────────────────────────────────

func hit_stop(duration_ms: int = 60) -> void:
	## Brief time freeze for impact feel. Safe to call from anywhere.
	Engine.time_scale = 0.0
	await get_tree().create_timer(duration_ms / 1000.0, true, false, true).timeout
	Engine.time_scale = 1.0


func squash_stretch(node: Node2D, intensity: float = 0.15) -> void:
	## Quick squash-stretch pop on a Node2D. Intensity 0.0-0.5.
	if not is_instance_valid(node):
		return
	var orig_scale := node.scale
	var squash := Vector2(orig_scale.x * (1.0 + intensity), orig_scale.y * (1.0 - intensity))
	var stretch := Vector2(orig_scale.x * (1.0 - intensity * 0.5), orig_scale.y * (1.0 + intensity * 0.5))
	var tw := node.create_tween()
	tw.tween_property(node, "scale", squash, 0.06).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", stretch, 0.08).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(node, "scale", orig_scale, 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)


func squash_stretch_control(ctrl: Control, intensity: float = 0.12) -> void:
	## Quick squash-stretch pop on a Control node via pivot.
	if not is_instance_valid(ctrl):
		return
	ctrl.pivot_offset = ctrl.size * 0.5
	var squash := Vector2(1.0 + intensity, 1.0 - intensity)
	var stretch := Vector2(1.0 - intensity * 0.5, 1.0 + intensity * 0.5)
	var tw := ctrl.create_tween()
	tw.tween_property(ctrl, "scale", squash, 0.06).set_ease(Tween.EASE_OUT)
	tw.tween_property(ctrl, "scale", stretch, 0.08).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(ctrl, "scale", Vector2.ONE, 0.12).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)


func screen_shake(camera: Node2D, amplitude: float = 6.0, duration: float = 0.2) -> void:
	## Exponentially decaying screen shake on a camera or parent node.
	if not is_instance_valid(camera):
		return
	var orig_offset := camera.position
	var elapsed := 0.0
	var tw := camera.create_tween()
	var steps := int(duration / 0.02)
	for i in range(steps):
		var decay := pow(1.0 - float(i) / float(steps), 2.0)
		var offset := Vector2(
			randf_range(-amplitude, amplitude) * decay,
			randf_range(-amplitude, amplitude) * decay
		)
		tw.tween_property(camera, "position", orig_offset + offset, 0.02)
	tw.tween_property(camera, "position", orig_offset, 0.04)
