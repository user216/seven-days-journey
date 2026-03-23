extends Node
## All practicum card definitions — transcribed from bot/practicum_data.py.
## Single source of truth for card content in the game.

# ── Card structure ────────────────────────────────────────────────
# Each card is a Dictionary with keys: time, slot_id, title, emoji, text

const TOTAL_CARDS_PER_DAY := 16
const DAY_SLOT_IDS: Array[String] = ["mp", "nc", "dc", "lc", "ep"]

# ── Routine cards (same every day) ────────────────────────────────

const ROUTINE_CARDS: Array[Dictionary] = [
	{
		"time": "04:30", "slot_id": "wk", "title": "Подъём", "emoji": "🌅",
		"text": "Доброе утро. Постарайтесь проснуться в промежутке с 4 до 5 утра. Это время спокойствия и ясности ума. Не спешите. Сделайте несколько спокойных вдохов и почувствуйте начало нового дня.",
	},
	{
		"time": "05:15", "slot_id": "wp", "title": "Утренние водные процедуры", "emoji": "🚿",
		"text": "Сделайте утренние процедуры.\nОчистите язык, промойте нос, умойтесь прохладной водой. Эти простые действия помогают мягко пробудить организм и подготовить тело к практике.",
	},
	{
		"time": "06:00", "slot_id": "tp", "title": "Тихая пауза", "emoji": "🧘",
		"text": "После практики уделите 10–15 минут спокойствию.\nПосидите с закрытыми глазами или просто спокойно подышите.",
	},
	{
		"time": "06:15", "slot_id": "pl", "title": "Планирование дня", "emoji": "📝",
		"text": "Откройте свой дневник и запишите мысли или планы на день.\nКакие три вещи сегодня для вас важны?",
	},
	{
		"time": "06:30", "slot_id": "wl", "title": "Прогулка", "emoji": "🚶",
		"text": "Перед завтраком сделайте небольшую прогулку.\nИдите спокойно, наблюдая природу, небо, воздух вокруг вас.\nДаже 10–15 минут такой прогулки помогают телу мягко проснуться.",
	},
	{
		"time": "07:00", "slot_id": "bf", "title": "Завтрак", "emoji": "🥣",
		"text": "Лёгкий и тёплый завтрак.\n\nПодойдут:\n• каша\n• фрукты\n• ягоды\n• тёплый травяной чай\n\nСтарайтесь есть спокойно и без спешки.",
	},
	{
		"time": "10:30", "slot_id": "b2", "title": "Второй завтрак", "emoji": "🍎",
		"text": "Небольшой перекус, чтобы поддержать энергию.\n\nПодойдут:\n• фрукты\n• орехи\n• йогурт\n• смузи",
	},
	{
		"time": "13:00", "slot_id": "lu", "title": "Обед", "emoji": "🍲",
		"text": "Это основной приём пищи.\n\nРекомендуется:\n• овощной суп\n• крупы\n• салат\n• рыба или птица\n\nЕшьте спокойно и не торопясь.",
	},
	{
		"time": "18:00", "slot_id": "dn", "title": "Ужин", "emoji": "🥗",
		"text": "Ужин должен быть лёгким.\n\nПодойдут:\n• овощи\n• салаты\n• тушёные блюда\n• лёгкий белок\n\nЖелательно закончить ужин за 2–3 часа до сна.",
	},
	{
		"time": "21:30", "slot_id": "bp", "title": "Подготовка ко сну", "emoji": "🛁",
		"text": "Сделайте спокойные вечерние ритуалы.\nМожно принять тёплый душ, записать мысли в дневник, поблагодарить этот день.",
	},
	{
		"time": "22:00", "slot_id": "gn", "title": "Спокойной ночи", "emoji": "🌙",
		"text": "Постарайтесь лечь спать в промежутке с 22 до 23 часов.\nПоблагодарите себя за прожитый день и за то, что вы продолжаете этот путь.",
	},
]

# ── Day-specific cards ────────────────────────────────────────────

const DAY_CARDS: Dictionary = {
	1: [
		{
			"time": "05:30", "slot_id": "mp", "title": "Утренняя практика", "emoji": "🧘‍♀️",
			"text": "Статическая практика с поднятыми руками\n\nСесть с прямой спиной, поднять руки вверх и удерживать положение.\nПрактика выполняется спокойно, почти без движения.\n\nЦель:\n• концентрация\n• включение тела утром\n• развитие внутренней устойчивости",
		},
		{
			"time": "06:30", "slot_id": "nc", "title": "Карточка питания", "emoji": "🥗",
			"text": "Легкое питание без мяса.\nРыба или птица допускаются в обед.\n\nПример меню:\n• завтрак — каша и фрукт\n• обед — овощной суп, гарнир, рыба или птица\n• ужин — тушеные овощи или салат",
		},
		{
			"time": "06:35", "slot_id": "dc", "title": "Питьевой режим", "emoji": "💧",
			"text": "Рекомендации на день:\n• начать утро со стакана теплой воды\n• пить воду между приемами пищи\n• средний объем — около 1,5–2 литров в течение дня",
		},
		{
			"time": "14:00", "slot_id": "lc", "title": "Лекция дня: Питание как забота о себе", "emoji": "📚",
			"text": "Темы:\n• как питание влияет на состояние женщины\n• связь питания и энергии\n• роль воды и питьевого режима\n\nЗадание:\nНаблюдать за состоянием после еды.",
		},
		{
			"time": "20:00", "slot_id": "ep", "title": "Вечерняя практика: Тратака", "emoji": "🕯",
			"text": "Сесть перед свечой и смотреть на пламя 2–5 минут.",
		},
	],
	2: [
		{
			"time": "05:30", "slot_id": "mp", "title": "Утренняя практика", "emoji": "🧘‍♀️",
			"text": "Дыхательная практика 20–30 минут.",
		},
		{
			"time": "06:30", "slot_id": "nc", "title": "Карточка питания", "emoji": "🥗",
			"text": "Легкие блюда, простые в приготовлении.",
		},
		{
			"time": "06:35", "slot_id": "dc", "title": "Питьевой режим", "emoji": "💧",
			"text": "Рекомендации по распределению воды в течение дня.",
		},
		{
			"time": "14:00", "slot_id": "lc", "title": "Лекция дня: Связь с природой", "emoji": "📚",
			"text": "Задание:\nПровести 20–30 минут на природе.",
		},
		{
			"time": "20:00", "slot_id": "ep", "title": "Вечерняя практика: Благодарность", "emoji": "🙏",
			"text": "Записать 5 событий дня, за которые можно поблагодарить этот день.",
		},
	],
	3: [
		{
			"time": "05:30", "slot_id": "mp", "title": "Утренняя практика", "emoji": "🧘‍♀️",
			"text": "Упражнения на стуле.\nМягкая гимнастика для спины, плеч и шеи.",
		},
		{
			"time": "06:30", "slot_id": "nc", "title": "Карточка питания", "emoji": "🥗",
			"text": "Рекомендации по питанию на день.",
		},
		{
			"time": "06:35", "slot_id": "dc", "title": "Питьевой режим", "emoji": "💧",
			"text": "Рекомендации по питьевому режиму на день.",
		},
		{
			"time": "14:00", "slot_id": "lc", "title": "Лекция дня: Витамины для женского организма", "emoji": "📚",
			"text": "Задание:\nСоставить список из 5 полезных продуктов.",
		},
		{
			"time": "20:00", "slot_id": "ep", "title": "Вечерняя практика: Тарабарщина", "emoji": "🗣",
			"text": "3–5 минут произносить любые бессмысленные слова.",
		},
	],
	4: [
		{
			"time": "05:30", "slot_id": "mp", "title": "Утренняя практика: Сурья Намаскар", "emoji": "🧘‍♀️",
			"text": "Комплекс «Приветствие солнцу».",
		},
		{
			"time": "06:30", "slot_id": "nc", "title": "Карточка питания", "emoji": "🥗",
			"text": "Рекомендации по питанию на день.",
		},
		{
			"time": "06:35", "slot_id": "dc", "title": "Питьевой режим", "emoji": "💧",
			"text": "Рекомендации по питьевому режиму на день.",
		},
		{
			"time": "14:00", "slot_id": "lc", "title": "Лекция дня: Искусство замедления", "emoji": "📚",
			"text": "Задание:\nПойти на прогулку в платье.\nИдти медленно, наблюдая природу или витрины магазинов.\n\nПосле прогулки ответить:\n• что нового вы увидели в знакомом месте\n• какие чувства испытали",
		},
		{
			"time": "20:00", "slot_id": "ep", "title": "Вечерняя практика: Суфийское кружение", "emoji": "💫",
			"text": "Медленное кружение 2–5 минут.",
		},
	],
	5: [
		{
			"time": "05:30", "slot_id": "mp", "title": "Утренняя практика: Дерево", "emoji": "🧘‍♀️",
			"text": "Практика «Дерево».",
		},
		{
			"time": "06:30", "slot_id": "nc", "title": "Карточка питания", "emoji": "🥗",
			"text": "Рекомендации по питанию на день.",
		},
		{
			"time": "06:35", "slot_id": "dc", "title": "Питьевой режим", "emoji": "💧",
			"text": "Рекомендации по питьевому режиму на день.",
		},
		{
			"time": "14:00", "slot_id": "lc", "title": "Лекция дня: Работа со страхами", "emoji": "📚",
			"text": "Задание — практика прописывания страха:\n1. Написать страх.\n2. Не отрывая руки продолжить писать:\n   «Что было бы, если бы этот страх ушёл.»",
		},
		{
			"time": "20:00", "slot_id": "ep", "title": "Вечерняя практика: Освобождение мыслей", "emoji": "📖",
			"text": "Выписать все мысли и переживания на лист бумаги.",
		},
	],
	6: [
		{
			"time": "05:30", "slot_id": "mp", "title": "Утренняя практика: Активные прыжки", "emoji": "🧘‍♀️",
			"text": "Короткая динамическая практика.",
		},
		{
			"time": "06:30", "slot_id": "nc", "title": "Карточка питания", "emoji": "🥗",
			"text": "Рекомендации по питанию на день.",
		},
		{
			"time": "06:35", "slot_id": "dc", "title": "Питьевой режим", "emoji": "💧",
			"text": "Рекомендации по питьевому режиму на день.",
		},
		{
			"time": "14:00", "slot_id": "lc", "title": "Лекция дня: Женственность и самоценность", "emoji": "📚",
			"text": "Задание:\nЗайти в ювелирный магазин и примерить украшения.",
		},
		{
			"time": "20:00", "slot_id": "ep", "title": "Вечерняя практика: Замедление", "emoji": "🍵",
			"text": "Сделать любое действие очень медленно.\nНапример, пить чай или ухаживать за волосами.",
		},
	],
	7: [
		{
			"time": "05:30", "slot_id": "mp", "title": "Утренняя практика", "emoji": "🧘‍♀️",
			"text": "Асаны и мягкое завершение недели.",
		},
		{
			"time": "06:30", "slot_id": "nc", "title": "Карточка питания", "emoji": "🥗",
			"text": "Рекомендации по питанию на день.",
		},
		{
			"time": "06:35", "slot_id": "dc", "title": "Питьевой режим", "emoji": "💧",
			"text": "Рекомендации по питьевому режиму на день.",
		},
		{
			"time": "14:00", "slot_id": "lc", "title": "Лекция дня: Режим дня как основа гармонии", "emoji": "📚",
			"text": "Итоговая лекция практикума.",
		},
		{
			"time": "20:00", "slot_id": "ep", "title": "Вечерняя практика: Промасливание тела", "emoji": "🌿",
			"text": "Нанести теплое масло на тело мягкими движениями.\n\nМожно использовать масла:\n• лаванда — для спокойствия\n• мелисса — для сна\n• грейпфрут — для обмена веществ\n• герань или роза — для упругости кожи",
		},
	],
}

# ── Level thresholds (identical to bot) ───────────────────────────

const LEVEL_THRESHOLDS: Array[Dictionary] = [
	{"level": 1, "xp": 0, "name": "Новичок"},
	{"level": 2, "xp": 50, "name": "Ученик"},
	{"level": 3, "xp": 150, "name": "Практикант"},
	{"level": 4, "xp": 300, "name": "Последователь"},
	{"level": 5, "xp": 500, "name": "Мастер утра"},
	{"level": 6, "xp": 750, "name": "Гармония"},
	{"level": 7, "xp": 1050, "name": "Наставник"},
	{"level": 8, "xp": 1400, "name": "Мудрец"},
	{"level": 9, "xp": 1800, "name": "Просветлённый"},
	{"level": 10, "xp": 2000, "name": "Легенда"},
]

# ── Achievements (identical to bot/achievements_data.py) ──────────

const ACHIEVEMENTS: Array[Dictionary] = [
	{"key": "first_reaction", "emoji": "🌟", "title": "Первый шаг", "description": "Первая реакция на карточку"},
	{"key": "day_complete", "emoji": "🏅", "title": "Завершённый день", "description": "Все 16 карточек за день"},
	{"key": "perfect_week", "emoji": "🏆", "title": "Идеальная неделя", "description": "112 из 112 за всю неделю"},
	{"key": "streak_3", "emoji": "🔥", "title": "3 дня подряд", "description": "Серия из 3 дней подряд"},
	{"key": "streak_7", "emoji": "💪", "title": "Неделя без перерывов", "description": "Серия из 7 дней подряд"},
	{"key": "early_bird", "emoji": "🐦", "title": "Ранняя пташка", "description": "Реакция до 06:00"},
	{"key": "night_owl", "emoji": "🦉", "title": "Ночная сова", "description": "Реакция на вечернюю практику"},
	{"key": "speed_demon", "emoji": "⚡", "title": "Молниеносный", "description": "Реакция в течение 5 минут после доставки"},
	{"key": "hopa_first_level", "emoji": "🔍", "title": "Первая находка", "description": "Завершён первый уровень Сада Тайн"},
	{"key": "hopa_no_hints", "emoji": "🧠", "title": "Острый глаз", "description": "Уровень без подсказок"},
	{"key": "hopa_speed_run", "emoji": "⏱", "title": "Быстрый поиск", "description": "Уровень менее чем за 60 секунд"},
	{"key": "hopa_all_levels", "emoji": "🏛", "title": "Хранитель Сада", "description": "Все 7 уровней Сада Тайн"},
]

# ── XP rates ──────────────────────────────────────────────────────

const XP_PER_REACTION := 10
const XP_PER_STREAK_DAY := 20
const XP_PER_BEST_STREAK_DAY := 30
const XP_PER_ACHIEVEMENT := 50
const XP_PER_PERFECT_DAY := 25

# ── Slot title lookup ─────────────────────────────────────────────

var SLOT_TITLES: Dictionary = {}

# ── Mini-interaction scene mapping ────────────────────────────────

const INTERACTION_MAP: Dictionary = {
	"wk": "res://scenes/mini_interactions/tap_sunrise.tscn",
	"wp": "res://scenes/mini_interactions/swipe_droplets.tscn",
	"mp": "res://scenes/mini_interactions/hold_pose.tscn",
	"tp": "res://scenes/mini_interactions/breathing_exercise.tscn",
	"pl": "res://scenes/mini_interactions/tap_journal.tscn",
	"wl": "res://scenes/mini_interactions/collect_flowers.tscn",
	"nc": "res://scenes/mini_interactions/flip_cards.tscn",
	"dc": "res://scenes/mini_interactions/drink_water.tscn",
	"bf": "res://scenes/mini_interactions/drag_food.tscn",
	"b2": "res://scenes/mini_interactions/drag_food.tscn",
	"lu": "res://scenes/mini_interactions/drag_food.tscn",
	"dn": "res://scenes/mini_interactions/drag_food.tscn",
	"lc": "res://scenes/mini_interactions/flip_cards.tscn",
	"bp": "res://scenes/mini_interactions/tap_journal.tscn",
	"gn": "res://scenes/mini_interactions/swipe_curtain.tscn",
}

const EP_INTERACTION_MAP: Dictionary = {
	1: "res://scenes/mini_interactions/hold_candle.tscn",
	2: "res://scenes/mini_interactions/tap_gratitude.tscn",
	3: "res://scenes/mini_interactions/gibberish_tap.tscn",
	4: "res://scenes/mini_interactions/sufi_spin.tscn",
	5: "res://scenes/mini_interactions/thought_release.tscn",
	6: "res://scenes/mini_interactions/slow_motion.tscn",
	7: "res://scenes/mini_interactions/body_oil.tscn",
}

# ── Helpers ───────────────────────────────────────────────────────

func _ready() -> void:
	CrashLogger.breadcrumb("GameData._ready")
	_build_slot_titles()


func _build_slot_titles() -> void:
	for card in ROUTINE_CARDS:
		SLOT_TITLES[card.slot_id] = card.title
	for day_num in DAY_CARDS:
		for card in DAY_CARDS[day_num]:
			if card.slot_id not in SLOT_TITLES:
				SLOT_TITLES[card.slot_id] = card.title


func get_all_cards_for_day(day_num: int) -> Array[Dictionary]:
	var day_specific: Array = DAY_CARDS.get(day_num, [])
	var combined: Array[Dictionary] = []
	combined.append_array(ROUTINE_CARDS)
	combined.append_array(day_specific)
	combined.sort_custom(func(a, b): return a.time < b.time or (a.time == b.time and a.slot_id < b.slot_id))
	return combined


func get_card(day_num: int, slot_id: String) -> Dictionary:
	for card in DAY_CARDS.get(day_num, []):
		if card.slot_id == slot_id:
			return card
	for card in ROUTINE_CARDS:
		if card.slot_id == slot_id:
			return card
	return {}


func get_default_slot_times() -> Dictionary:
	var times: Dictionary = {}
	for card in ROUTINE_CARDS:
		times[card.slot_id] = card.time
	for card in DAY_CARDS.get(1, []):
		times[card.slot_id] = card.time
	return times


func get_interaction_scene(slot_id: String, day_num: int) -> String:
	if slot_id == "ep":
		return EP_INTERACTION_MAP.get(day_num, "")
	return INTERACTION_MAP.get(slot_id, "")


func time_to_minutes(time_str: String) -> float:
	var parts := time_str.split(":")
	return float(parts[0]) * 60.0 + float(parts[1])
