class_name MultiplierUpgrade
extends BaseUpgrade

## MultiplierUpgrade - Upgrades that multiply income by a percentage

enum MultiplierTarget {
	CLICK,
	PASSIVE,
	GLOBAL
}

var multiplier: float = 2.0
var target: int = MultiplierTarget.GLOBAL


func _init() -> void:
	category = UpgradeCategory.MULTIPLIER
	max_purchases = 1


func apply_effect() -> void:
	match target:
		MultiplierTarget.CLICK:
			GameManager.increase_click_multiplier(multiplier)
			print("MultiplierUpgrade %s: Click multiplier x%s" % [id, multiplier])
		MultiplierTarget.PASSIVE:
			GameManager.increase_passive_multiplier(multiplier)
			print("MultiplierUpgrade %s: Passive multiplier x%s" % [id, multiplier])
		MultiplierTarget.GLOBAL:
			GameManager.increase_global_multiplier(multiplier)
			print("MultiplierUpgrade %s: Global multiplier x%s" % [id, multiplier])


func get_effect_description() -> String:
	var target_name: String
	match target:
		MultiplierTarget.CLICK:
			target_name = "click"
		MultiplierTarget.PASSIVE:
			target_name = "passive"
		MultiplierTarget.GLOBAL:
			target_name = "all"
		_:
			target_name = "unknown"

	return "x%s %s income" % [multiplier, target_name]


# ═══════════════════════════════════════════════════════════════════════════
# STATIC FACTORY METHODS
# ═══════════════════════════════════════════════════════════════════════════

static func create_efficiency_1() -> MultiplierUpgrade:
	var upgrade := MultiplierUpgrade.new()
	upgrade.id = "mult_efficiency_1"
	upgrade.display_name = "Efficiency I"
	upgrade.description = "Your clicking technique improves, doubling click power!"
	upgrade.multiplier = 2.0
	upgrade.target = MultiplierTarget.CLICK
	upgrade.base_cost_value = 1
	upgrade.base_cost_exponent = 3  # 1,000
	upgrade.max_purchases = 1
	upgrade.starts_visible = false
	upgrade.starts_unlocked = true
	upgrade.visibility_threshold_value = 500
	upgrade.visibility_threshold_exponent = 0
	return upgrade


static func create_efficiency_2() -> MultiplierUpgrade:
	var upgrade := MultiplierUpgrade.new()
	upgrade.id = "mult_efficiency_2"
	upgrade.display_name = "Efficiency II"
	upgrade.description = "Advanced clicking mastery grants another doubling!"
	upgrade.multiplier = 2.0
	upgrade.target = MultiplierTarget.CLICK
	upgrade.base_cost_value = 5
	upgrade.base_cost_exponent = 4  # 50,000
	upgrade.max_purchases = 1
	upgrade.starts_visible = false
	upgrade.starts_unlocked = true
	upgrade.visibility_threshold_value = 2.5
	upgrade.visibility_threshold_exponent = 4  # 25,000
	return upgrade


static func create_efficiency_3() -> MultiplierUpgrade:
	var upgrade := MultiplierUpgrade.new()
	upgrade.id = "mult_efficiency_3"
	upgrade.display_name = "Efficiency III"
	upgrade.description = "Expert-level clicking efficiency!"
	upgrade.multiplier = 2.0
	upgrade.target = MultiplierTarget.CLICK
	upgrade.base_cost_value = 5
	upgrade.base_cost_exponent = 6  # 5,000,000
	upgrade.max_purchases = 1
	upgrade.starts_visible = false
	upgrade.starts_unlocked = true
	upgrade.visibility_threshold_value = 2.5
	upgrade.visibility_threshold_exponent = 6  # 2,500,000
	return upgrade


static func create_generator_boost_1() -> MultiplierUpgrade:
	var upgrade := MultiplierUpgrade.new()
	upgrade.id = "mult_gen_boost_1"
	upgrade.display_name = "Generator Boost I"
	upgrade.description = "Optimize your generators for double output!"
	upgrade.multiplier = 2.0
	upgrade.target = MultiplierTarget.PASSIVE
	upgrade.base_cost_value = 1
	upgrade.base_cost_exponent = 4  # 10,000
	upgrade.max_purchases = 1
	upgrade.starts_visible = false
	upgrade.starts_unlocked = true
	upgrade.visibility_threshold_value = 5
	upgrade.visibility_threshold_exponent = 3  # 5,000
	return upgrade


static func create_generator_boost_2() -> MultiplierUpgrade:
	var upgrade := MultiplierUpgrade.new()
	upgrade.id = "mult_gen_boost_2"
	upgrade.display_name = "Generator Boost II"
	upgrade.description = "Advanced generator optimization!"
	upgrade.multiplier = 2.0
	upgrade.target = MultiplierTarget.PASSIVE
	upgrade.base_cost_value = 1
	upgrade.base_cost_exponent = 6  # 1,000,000
	upgrade.max_purchases = 1
	upgrade.starts_visible = false
	upgrade.starts_unlocked = true
	upgrade.visibility_threshold_value = 5
	upgrade.visibility_threshold_exponent = 5  # 500,000
	return upgrade


static func create_synergy_bonus() -> MultiplierUpgrade:
	var upgrade := MultiplierUpgrade.new()
	upgrade.id = "mult_synergy"
	upgrade.display_name = "Synergy Bonus"
	upgrade.description = "Your generators work together, boosting ALL income by 50%!"
	upgrade.multiplier = 1.5
	upgrade.target = MultiplierTarget.GLOBAL
	upgrade.base_cost_value = 1
	upgrade.base_cost_exponent = 8  # 100,000,000
	upgrade.max_purchases = 1
	upgrade.starts_visible = false
	upgrade.starts_unlocked = false  # Requires special unlock (own 5 generator types)
	upgrade.is_mystery = true
	return upgrade


static func create_void_affinity() -> MultiplierUpgrade:
	var upgrade := MultiplierUpgrade.new()
	upgrade.id = "prestige_void_affinity"
	upgrade.display_name = "Void Affinity"
	upgrade.description = "Your connection to the void doubles ALL income permanently!"
	upgrade.multiplier = 2.0
	upgrade.target = MultiplierTarget.GLOBAL
	upgrade.base_cost_value = 100
	upgrade.base_cost_exponent = 0
	upgrade.max_purchases = 1
	upgrade.category = BaseUpgrade.UpgradeCategory.PRESTIGE
	upgrade.starts_visible = true
	upgrade.starts_unlocked = true
	return upgrade
