extends Node
## Pre-compiles shaders during startup to prevent first-frame stutter on mobile.
## Staggered: compiles BATCH_SIZE shaders per frame to avoid overwhelming budget GPUs.
## Skips screen-texture shaders (hint_screen_texture) — they need a rendered frame first.
## Warmup rects are NOT freed — destroying shader materials while Mali GPU still
## references them from the command buffer can crash Vulkan drivers.

## Shaders that use hint_screen_texture are excluded — they compile on first use
## after a frame exists. Compiling them before any frame renders can crash Mali drivers.
const SHADER_PATHS: Array[String] = [
	"res://shaders/platform_glow.gdshader",
	"res://shaders/ambient_glow.gdshader",
	"res://shaders/iris_wipe.gdshader",
	"res://shaders/sky_gradient.gdshader",
	"res://shaders/vignette.gdshader",
	"res://shaders/hopa_object_highlight.gdshader",
	"res://shaders/hopa_scene_depth.gdshader",
	"res://shaders/hopa_discovery_burst.gdshader",
	"res://shaders/screen_flash.gdshader",
	"res://shaders/diamond_wipe.gdshader",
	"res://shaders/dissolve.gdshader",
	"res://shaders/hero_tint.gdshader",
	"res://shaders/sprite_outline.gdshader",
	"res://shaders/pattern_dissolve.gdshader",
	# NOTE: background_blur.gdshader and shockwave.gdshader excluded
	# — they use hint_screen_texture which doesn't exist during boot
]

const BATCH_SIZE := 4  # shaders per frame

var _index: int = 0
var _skip: bool = false


func _ready() -> void:
	if not _read_diag_flag("shaders", true):
		_skip = true
		set_process(false)
		CrashLogger.breadcrumb("ShaderWarmup._ready SKIPPED (shaders=off)")
		return
	CrashLogger.breadcrumb("ShaderWarmup._ready (staggered, %d shaders)" % SHADER_PATHS.size())


func _read_diag_flag(key: String, default_val: bool) -> bool:
	var path := "user://diag_flags.txt"
	if not FileAccess.file_exists(path):
		return default_val
	var f := FileAccess.open(path, FileAccess.READ)
	if not f:
		return default_val
	while not f.eof_reached():
		var line := f.get_line().strip_edges()
		if line.begins_with(key + "="):
			f.close()
			return line.get_slice("=", 1) == "1"
	f.close()
	return default_val


func _process(_delta: float) -> void:
	if _index >= SHADER_PATHS.size():
		set_process(false)
		CrashLogger.breadcrumb("ShaderWarmup.done (%d shaders compiled)" % SHADER_PATHS.size())
		# Do NOT free the warmup rects — Mali Vulkan drivers crash when shader
		# resources are freed while the GPU's command buffer still references them.
		# 14 invisible 1px nodes use negligible memory.
		return

	var end := mini(_index + BATCH_SIZE, SHADER_PATHS.size())
	var batch_names := PackedStringArray()
	for i in range(_index, end):
		var path := SHADER_PATHS[i]
		var shader_name := path.get_file().get_basename()
		batch_names.append(shader_name)
		var shader: Shader = load(path) as Shader
		if not shader:
			continue
		var mat := ShaderMaterial.new()
		mat.shader = shader
		var rect := ColorRect.new()
		rect.material = mat
		rect.size = Vector2(1, 1)
		rect.position = Vector2(-10, -10)  # offscreen
		rect.modulate.a = 0.0  # invisible
		add_child(rect)

	CrashLogger.breadcrumb("ShaderWarmup.batch [%s]" % ", ".join(batch_names))
	_index = end
