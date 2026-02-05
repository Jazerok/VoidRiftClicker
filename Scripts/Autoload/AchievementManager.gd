extends Node

## AchievementManager - Tracks and awards achievements

signal achievement_unlocked(achievement_id: String, achievement_name: String, description: String)
signal achievement_progress(achievement_id: String, progress: float)

var _achievements: Dictionary = {}
var achievement_multiplier: float = 1.0

var unlocked_count: int:
	get:
		var count := 0
		for ach in _achievements.values():
			if ach.is_unlocked:
				count += 1
		return count

var total_count: int:
	get: return _achievements.size()


func _ready() -> void:
	_register_all_achievements()
	print("AchievementManager: Registered %d achievements" % _achievements.size())


func _process(_delta: float) -> void:
	_check_all_achievements()


func _register_all_achievements() -> void:
	_register_click_milestones()
	_register_income_milestones()
	_register_speed_achievements()
	_register_collection_achievements()
	_register_prestige_achievements()
	_register_secret_achievements()


func _register_click_milestones() -> void:
	var milestones := [
		["clicks_100", "First Steps", 100, "Click the portal 100 times"],
		["clicks_1k", "Getting Warmed Up", 1000, "Click the portal 1,000 times"],
		["clicks_10k", "Click Enthusiast", 10000, "Click the portal 10,000 times"],
		["clicks_100k", "Click Addict", 100000, "Click the portal 100,000 times"],
		["clicks_1m", "Click Maniac", 1000000, "Click the portal 1,000,000 times"],
		["clicks_10m", "Click Legend", 10000000, "Click the portal 10,000,000 times"],
	]

	for m in milestones:
		_register(Achievement.new(m[0], m[1], m[3], Achievement.Category.CLICK_MILESTONE, m[2],
			func(): return GameManager.total_clicks, 0.01))


func _register_income_milestones() -> void:
	var milestones := [
		["income_1k", "Small Fortune", 3, "Earn 1,000 total Void Energy"],
		["income_1m", "Millionaire", 6, "Earn 1,000,000 total Void Energy"],
		["income_1b", "Billionaire", 9, "Earn 1,000,000,000 total Void Energy"],
		["income_1t", "Trillionaire", 12, "Earn 1 trillion total Void Energy"],
		["income_1qa", "Quadrillionaire", 15, "Earn 1 quadrillion total Void Energy"],
		["income_1qi", "Quintillionaire", 18, "Earn 1 quintillion total Void Energy"],
	]

	for m in milestones:
		_register(Achievement.new(m[0], m[1], m[3], Achievement.Category.INCOME_MILESTONE, pow(10, m[2]),
			func(): return GameManager.total_void_energy_earned.to_double(), 0.02))


func _register_speed_achievements() -> void:
	_register(Achievement.new("speed_10cps", "Quick Fingers", "Reach 10 clicks per second",
		Achievement.Category.SPEED_RECORD, 10.0, func(): return GameManager.current_cps, 0.01))

	_register(Achievement.new("speed_max", "Speed Limit", "Click at the maximum allowed rate",
		Achievement.Category.SPEED_RECORD, 1.0, func():
			return 1.0 if GameManager.current_cps >= GameManager.max_clicks_per_second else 0.0, 0.02))

	_register(Achievement.new("frenzy_first", "First Frenzy", "Activate frenzy mode for the first time",
		Achievement.Category.SPEED_RECORD, 1.0, func():
			return 1.0 if GameManager.is_frenzy_active else 0.0, 0.02))


func _register_collection_achievements() -> void:
	_register(Achievement.new("collect_10", "Collector", "Own 10 different upgrades",
		Achievement.Category.COLLECTION, 10.0, func():
			return UpgradeManager.get_total_upgrades_owned() if UpgradeManager else 0, 0.02))

	_register(Achievement.new("collect_25", "Hoarder", "Own 25 different upgrades",
		Achievement.Category.COLLECTION, 25.0, func():
			return UpgradeManager.get_total_upgrades_owned() if UpgradeManager else 0, 0.03))

	_register(Achievement.new("generators_all", "Full Fleet", "Own at least one of each generator type",
		Achievement.Category.COLLECTION, 8.0, func():
			if not UpgradeManager:
				return 0
			var generators := UpgradeManager.get_upgrades_by_category(BaseUpgrade.UpgradeCategory.GENERATOR)
			var count := 0
			for g in generators:
				if g.is_owned:
					count += 1
			return count, 0.05))


func _register_prestige_achievements() -> void:
	_register(Achievement.new("prestige_1", "New Beginning", "Perform your first Galaxy Reset",
		Achievement.Category.PRESTIGE, 1.0, func(): return GameManager.prestige_count, 0.05))

	_register(Achievement.new("prestige_5", "Cycle of Rebirth", "Perform 5 Galaxy Resets",
		Achievement.Category.PRESTIGE, 5.0, func(): return GameManager.prestige_count, 0.05))

	_register(Achievement.new("prestige_10", "Eternal Recurrence", "Perform 10 Galaxy Resets",
		Achievement.Category.PRESTIGE, 10.0, func(): return GameManager.prestige_count, 0.10))


func _register_secret_achievements() -> void:
	var ach := Achievement.new("secret_night", "Night Owl", "Play the game between midnight and 4 AM",
		Achievement.Category.SECRET, 1.0, func():
			var hour: int = Time.get_datetime_dict_from_system().hour
			return 1.0 if hour >= 0 and hour < 4 else 0.0, 0.02)
	ach.is_hidden = true
	_register(ach)

	var patience_ach := Achievement.new("secret_patience", "Patience", "Wait 5 minutes without clicking",
		Achievement.Category.SECRET, 1.0, func(): return 0.0, 0.03)
	patience_ach.is_hidden = true
	_register(patience_ach)


func _register(achievement: Achievement) -> void:
	_achievements[achievement.id] = achievement


func _check_all_achievements() -> void:
	for achievement: Achievement in _achievements.values():
		if achievement.is_unlocked:
			continue

		var current_value: float = 0.0
		if achievement.check_condition:
			current_value = achievement.check_condition.call()
		var progress: float = current_value / achievement.required_value

		if progress != achievement.progress:
			achievement.progress = progress
			achievement_progress.emit(achievement.id, progress)

		if current_value >= achievement.required_value:
			_unlock_achievement(achievement)


func _unlock_achievement(achievement: Achievement) -> void:
	if achievement.is_unlocked:
		return

	achievement.is_unlocked = true
	achievement.unlocked_at = Time.get_datetime_string_from_system()

	achievement_multiplier *= (1 + achievement.bonus_multiplier)
	GameManager.increase_global_multiplier(1 + achievement.bonus_multiplier)

	achievement_unlocked.emit(achievement.id, achievement.name, achievement.description)

	print("Achievement Unlocked: %s!" % achievement.name)

	if SaveManager:
		SaveManager.mark_unsaved_changes()


func force_unlock(id: String) -> void:
	if _achievements.has(id):
		_unlock_achievement(_achievements[id])


func get_achievement(id: String) -> Achievement:
	return _achievements.get(id)


func get_by_category(category: int) -> Array[Achievement]:
	var result: Array[Achievement] = []
	for ach in _achievements.values():
		if ach.category == category:
			result.append(ach)
	return result


func get_unlocked() -> Array[Achievement]:
	var result: Array[Achievement] = []
	for ach in _achievements.values():
		if ach.is_unlocked:
			result.append(ach)
	return result


func get_visible() -> Array[Achievement]:
	var result: Array[Achievement] = []
	for ach in _achievements.values():
		if not ach.is_hidden or ach.is_unlocked:
			result.append(ach)
	return result


func get_save_data() -> Dictionary:
	var data := {}
	for id in _achievements:
		if _achievements[id].is_unlocked:
			data[id] = true
	data["multiplier"] = achievement_multiplier
	return data


func load_save_data(data: Dictionary) -> void:
	achievement_multiplier = 1.0

	for key in data:
		if key == "multiplier":
			achievement_multiplier = data[key]
			continue
		if _achievements.has(key):
			_achievements[key].is_unlocked = data[key]
			_achievements[key].progress = 1.0

	print("AchievementManager: Loaded %d achievements" % unlocked_count)


func reset_all() -> void:
	for ach in _achievements.values():
		ach.is_unlocked = false
		ach.progress = 0
		ach.unlocked_at = ""
	achievement_multiplier = 1.0
	print("AchievementManager: All achievements reset!")


class Achievement:
	enum Category { CLICK_MILESTONE, INCOME_MILESTONE, SPEED_RECORD, COLLECTION, PRESTIGE, SECRET }

	var id: String
	var name: String
	var description: String
	var category: int
	var is_hidden: bool = false
	var is_unlocked: bool = false
	var unlocked_at: String = ""
	var progress: float = 0.0
	var required_value: float = 1.0
	var check_condition: Callable
	var bonus_multiplier: float = 0.01

	func _init(p_id: String, p_name: String, p_desc: String, p_cat: int, p_required: float, p_check: Callable, p_bonus: float = 0.01) -> void:
		id = p_id
		name = p_name
		description = p_desc
		category = p_cat
		required_value = p_required
		check_condition = p_check
		bonus_multiplier = p_bonus
