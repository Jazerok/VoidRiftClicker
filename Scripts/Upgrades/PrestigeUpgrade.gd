class_name PrestigeUpgrade
extends BaseUpgrade

## PrestigeUpgrade - Permanent upgrades bought with Star Dust

enum PrestigeBonusType {
	GLOBAL_MULTIPLIER,
	CLICK_MULTIPLIER,
	PASSIVE_MULTIPLIER,
	STARTING_ENERGY,
	STAR_DUST_BONUS
}

var bonus_type: int = PrestigeBonusType.GLOBAL_MULTIPLIER
var bonus_value: float = 1.0


func _init() -> void:
	category = UpgradeCategory.PRESTIGE
	max_purchases = 1
	starts_visible = true
	starts_unlocked = true


func apply_effect() -> void:
	match bonus_type:
		PrestigeBonusType.GLOBAL_MULTIPLIER:
			GameManager.increase_global_multiplier(bonus_value)
			pass
		PrestigeBonusType.CLICK_MULTIPLIER:
			GameManager.increase_click_multiplier(bonus_value)
			pass
		PrestigeBonusType.PASSIVE_MULTIPLIER:
			GameManager.increase_passive_multiplier(bonus_value)
			pass
		PrestigeBonusType.STARTING_ENERGY:
			GameManager.add_void_energy(BigNumber.new(bonus_value))
			pass
		PrestigeBonusType.STAR_DUST_BONUS:
			pass


func get_effect_description() -> String:
	match bonus_type:
		PrestigeBonusType.GLOBAL_MULTIPLIER:
			return "x%s all income (permanent)" % bonus_value
		PrestigeBonusType.CLICK_MULTIPLIER:
			return "x%s click power (permanent)" % bonus_value
		PrestigeBonusType.PASSIVE_MULTIPLIER:
			return "x%s passive income (permanent)" % bonus_value
		PrestigeBonusType.STARTING_ENERGY:
			return "+%s starting energy" % BigNumber.new(bonus_value).to_formatted_string()
		PrestigeBonusType.STAR_DUST_BONUS:
			return "+%d%% Star Dust gain" % [bonus_value * 100]
		_:
			return "Unknown bonus"


# ═══════════════════════════════════════════════════════════════════════════
# TIER 1: EARLY PRESTIGE (1-5 Star Dust)
# ═══════════════════════════════════════════════════════════════════════════

static func create_starting_boost() -> PrestigeUpgrade:
	var upgrade := PrestigeUpgrade.new()
	upgrade.id = "prestige_starting_boost"
	upgrade.display_name = "Starting Boost"
	upgrade.description = "Begin each new run with 1,000 Void Energy. A small head start!"
	upgrade.bonus_type = PrestigeBonusType.STARTING_ENERGY
	upgrade.bonus_value = 1000
	upgrade.base_cost_value = 1
	upgrade.base_cost_exponent = 0
	return upgrade


static func create_keen_eye() -> PrestigeUpgrade:
	var upgrade := PrestigeUpgrade.new()
	upgrade.id = "prestige_keen_eye"
	upgrade.display_name = "Keen Eye"
	upgrade.description = "Your experience grants +25% click power permanently."
	upgrade.bonus_type = PrestigeBonusType.CLICK_MULTIPLIER
	upgrade.bonus_value = 1.25
	upgrade.base_cost_value = 2
	upgrade.base_cost_exponent = 0
	return upgrade


static func create_efficient_systems() -> PrestigeUpgrade:
	var upgrade := PrestigeUpgrade.new()
	upgrade.id = "prestige_efficient_systems"
	upgrade.display_name = "Efficient Systems"
	upgrade.description = "Generators are 25% more efficient permanently."
	upgrade.bonus_type = PrestigeBonusType.PASSIVE_MULTIPLIER
	upgrade.bonus_value = 1.25
	upgrade.base_cost_value = 3
	upgrade.base_cost_exponent = 0
	return upgrade


static func create_head_start() -> PrestigeUpgrade:
	var upgrade := PrestigeUpgrade.new()
	upgrade.id = "prestige_head_start"
	upgrade.display_name = "Head Start"
	upgrade.description = "Begin each run with 100,000 Void Energy!"
	upgrade.bonus_type = PrestigeBonusType.STARTING_ENERGY
	upgrade.bonus_value = 100000
	upgrade.base_cost_value = 5
	upgrade.base_cost_exponent = 0
	return upgrade


# ═══════════════════════════════════════════════════════════════════════════
# TIER 2: MID PRESTIGE (10-25 Star Dust)
# ═══════════════════════════════════════════════════════════════════════════

static func create_void_touched() -> PrestigeUpgrade:
	var upgrade := PrestigeUpgrade.new()
	upgrade.id = "prestige_void_touched"
	upgrade.display_name = "Void Touched"
	upgrade.description = "Your connection to the void grants x1.5 ALL income!"
	upgrade.bonus_type = PrestigeBonusType.GLOBAL_MULTIPLIER
	upgrade.bonus_value = 1.5
	upgrade.base_cost_value = 10
	upgrade.base_cost_exponent = 0
	return upgrade


static func create_resonance_amplifier() -> PrestigeUpgrade:
	var upgrade := PrestigeUpgrade.new()
	upgrade.id = "prestige_resonance_amp"
	upgrade.display_name = "Resonance Amplifier"
	upgrade.description = "Gain 25% more Star Dust from each Galaxy Reset!"
	upgrade.bonus_type = PrestigeBonusType.STAR_DUST_BONUS
	upgrade.bonus_value = 0.25
	upgrade.base_cost_value = 15
	upgrade.base_cost_exponent = 0
	return upgrade


static func create_master_clicker() -> PrestigeUpgrade:
	var upgrade := PrestigeUpgrade.new()
	upgrade.id = "prestige_master_clicker"
	upgrade.display_name = "Master Clicker"
	upgrade.description = "x2 click power permanently!"
	upgrade.bonus_type = PrestigeBonusType.CLICK_MULTIPLIER
	upgrade.bonus_value = 2.0
	upgrade.base_cost_value = 20
	upgrade.base_cost_exponent = 0
	return upgrade


static func create_automation_expert() -> PrestigeUpgrade:
	var upgrade := PrestigeUpgrade.new()
	upgrade.id = "prestige_automation_expert"
	upgrade.display_name = "Automation Expert"
	upgrade.description = "x2 passive income from all generators!"
	upgrade.bonus_type = PrestigeBonusType.PASSIVE_MULTIPLIER
	upgrade.bonus_value = 2.0
	upgrade.base_cost_value = 25
	upgrade.base_cost_exponent = 0
	return upgrade


# ═══════════════════════════════════════════════════════════════════════════
# TIER 3: LATE PRESTIGE (50-100 Star Dust)
# ═══════════════════════════════════════════════════════════════════════════

static func create_void_affinity() -> PrestigeUpgrade:
	var upgrade := PrestigeUpgrade.new()
	upgrade.id = "prestige_void_affinity"
	upgrade.display_name = "Void Affinity"
	upgrade.description = "Your deep connection to the void DOUBLES all income!"
	upgrade.bonus_type = PrestigeBonusType.GLOBAL_MULTIPLIER
	upgrade.bonus_value = 2.0
	upgrade.base_cost_value = 50
	upgrade.base_cost_exponent = 0
	return upgrade


static func create_dimensional_mastery() -> PrestigeUpgrade:
	var upgrade := PrestigeUpgrade.new()
	upgrade.id = "prestige_dimensional_mastery"
	upgrade.display_name = "Dimensional Mastery"
	upgrade.description = "Gain 50% more Star Dust from Galaxy Resets!"
	upgrade.bonus_type = PrestigeBonusType.STAR_DUST_BONUS
	upgrade.bonus_value = 0.50
	upgrade.base_cost_value = 75
	upgrade.base_cost_exponent = 0
	return upgrade


static func create_wealth_beyond_measure() -> PrestigeUpgrade:
	var upgrade := PrestigeUpgrade.new()
	upgrade.id = "prestige_wealth"
	upgrade.display_name = "Wealth Beyond Measure"
	upgrade.description = "Begin each run with 10 BILLION Void Energy!"
	upgrade.bonus_type = PrestigeBonusType.STARTING_ENERGY
	upgrade.bonus_value = 10_000_000_000
	upgrade.base_cost_value = 100
	upgrade.base_cost_exponent = 0
	return upgrade


# ═══════════════════════════════════════════════════════════════════════════
# TIER 4: END GAME (200+ Star Dust)
# ═══════════════════════════════════════════════════════════════════════════

static func create_cosmic_enlightenment() -> PrestigeUpgrade:
	var upgrade := PrestigeUpgrade.new()
	upgrade.id = "prestige_cosmic_enlightenment"
	upgrade.display_name = "Cosmic Enlightenment"
	upgrade.description = "x5 ALL income! You've transcended normal limits."
	upgrade.bonus_type = PrestigeBonusType.GLOBAL_MULTIPLIER
	upgrade.bonus_value = 5.0
	upgrade.base_cost_value = 200
	upgrade.base_cost_exponent = 0
	return upgrade


static func create_reality_weaver() -> PrestigeUpgrade:
	var upgrade := PrestigeUpgrade.new()
	upgrade.id = "prestige_reality_weaver"
	upgrade.display_name = "Reality Weaver"
	upgrade.description = "DOUBLE all Star Dust gains! Stack with other bonuses."
	upgrade.bonus_type = PrestigeBonusType.STAR_DUST_BONUS
	upgrade.bonus_value = 1.0
	upgrade.base_cost_value = 500
	upgrade.base_cost_exponent = 0
	return upgrade


static func create_void_emperor() -> PrestigeUpgrade:
	var upgrade := PrestigeUpgrade.new()
	upgrade.id = "prestige_void_emperor"
	upgrade.display_name = "Void Emperor"
	upgrade.description = "x10 ALL income! You rule the void itself!"
	upgrade.bonus_type = PrestigeBonusType.GLOBAL_MULTIPLIER
	upgrade.bonus_value = 10.0
	upgrade.base_cost_value = 1000
	upgrade.base_cost_exponent = 0
	return upgrade
