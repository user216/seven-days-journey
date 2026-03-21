extends Control
## Character customization screen — skin color, hair color, hair style selection before game start.

@onready var preview: TextureRect = $VBox/Preview
@onready var skin_label: Label = $VBox/SkinRow/SkinLabel
@onready var hair_label: Label = $VBox/HairRow/HairLabel
@onready var style_label: Label = $VBox/StyleRow/StyleLabel
@onready var start_btn: Button = $VBox/StartBtn


func _ready() -> void:
	$VBox/SkinRow/SkinPrev.pressed.connect(_on_skin_prev)
	$VBox/SkinRow/SkinNext.pressed.connect(_on_skin_next)
	$VBox/HairRow/HairPrev.pressed.connect(_on_hair_prev)
	$VBox/HairRow/HairNext.pressed.connect(_on_hair_next)
	$VBox/StyleRow/StylePrev.pressed.connect(_on_style_prev)
	$VBox/StyleRow/StyleNext.pressed.connect(_on_style_next)
	start_btn.pressed.connect(_on_start)
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
		# Apply tints via modulate on a sub-material or just show the base
		# Since SVGs are loaded as flat textures, modulate the whole preview
		preview.modulate = Color.WHITE


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
