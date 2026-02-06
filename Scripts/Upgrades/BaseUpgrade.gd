class_name BaseUpgrade
extends RefCounted

## BaseUpgrade - The foundation class for all upgrades in the game

enum UpgradeCategory {
	CLICK_POWER,
	GENERATOR,
	MULTIPLIER,
	INTERACTIVE,
	MYSTERY,
	PRESTIGE
}

# Upgrade Identity
var id: String = ""
var display_name: String = "Unknown Upgrade"
var description: String = "No description"
var category: int = UpgradeCategory.CLICK_POWER
var icon: Texture2D = null

# Purchase Settings
var base_cost_value: float = 10.0
var base_cost_exponent: int = 0
var cost_multiplier: float = 1.15
var max_purchases: int = -1  # -1 = unlimited

# Visibility Settings
var is_visible: bool = false
var is_unlocked: bool = false
var starts_visible: bool = true
var starts_unlocked: bool = true
var is_mystery: bool = false
var visibility_threshold_value: float = 0.0
var visibility_threshold_exponent: int = 0

# Ownership State
var owned_count: int = 0

var is_owned: bool:
	get: return owned_count > 0

var can_purchase_more: bool:
	get: return max_purchases == -1 or owned_count < max_purchases


func get_base_cost() -> BigNumber:
	return BigNumber.new(base_cost_value, base_cost_exponent)


func get_visibility_threshold() -> BigNumber:
	return BigNumber.new(visibility_threshold_value, visibility_threshold_exponent)


func get_current_cost() -> BigNumber:
	var multiplier := pow(cost_multiplier, owned_count)
	return get_base_cost().multiply(multiplier)


func get_bulk_cost(count: int) -> BigNumber:
	if count <= 0:
		return BigNumber.zero()
	if count == 1:
		return get_current_cost()

	# Geometric series sum: a × (r^n - 1) / (r - 1)
	var first_cost := get_current_cost()
	var r := cost_multiplier
	var sum_multiplier := (pow(r, count) - 1) / (r - 1)

	return first_cost.multiply(sum_multiplier)


func get_affordable_count(budget: BigNumber) -> int:
	if budget.less_than(get_current_cost()):
		return 0

	# Binary search for max affordable count
	var low := 1
	var high := 1000 if max_purchases == -1 else max_purchases - owned_count

	while low < high:
		var mid := (low + high + 1) / 2
		if budget.greater_than_or_equal(get_bulk_cost(mid)):
			low = mid
		else:
			high = mid - 1

	return low


func purchase() -> bool:
	if not can_purchase_more:
		pass
		return false

	if not is_unlocked:
		pass
		return false

	var cost := get_current_cost()
	var is_prestige := category == UpgradeCategory.PRESTIGE

	if is_prestige:
		if not GameManager.can_afford_star_dust(cost):
			pass
			return false
		GameManager.spend_star_dust(cost)
	else:
		if not GameManager.can_afford(cost):
			pass
			return false
		GameManager.spend_void_energy(cost)

	owned_count += 1
	apply_effect()

	if SaveManager:
		SaveManager.mark_unsaved_changes()

	pass
	return true


func purchase_bulk(count: int) -> int:
	var available := count if max_purchases == -1 else mini(count, max_purchases - owned_count)
	if available <= 0:
		return 0

	var is_prestige := category == UpgradeCategory.PRESTIGE
	var currency: BigNumber = GameManager.star_dust if is_prestige else GameManager.void_energy

	var affordable := get_affordable_count(currency)
	var to_purchase := mini(available, affordable)
	if to_purchase <= 0:
		return 0

	var total_cost := get_bulk_cost(to_purchase)

	if is_prestige:
		GameManager.spend_star_dust(total_cost)
	else:
		GameManager.spend_void_energy(total_cost)

	for i in to_purchase:
		owned_count += 1
		apply_effect()

	if SaveManager:
		SaveManager.mark_unsaved_changes()

	pass
	return to_purchase


## Override this in child classes to define what the upgrade does
func apply_effect() -> void:
	pass


## Override this in child classes to provide effect description
func get_effect_description() -> String:
	return "No effect"


func check_visibility() -> bool:
	if is_visible:
		return true

	var threshold := get_visibility_threshold()
	if not threshold.is_zero:
		if GameManager.total_void_energy_earned.greater_than_or_equal(threshold):
			is_visible = true
			return true
	elif starts_visible:
		is_visible = true
		return true

	return false


func check_unlock() -> bool:
	if is_unlocked:
		return true

	if not is_visible:
		return false

	if starts_unlocked:
		is_unlocked = true
		return true

	return false


func reset(keep_progress: bool = false) -> void:
	if not keep_progress:
		owned_count = 0
		is_visible = starts_visible
		is_unlocked = starts_unlocked


func get_save_data() -> Dictionary:
	return {
		"owned": owned_count,
		"visible": is_visible,
		"unlocked": is_unlocked
	}


func load_save_data(data: Dictionary) -> void:
	owned_count = data.get("owned", 0)
	is_visible = data.get("visible", false)
	is_unlocked = data.get("unlocked", false)
