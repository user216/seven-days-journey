class_name HopaData
## Static data definitions for HOPA "Сад Тайн" levels.

# ── Level order ──────────────────────────────────────────────────

const LEVEL_ORDER: Array[String] = [
	"garden_morning",
	"kitchen_pantry",
	"meditation_room",
	"forest_path",
	"tea_ceremony",
	"stargazing_tower",
	"sacred_garden",
]

# ── Level titles ─────────────────────────────────────────────────

const LEVEL_TITLES: Dictionary = {
	"garden_morning": "Утренний Сад",
	"kitchen_pantry": "Кухня трав",
	"meditation_room": "Комната медитации",
	"forest_path": "Лесная тропа",
	"tea_ceremony": "Чайная церемония",
	"stargazing_tower": "Башня звездочёта",
	"sacred_garden": "Священный сад",
}

# ── Story text (before/after each level) ─────────────────────────

const STORY_TEXT: Dictionary = {
	"garden_morning": {
		"before": [
			"Доброе утро! Солнце только взошло над садом.",
			"Роса блестит на лепестках, а воздух наполнен ароматом трав.",
			"Найди все предметы, чтобы приготовить утренний ритуал.",
		],
		"after": [
			"Прекрасно! Сад раскрыл свои тайны.",
			"Пора идти на кухню приготовить целебный напиток...",
		],
	},
	"kitchen_pantry": {
		"before": [
			"Кухня пахнет корицей и шалфеем.",
			"На полках — медные кастрюли и баночки со специями.",
			"Найди всё, что нужно для приготовления аюрведического напитка.",
		],
		"after": [
			"Напиток готов! Тепло разливается по телу.",
			"Теперь — к тихому месту для медитации...",
		],
	},
	"meditation_room": {
		"before": [
			"Мягкий свет луны проникает через окно.",
			"Комната наполнена покоем и тонким ароматом благовоний.",
			"Найди предметы для глубокой медитации.",
		],
		"after": [
			"Ум стал ясным, как горное озеро.",
			"Природа зовёт — пора на прогулку в лес...",
		],
	},
	"forest_path": {
		"before": [
			"Древние деревья склоняют ветви над тропой.",
			"Мох, грибы, звуки ручья — лес полон жизни.",
			"Найди сокровища, которые прячет лесная тропа.",
		],
		"after": [
			"Лес поделился своей мудростью.",
			"Вдалеке виднеется уютная чайная...",
		],
	},
	"tea_ceremony": {
		"before": [
			"Бамбуковый коврик, тонкий фарфор, аромат жасмина.",
			"Чайная церемония — это искусство быть здесь и сейчас.",
			"Найди всё необходимое для чаепития.",
		],
		"after": [
			"Каждый глоток — момент осознанности.",
			"Вечереет. Пора подняться на башню звездочёта...",
		],
	},
	"stargazing_tower": {
		"before": [
			"Сумерки окутали башню. Небо полно звёзд.",
			"Карты созвездий разбросаны среди кристаллов и свечей.",
			"Найди инструменты для наблюдения за звёздами.",
		],
		"after": [
			"Звёзды рассказали свою историю.",
			"Впереди — последний шаг: Священный сад...",
		],
	},
	"sacred_garden": {
		"before": [
			"Золотой свет заливает фонтан и цветущий пруд.",
			"Все семь дней привели тебя сюда — в сердце сада.",
			"Найди знакомые предметы — они ждут возвращения.",
		],
		"after": [
			"Сад Тайн раскрыл все свои секреты.",
			"Ты прошла путь гармонии. Практикум завершён!",
		],
	},
}

# ── Defaults ─────────────────────────────────────────────────────

const DEFAULT_TIME_LIMIT := 180
const DEFAULT_HINT_COOLDOWN := 30.0
const DEFAULT_OBJECTS_ALPHA := 0.85

# ── Object definitions per level ─────────────────────────────────
# Each object: id, name (Russian), is_key_item

const LEVEL_OBJECTS: Dictionary = {
	"garden_morning": [
		{"id": "watering_can", "name": "Лейка", "is_key_item": false},
		{"id": "golden_key", "name": "Золотой ключ", "is_key_item": true},
		{"id": "butterfly", "name": "Бабочка", "is_key_item": false},
		{"id": "teacup", "name": "Чашка", "is_key_item": false},
		{"id": "crystal", "name": "Кристалл", "is_key_item": false},
		{"id": "feather", "name": "Перо", "is_key_item": false},
		{"id": "scroll", "name": "Свиток", "is_key_item": true},
	],
	"kitchen_pantry": [
		{"id": "mortar", "name": "Ступка", "is_key_item": false},
		{"id": "cinnamon_stick", "name": "Палочка корицы", "is_key_item": false},
		{"id": "golden_spoon", "name": "Золотая ложка", "is_key_item": true},
		{"id": "herb_jar", "name": "Банка с травами", "is_key_item": false},
		{"id": "candle", "name": "Свеча", "is_key_item": false},
		{"id": "recipe_book", "name": "Книга рецептов", "is_key_item": true},
	],
	"meditation_room": [
		{"id": "singing_bowl", "name": "Поющая чаша", "is_key_item": false},
		{"id": "mala_beads", "name": "Чётки", "is_key_item": false},
		{"id": "lotus_flower", "name": "Лотос", "is_key_item": true},
		{"id": "incense_holder", "name": "Курильница", "is_key_item": false},
		{"id": "moon_pendant", "name": "Лунный кулон", "is_key_item": true},
	],
	"forest_path": [
		{"id": "mushroom", "name": "Гриб", "is_key_item": false},
		{"id": "lantern", "name": "Фонарь", "is_key_item": false},
		{"id": "bird_nest", "name": "Гнездо", "is_key_item": false},
		{"id": "stone_rune", "name": "Камень с руной", "is_key_item": true},
		{"id": "fox_figurine", "name": "Фигурка лисы", "is_key_item": false},
		{"id": "acorn", "name": "Жёлудь", "is_key_item": false},
	],
	"tea_ceremony": [
		{"id": "tea_whisk", "name": "Венчик для чая", "is_key_item": false},
		{"id": "jade_stone", "name": "Нефрит", "is_key_item": false},
		{"id": "origami_crane", "name": "Журавлик", "is_key_item": true},
		{"id": "bonsai_scissors", "name": "Ножницы", "is_key_item": false},
		{"id": "bell", "name": "Колокольчик", "is_key_item": false},
	],
	"stargazing_tower": [
		{"id": "telescope_lens", "name": "Линза", "is_key_item": false},
		{"id": "star_map", "name": "Карта звёзд", "is_key_item": false},
		{"id": "prism", "name": "Призма", "is_key_item": true},
		{"id": "compass", "name": "Компас", "is_key_item": false},
		{"id": "moonstone", "name": "Лунный камень", "is_key_item": false},
		{"id": "quill", "name": "Перо для письма", "is_key_item": true},
	],
	"sacred_garden": [
		{"id": "golden_key_2", "name": "Золотой ключ", "is_key_item": false},
		{"id": "singing_bowl_2", "name": "Поющая чаша", "is_key_item": false},
		{"id": "lotus_flower_2", "name": "Лотос", "is_key_item": false},
		{"id": "stone_rune_2", "name": "Камень с руной", "is_key_item": false},
		{"id": "origami_crane_2", "name": "Журавлик", "is_key_item": false},
		{"id": "prism_2", "name": "Призма", "is_key_item": false},
		{"id": "fountain_gem", "name": "Камень фонтана", "is_key_item": true},
		{"id": "sacred_scroll", "name": "Священный свиток", "is_key_item": true},
	],
}

# ── Puzzle definitions per level ─────────────────────────────────

const LEVEL_PUZZLES: Dictionary = {
	"garden_morning": {"type": "jigsaw", "trigger": "after_all_found", "pieces": 9},
	"kitchen_pantry": {"type": "match_pairs", "trigger": "after_all_found", "pairs": 6},
	"meditation_room": {"type": "connect_runes", "trigger": "after_all_found", "pairs": 4},
	"forest_path": {"type": "jigsaw", "trigger": "after_all_found", "pieces": 9},
	"tea_ceremony": {"type": "match_pairs", "trigger": "after_all_found", "pairs": 6},
	"stargazing_tower": {"type": "connect_runes", "trigger": "after_all_found", "pairs": 5},
	"sacred_garden": {"type": "jigsaw", "trigger": "after_all_found", "pieces": 16},
}

# ── Puzzle scene mapping ─────────────────────────────────────────

const PUZZLE_SCENES: Dictionary = {
	"jigsaw": "res://scenes/hopa/puzzles/jigsaw_puzzle.tscn",
	"match_pairs": "res://scenes/hopa/puzzles/match_pairs_puzzle.tscn",
	"connect_runes": "res://scenes/hopa/puzzles/connect_runes_puzzle.tscn",
}

# ── Helpers ──────────────────────────────────────────────────────

static func get_level_for_day(day: int) -> String:
	if day >= 1 and day <= LEVEL_ORDER.size():
		return LEVEL_ORDER[day - 1]
	return ""


static func get_level_index(scene_id: String) -> int:
	return LEVEL_ORDER.find(scene_id)


static func get_next_level(scene_id: String) -> String:
	var idx := LEVEL_ORDER.find(scene_id)
	if idx >= 0 and idx < LEVEL_ORDER.size() - 1:
		return LEVEL_ORDER[idx + 1]
	return ""


static func get_title(scene_id: String) -> String:
	return LEVEL_TITLES.get(scene_id, scene_id)


static func get_day_number(scene_id: String) -> int:
	var idx := LEVEL_ORDER.find(scene_id)
	return idx + 1 if idx >= 0 else 0


static func get_story(scene_id: String, phase: String) -> Array:
	var story: Dictionary = STORY_TEXT.get(scene_id, {})
	return story.get(phase, [])


static func get_objects(scene_id: String) -> Array:
	return LEVEL_OBJECTS.get(scene_id, [])


static func get_puzzle(scene_id: String) -> Dictionary:
	return LEVEL_PUZZLES.get(scene_id, {})
