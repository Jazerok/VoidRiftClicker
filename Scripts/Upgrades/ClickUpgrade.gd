class_name ClickUpgrade
extends BaseUpgrade

## ClickUpgrade - Upgrades that increase click power

var click_power_bonus_value: float = 1.0
var click_power_bonus_exponent: int = 0


func _init() -> void:
	category = UpgradeCategory.CLICK_POWER


func get_click_power_bonus() -> BigNumber:
	return BigNumber.new(click_power_bonus_value, click_power_bonus_exponent)


func apply_effect() -> void:
	GameManager.increase_base_click_power(get_click_power_bonus())
	pass


func get_effect_description() -> String:
	return "+%s click power per level" % get_click_power_bonus().to_formatted_string()


# ═══════════════════════════════════════════════════════════════════════════
# STATIC FACTORY METHODS
# ═══════════════════════════════════════════════════════════════════════════

static func create_quantum_tap() -> ClickUpgrade:
	var upgrade := ClickUpgrade.new()
	upgrade.id = "click_quantum_tap"
	upgrade.display_name = "Quantum Tap"
	upgrade.description = "Harness quantum fluctuations to increase your tapping power."
	upgrade.click_power_bonus_value = 1
	upgrade.click_power_bonus_exponent = 0
	upgrade.base_cost_value = 100
	upgrade.base_cost_exponent = 0
	upgrade.cost_multiplier = 1.15
	upgrade.max_purchases = -1
	upgrade.starts_visible = false
	upgrade.starts_unlocked = true
	upgrade.visibility_threshold_value = 50
	upgrade.visibility_threshold_exponent = 0
	return upgrade


static func create_void_infusion() -> ClickUpgrade:
	var upgrade := ClickUpgrade.new()
	upgrade.id = "click_void_infusion"
	upgrade.display_name = "Void Infusion"
	upgrade.description = "Infuse your clicks with raw void energy for increased power."
	upgrade.click_power_bonus_value = 5
	upgrade.click_power_bonus_exponent = 0
	upgrade.base_cost_value = 5
	upgrade.base_cost_exponent = 3  # 5,000
	upgrade.cost_multiplier = 1.15
	upgrade.max_purchases = -1
	upgrade.starts_visible = false
	upgrade.starts_unlocked = true
	upgrade.visibility_threshold_value = 2.5
	upgrade.visibility_threshold_exponent = 3  # 2,500
	return upgrade


static func create_dimensional_force() -> ClickUpgrade:
	var upgrade := ClickUpgrade.new()
	upgrade.id = "click_dimensional_force"
	upgrade.display_name = "Dimensional Force"
	upgrade.description = "Channel the power of parallel dimensions into each tap."
	upgrade.click_power_bonus_value = 25
	upgrade.click_power_bonus_exponent = 0
	upgrade.base_cost_value = 5
	upgrade.base_cost_exponent = 5  # 500,000
	upgrade.cost_multiplier = 1.15
	upgrade.max_purchases = -1
	upgrade.starts_visible = false
	upgrade.starts_unlocked = true
	upgrade.visibility_threshold_value = 2.5
	upgrade.visibility_threshold_exponent = 5  # 250,000
	return upgrade


static func create_reality_breaker() -> ClickUpgrade:
	var upgrade := ClickUpgrade.new()
	upgrade.id = "click_reality_breaker"
	upgrade.display_name = "Reality Breaker"
	upgrade.description = "Your taps now shatter the fabric of reality itself!"
	upgrade.click_power_bonus_value = 100
	upgrade.click_power_bonus_exponent = 0
	upgrade.base_cost_value = 5
	upgrade.base_cost_exponent = 8  # 500,000,000
	upgrade.cost_multiplier = 1.15
	upgrade.max_purchases = -1
	upgrade.starts_visible = false
	upgrade.starts_unlocked = true
	upgrade.visibility_threshold_value = 2.5
	upgrade.visibility_threshold_exponent = 8  # 250M
	return upgrade
