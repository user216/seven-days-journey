extends Control
## Character customization screen — skin color, hair color, hair style selection before game start.

@onready var preview: TextureRect = $VBox/Preview
@onready var skin_label: Label = $VBox/SkinRow/SkinLabel
@onready var hair_label: Label = $VBox/HairRow/HairLabel
@onready var style_label: Label = $VBox/StyleRow/StyleLabel
@onready var start_btn: Button = $VBox/StartBtn

var _preview_shader: ShaderMaterial = null


func _ready() -> void:
	$VBox/SkinRow/SkinPrev.pressed.connect(_on_skin_prev)
	$VBox/SkinRow/SkinNext.pressed.connect(_on_skin_next)
	$VBox/HairRow/HairPrev.pressed.connect(_on_hair_prev)
	$VBox/HairRow/HairNext.pressed.connect(_on_hair_next)
	$VBox/StyleRow/StylePrev.pressed.connect(_on_style_prev)
	$VBox/StyleRow/StyleNext.pressed.connect(_on_style_next)
	start_btn.pressed.connect(_on_start)
	# Setup tint shader for preview
	_preview_shader = ShaderMaterial.new()
	_preview_shader.shader = load("res://shaders/hero_tint.gdshader")
	preview.material = _preview_shader
	_update_all()
	ThemeManager.apply_ui_scale_to_tree(self)
	GameState.ui_scale_changed.connect(func(_s): ThemeManager.apply_ui_scale_to_tree(self))


func _update_all() -> void:
	_update_skin_label()
	_update_hair_label()
	_update_style_label()
	_update_preview()


func _update_preview() -> void:
	var suffix := GameState.get_hair_style_suffix()
	var gender_suffix := ""
	if GameState.gender == "male":
		gender_suffix = "_male"
	var path := "res://assets/hero/climb/hero_climb_idle%s%s.svg" % [gender_suffix, suffix]
	var tex := load(path) as Texture2D
	if tex:
		preview.texture = tex
		preview.modulate = Color.WHITE
	if _preview_shader:
		_preview_shader.set_shader_parameter("skin_tint", GameState.get_skin_tint())
		_preview_shader.set_shader_parameter("hair_tint", GameState.get_hair_tint())
		_preview_shader.set_shader_parameter("dress_tint", Color.WHITE)
		_preview_shader.set_shader_parameter("glow_intensity", 0.0)


func _update_skin_label() -> void:
	skin_label.text = GameState.SKIN_PRESETS[GameState.hero_skin_idx].name


func _update_hair_label() -> void:
	hair_label.text = GameState.HAIR_PRESETS[GameState.hero_hair_idx].name


func _update_style_label() -> void:
	style_label.text = GameState.get_hair_style_name()


func _on_skin_prev() -> void:
	GameState.hero_skin_idx = wrapi(GameState.hero_skin_idx - 1, 0, GameState.SKIN_PRESETS.size())
	_update_all()

func _on_skin_next() -> void:
	GameState.hero_skin_idx = wrapi(GameState.hero_skin_idx + 1, 0, GameState.SKIN_PRESETS.size())
	_update_all()

func _on_hair_prev() -> void:
	GameState.hero_hair_idx = wrapi(GameState.hero_hair_idx - 1, 0, GameState.HAIR_PRESETS.size())
	_update_all()

func _on_hair_next() -> void:
	GameState.hero_hair_idx = wrapi(GameState.hero_hair_idx + 1, 0, GameState.HAIR_PRESETS.size())
	_update_all()

func _on_style_prev() -> void:
	var presets := GameState.get_hair_style_presets()
	GameState.hero_hair_style_idx = wrapi(GameState.hero_hair_style_idx - 1, 0, presets.size())
	_update_all()

func _on_style_next() -> void:
	var presets := GameState.get_hair_style_presets()
	GameState.hero_hair_style_idx = wrapi(GameState.hero_hair_style_idx + 1, 0, presets.size())
	_update_all()

func _on_start() -> void:
	GameState.start_game()
	SaveManager.save_game()
	SceneTransition.change_scene("res://scenes/vertical_climb/vertical_level.tscn")
