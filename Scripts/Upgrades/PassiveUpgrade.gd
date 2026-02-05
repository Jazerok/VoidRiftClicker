class_name PassiveUpgrade
extends BaseUpgrade

## PassiveUpgrade - Generators that automatically earn energy over time

var production_per_second_value: float = 1.0
var production_per_second_exponent: int = 0
var tier: int = 1
var previous_tier_requirement: int = 10
var previous_tier_upgrade_id: String = ""


func _init() -> void:
	category = UpgradeCategory.GENERATOR


func get_production_per_second() -> BigNumber:
	return BigNumber.new(production_per_second_value, production_per_second_exponent)


func apply_effect() -> void:
	GameManager.increase_base_passive_income(get_production_per_second())
	print("PassiveUpgrade %s: Applied +%s/sec" % [id, get_production_per_second().to_formatted_string()])


func get_effect_description() -> String:
	return "+%s/sec per unit" % get_production_per_second().to_formatted_string()


func get_total_production() -> BigNumber:
	return get_production_per_second().multiply(owned_count)


func check_visibility() -> bool:
	if is_visible:
		return true

	# First tier is always visible
	if tier == 1:
		is_visible = starts_visible
		return is_visible

	# Check if player owns enough of the previous tier
	if not previous_tier_upgrade_id.is_empty():
		var previous_tier := UpgradeManager.get_upgrade(previous_tier_upgrade_id)
		if previous_tier and previous_tier.owned_count >= previous_tier_requirement:
			is_visible = true
			return true

	# Also check standard visibility threshold
	return super.check_visibility()


# ═══════════════════════════════════════════════════════════════════════════
# STATIC FACTORY METHODS
# ═══════════════════════════════════════════════════════════════════════════

static func create_probe_drone() -> PassiveUpgrade:
	var upgrade := PassiveUpgrade.new()
	upgrade.id = "gen_probe_drone"
	upgrade.display_name = "Probe Drone"
	upgrade.description = "A small automated drone that harvests void energy from the portal."
	upgrade.tier = 1
	upgrade.production_per_second_value = 0.1
	upgrade.production_per_second_exponent = 0
	upgrade.base_cost_value = 15
	upgrade.base_cost_exponent = 0
	upgrade.cost_multiplier = 1.15
	upgrade.max_purchases = -1
	upgrade.starts_visible = true
	upgrade.starts_unlocked = true
	upgrade.previous_tier_upgrade_id = ""
	upgrade.previous_tier_requirement = 0
	return upgrade


static func create_mining_satellite() -> PassiveUpgrade:
	var upgrade := PassiveUpgrade.new()
	upgrade.id = "gen_mining_satellite"
	upgrade.display_name = "Mining Satellite"
	upgrade.description = "An orbital platform that extracts energy from dimensional rifts."
	upgrade.tier = 2
	upgrade.production_per_second_value = 1
	upgrade.production_per_second_exponent = 0
	upgrade.base_cost_value = 100
	upgrade.base_cost_exponent = 0
	upgrade.cost_multiplier = 1.15
	upgrade.max_purchases = -1
	upgrade.starts_visible = false
	upgrade.starts_unlocked = true
	upgrade.previous_tier_upgrade_id = "gen_probe_drone"
	upgrade.previous_tier_requirement = 1
	return upgrade


static func create_harvester_ship() -> PassiveUpgrade:
	var upgrade := PassiveUpgrade.new()
	upgrade.id = "gen_harvester_ship"
	upgrade.display_name = "Harvester Ship"
	upgrade.description = "A massive vessel designed to harvest energy across multiple dimensions."
	upgrade.tier = 3
	upgrade.production_per_second_value = 8
	upgrade.production_per_second_exponent = 0
	upgrade.base_cost_value = 1.1
	upgrade.base_cost_exponent = 3  # 1,100
	upgrade.cost_multiplier = 1.15
	upgrade.max_purchases = -1
	upgrade.starts_visible = false
	upgrade.starts_unlocked = true
	upgrade.previous_tier_upgrade_id = "gen_mining_satellite"
	upgrade.previous_tier_requirement = 1
	return upgrade


static func create_orbital_station() -> PassiveUpgrade:
	var upgrade := PassiveUpgrade.new()
	upgrade.id = "gen_orbital_station"
	upgrade.display_name = "Orbital Station"
	upgrade.description = "A space station dedicated to processing dimensional energy on an industrial scale."
	upgrade.tier = 4
	upgrade.production_per_second_value = 47
	upgrade.production_per_second_exponent = 0
	upgrade.base_cost_value = 1.2
	upgrade.base_cost_exponent = 4  # 12,000
	upgrade.cost_multiplier = 1.15
	upgrade.max_purchases = -1
	upgrade.starts_visible = false
	upgrade.starts_unlocked = true
	upgrade.previous_tier_upgrade_id = "gen_harvester_ship"
	upgrade.previous_tier_requirement = 1
	return upgrade


static func create_dyson_collector() -> PassiveUpgrade:
	var upgrade := PassiveUpgrade.new()
	upgrade.id = "gen_dyson_collector"
	upgrade.display_name = "Dyson Collector"
	upgrade.description = "A partial Dyson sphere that harvests energy from an entire star system."
	upgrade.tier = 5
	upgrade.production_per_second_value = 260
	upgrade.production_per_second_exponent = 0
	upgrade.base_cost_value = 1.3
	upgrade.base_cost_exponent = 5  # 130,000
	upgrade.cost_multiplier = 1.15
	upgrade.max_purchases = -1
	upgrade.starts_visible = false
	upgrade.starts_unlocked = true
	upgrade.previous_tier_upgrade_id = "gen_orbital_station"
	upgrade.previous_tier_requirement = 1
	return upgrade


static func create_wormhole_siphon() -> PassiveUpgrade:
	var upgrade := PassiveUpgrade.new()
	upgrade.id = "gen_wormhole_siphon"
	upgrade.display_name = "Wormhole Siphon"
	upgrade.description = "Extracts raw energy directly from naturally occurring wormholes."
	upgrade.tier = 6
	upgrade.production_per_second_value = 1.4
	upgrade.production_per_second_exponent = 3  # 1,400
	upgrade.base_cost_value = 1.4
	upgrade.base_cost_exponent = 6  # 1,400,000
	upgrade.cost_multiplier = 1.15
	upgrade.max_purchases = -1
	upgrade.starts_visible = false
	upgrade.starts_unlocked = true
	upgrade.previous_tier_upgrade_id = "gen_dyson_collector"
	upgrade.previous_tier_requirement = 1
	return upgrade


static func create_galaxy_harvester() -> PassiveUpgrade:
	var upgrade := PassiveUpgrade.new()
	upgrade.id = "gen_galaxy_harvester"
	upgrade.display_name = "Galaxy Harvester"
	upgrade.description = "An impossibly large construct that drains energy from an entire galaxy."
	upgrade.tier = 7
	upgrade.production_per_second_value = 7.8
	upgrade.production_per_second_exponent = 3  # 7,800
	upgrade.base_cost_value = 2
	upgrade.base_cost_exponent = 7  # 20,000,000
	upgrade.cost_multiplier = 1.15
	upgrade.max_purchases = -1
	upgrade.starts_visible = false
	upgrade.starts_unlocked = true
	upgrade.previous_tier_upgrade_id = "gen_wormhole_siphon"
	upgrade.previous_tier_requirement = 1
	return upgrade


static func create_universe_engine() -> PassiveUpgrade:
	var upgrade := PassiveUpgrade.new()
	upgrade.id = "gen_universe_engine"
	upgrade.display_name = "Universe Engine"
	upgrade.description = "The ultimate creation - a machine that harvests the death of universes themselves."
	upgrade.tier = 8
	upgrade.production_per_second_value = 4.4
	upgrade.production_per_second_exponent = 4  # 44,000
	upgrade.base_cost_value = 3.3
	upgrade.base_cost_exponent = 8  # 330,000,000
	upgrade.cost_multiplier = 1.15
	upgrade.max_purchases = -1
	upgrade.starts_visible = false
	upgrade.starts_unlocked = true
	upgrade.previous_tier_upgrade_id = "gen_galaxy_harvester"
	upgrade.previous_tier_requirement = 1
	return upgrade
