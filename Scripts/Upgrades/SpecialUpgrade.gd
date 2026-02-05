class_name SpecialUpgrade
extends BaseUpgrade

## SpecialUpgrade - Interactive and unique upgrades with special mechanics

enum SpecialEffectType {
	CRITICAL_CLICK,
	CLICK_FRENZY,
	COMBO_MASTER,
	OVERDRIVE,
	DOUBLE_TAP,
	NIGHT_SHIFT,
	SPEED_DEMON,
	PATIENT_COLLECTOR,
	LUCKY_STAR,
	MAX_CPS_BONUS,
	ABILITY_UNLOCK
}

var effect_type: int = SpecialEffectType.CRITICAL_CLICK
var effect_strength: float = 2.0
var effect_chance: float = 0.05
var effect_duration: float = 10.0
var cooldown: float = 0.0

# Runtime state (not saved)
var is_effect_active: bool = false
var effect_time_remaining: float = 0.0
var cooldown_remaining: float = 0.0


func _init() -> void:
	category = UpgradeCategory.INTERACTIVE
	max_purchases = 1


func apply_effect() -> void:
	print("SpecialUpgrade %s: Enabled %s" % [id, SpecialEffectType.keys()[effect_type]])

	match effect_type:
		SpecialEffectType.DOUBLE_TAP:
			pass  # Handled in click processing
		SpecialEffectType.MAX_CPS_BONUS:
			GameManager.increase_max_cps(int(effect_strength))
		SpecialEffectType.ABILITY_UNLOCK:
			_unlock_hotbar_ability()


func _unlock_hotbar_ability() -> void:
	var ability_id: String = ""
	match id:
		"ability_critical_click": ability_id = "critical_click"
		"ability_double_tap": ability_id = "double_tap"
		"ability_patient_collector": ability_id = "patient_collector"
		"ability_lucky_star": ability_id = "lucky_star"
		"ability_overdrive": ability_id = "overdrive"
		"ability_energy_surge": ability_id = "energy_surge"
		"ability_time_warp": ability_id = "time_warp"
		"ability_void_blast": ability_id = "void_blast"
		"ability_fortunes_favor": ability_id = "fortunes_favor"

	if ability_id.is_empty():
		push_error("SpecialUpgrade: Unknown ability upgrade ID: %s" % id)
		return

	var hotbar = GameManager.get_tree().root.find_child("AbilityHotbar", true, false)
	if hotbar and hotbar.has_method("unlock_ability"):
		hotbar.unlock_ability(ability_id)
		print("SpecialUpgrade: Unlocked ability '%s' via upgrade '%s'" % [ability_id, id])
	else:
		push_error("SpecialUpgrade: Could not find AbilityHotbar to unlock ability '%s'" % ability_id)


func get_effect_description() -> String:
	match effect_type:
		SpecialEffectType.CRITICAL_CLICK:
			return "%d%% chance for x%s click" % [effect_chance * 100, effect_strength]
		SpecialEffectType.CLICK_FRENZY:
			return "x%s for %ss when clicking fast" % [effect_strength, effect_duration]
		SpecialEffectType.COMBO_MASTER:
			return "+%d%% per second of fast clicking" % [effect_strength * 100]
		SpecialEffectType.OVERDRIVE:
			return "x%s for %ss (manual activation)" % [effect_strength, effect_duration]
		SpecialEffectType.DOUBLE_TAP:
			return "Each click counts as 2 clicks"
		SpecialEffectType.NIGHT_SHIFT:
			return "x%s income between 10PM-6AM" % effect_strength
		SpecialEffectType.SPEED_DEMON:
			return "x%s when clicking at max CPS" % effect_strength
		SpecialEffectType.PATIENT_COLLECTOR:
			return "x%s passive if no clicks for %ss" % [effect_strength, effect_duration]
		SpecialEffectType.LUCKY_STAR:
			return "Random x2-x10 boost every %s minutes" % [cooldown / 60]
		SpecialEffectType.MAX_CPS_BONUS:
			return "+%s max clicks per second" % effect_strength
		SpecialEffectType.ABILITY_UNLOCK:
			return "Unlock hotbar ability"
		_:
			return "Special effect"


func check_critical_click() -> float:
	if effect_type != SpecialEffectType.CRITICAL_CLICK:
		return 1.0
	if not is_owned:
		return 1.0

	if randf() < effect_chance:
		return effect_strength

	return 1.0


func check_night_shift() -> float:
	if effect_type != SpecialEffectType.NIGHT_SHIFT:
		return 1.0
	if not is_owned:
		return 1.0

	var hour: int = Time.get_datetime_dict_from_system().hour
	if hour >= 22 or hour < 6:
		return effect_strength

	return 1.0


func check_speed_demon() -> float:
	if effect_type != SpecialEffectType.SPEED_DEMON:
		return 1.0
	if not is_owned:
		return 1.0

	if GameManager.current_cps >= GameManager.max_clicks_per_second - 1:
		return effect_strength

	return 1.0


func activate_manual() -> bool:
	if effect_type != SpecialEffectType.OVERDRIVE:
		return false
	if not is_owned:
		return false
	if cooldown_remaining > 0:
		return false

	is_effect_active = true
	effect_time_remaining = effect_duration
	cooldown_remaining = cooldown

	print("SpecialUpgrade %s: Overdrive activated! x%s for %ss" % [id, effect_strength, effect_duration])
	return true


func update_timers(delta: float) -> void:
	if is_effect_active and effect_time_remaining > 0:
		effect_time_remaining -= delta
		if effect_time_remaining <= 0:
			is_effect_active = false
			effect_time_remaining = 0
			print("SpecialUpgrade %s: Effect ended" % id)

	if cooldown_remaining > 0:
		cooldown_remaining -= delta
		if cooldown_remaining < 0:
			cooldown_remaining = 0


# ═══════════════════════════════════════════════════════════════════════════
# STATIC FACTORY METHODS
# ═══════════════════════════════════════════════════════════════════════════

static func create_critical_click() -> SpecialUpgrade:
	var upgrade := SpecialUpgrade.new()
	upgrade.id = "ability_critical_click"
	upgrade.display_name = "Critical Click"
	upgrade.description = "Unlock the Critical Click ability: 100% crit chance for 8 seconds (45s cooldown). Press 1 to activate."
	upgrade.effect_type = SpecialEffectType.ABILITY_UNLOCK
	upgrade.effect_strength = 20.0
	upgrade.base_cost_value = 5
	upgrade.base_cost_exponent = 4  # 50,000
	upgrade.max_purchases = 1
	upgrade.starts_visible = false
	upgrade.starts_unlocked = true
	upgrade.visibility_threshold_value = 2.5
	upgrade.visibility_threshold_exponent = 4  # 25,000
	return upgrade


static func create_double_tap() -> SpecialUpgrade:
	var upgrade := SpecialUpgrade.new()
	upgrade.id = "ability_double_tap"
	upgrade.display_name = "Double Tap"
	upgrade.description = "Unlock the Double Tap ability: Clicks count as 2 for 10 seconds (30s cooldown). Press 2 to activate."
	upgrade.effect_type = SpecialEffectType.ABILITY_UNLOCK
	upgrade.effect_strength = 2.0
	upgrade.base_cost_value = 5
	upgrade.base_cost_exponent = 5  # 500,000
	upgrade.max_purchases = 1
	upgrade.starts_visible = false
	upgrade.starts_unlocked = true
	upgrade.visibility_threshold_value = 2.5
	upgrade.visibility_threshold_exponent = 5  # 250,000
	return upgrade


static func create_patient_collector() -> SpecialUpgrade:
	var upgrade := SpecialUpgrade.new()
	upgrade.id = "ability_patient_collector"
	upgrade.display_name = "Patient Collector"
	upgrade.description = "Unlock the Patience ability: x5 passive income for 12 seconds (60s cooldown). Press 3 to activate."
	upgrade.effect_type = SpecialEffectType.ABILITY_UNLOCK
	upgrade.effect_strength = 5.0
	upgrade.base_cost_value = 5
	upgrade.base_cost_exponent = 6  # 5,000,000
	upgrade.max_purchases = 1
	upgrade.starts_visible = false
	upgrade.starts_unlocked = true
	upgrade.visibility_threshold_value = 2.5
	upgrade.visibility_threshold_exponent = 6  # 2,500,000
	return upgrade


static func create_lucky_star() -> SpecialUpgrade:
	var upgrade := SpecialUpgrade.new()
	upgrade.id = "ability_lucky_star"
	upgrade.display_name = "Lucky Star"
	upgrade.description = "Unlock the Lucky Star ability: Random x2-x10 boost for 15 seconds (90s cooldown). Press 4 to activate."
	upgrade.effect_type = SpecialEffectType.ABILITY_UNLOCK
	upgrade.effect_strength = 5.0
	upgrade.base_cost_value = 5
	upgrade.base_cost_exponent = 7  # 50,000,000
	upgrade.max_purchases = 1
	upgrade.starts_visible = false
	upgrade.starts_unlocked = true
	upgrade.visibility_threshold_value = 2.5
	upgrade.visibility_threshold_exponent = 7  # 25,000,000
	return upgrade


static func create_overdrive_ability() -> SpecialUpgrade:
	var upgrade := SpecialUpgrade.new()
	upgrade.id = "ability_overdrive"
	upgrade.display_name = "Overdrive"
	upgrade.description = "Unlock the Overdrive ability: x5 all income for 5 seconds (45s cooldown). Press 5 to activate."
	upgrade.effect_type = SpecialEffectType.ABILITY_UNLOCK
	upgrade.effect_strength = 5.0
	upgrade.base_cost_value = 5
	upgrade.base_cost_exponent = 8  # 500,000,000
	upgrade.max_purchases = 1
	upgrade.starts_visible = false
	upgrade.starts_unlocked = true
	upgrade.visibility_threshold_value = 2.5
	upgrade.visibility_threshold_exponent = 8  # 250,000,000
	return upgrade


static func create_energy_surge_ability() -> SpecialUpgrade:
	var upgrade := SpecialUpgrade.new()
	upgrade.id = "ability_energy_surge"
	upgrade.display_name = "Energy Surge"
	upgrade.description = "Unlock the Energy Surge ability: Gain 10 seconds of passive income instantly (60s cooldown). Press 6 to activate."
	upgrade.effect_type = SpecialEffectType.ABILITY_UNLOCK
	upgrade.effect_strength = 10.0
	upgrade.base_cost_value = 5
	upgrade.base_cost_exponent = 9  # 5,000,000,000
	upgrade.max_purchases = 1
	upgrade.starts_visible = false
	upgrade.starts_unlocked = true
	upgrade.visibility_threshold_value = 2.5
	upgrade.visibility_threshold_exponent = 9  # 2,500,000,000
	return upgrade


static func create_time_warp_ability() -> SpecialUpgrade:
	var upgrade := SpecialUpgrade.new()
	upgrade.id = "ability_time_warp"
	upgrade.display_name = "Time Warp"
	upgrade.description = "Unlock the Time Warp ability: x3 passive income for 15 seconds (90s cooldown). Press 7 to activate."
	upgrade.effect_type = SpecialEffectType.ABILITY_UNLOCK
	upgrade.effect_strength = 3.0
	upgrade.base_cost_value = 5
	upgrade.base_cost_exponent = 10  # 50,000,000,000
	upgrade.max_purchases = 1
	upgrade.starts_visible = false
	upgrade.starts_unlocked = true
	upgrade.visibility_threshold_value = 2.5
	upgrade.visibility_threshold_exponent = 10  # 25,000,000,000
	return upgrade


static func create_void_blast_ability() -> SpecialUpgrade:
	var upgrade := SpecialUpgrade.new()
	upgrade.id = "ability_void_blast"
	upgrade.display_name = "Void Blast"
	upgrade.description = "Unlock the Void Blast ability: x20 mega-click (30s cooldown). Press 8 to activate."
	upgrade.effect_type = SpecialEffectType.ABILITY_UNLOCK
	upgrade.effect_strength = 20.0
	upgrade.base_cost_value = 5
	upgrade.base_cost_exponent = 11  # 500,000,000,000
	upgrade.max_purchases = 1
	upgrade.starts_visible = false
	upgrade.starts_unlocked = true
	upgrade.visibility_threshold_value = 2.5
	upgrade.visibility_threshold_exponent = 11  # 250,000,000,000
	return upgrade


static func create_fortunes_favor_ability() -> SpecialUpgrade:
	var upgrade := SpecialUpgrade.new()
	upgrade.id = "ability_fortunes_favor"
	upgrade.display_name = "Fortune's Favor"
	upgrade.description = "Unlock the Fortune's Favor ability: x3 critical chance for 20 seconds (120s cooldown). Press 9 to activate."
	upgrade.effect_type = SpecialEffectType.ABILITY_UNLOCK
	upgrade.effect_strength = 3.0
	upgrade.base_cost_value = 5
	upgrade.base_cost_exponent = 12  # 5,000,000,000,000
	upgrade.max_purchases = 1
	upgrade.starts_visible = false
	upgrade.starts_unlocked = true
	upgrade.visibility_threshold_value = 2.5
	upgrade.visibility_threshold_exponent = 12  # 2,500,000,000,000
	return upgrade
