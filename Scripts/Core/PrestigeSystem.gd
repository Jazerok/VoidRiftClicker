class_name PrestigeSystem
extends Node

## PrestigeSystem - Handles the "Galaxy Reset" prestige mechanic

signal prestige_status_updated(can_prestige: bool, potential_reward: String)
signal prestige_confirm_requested(star_dust_amount: String, bonuses: String)
signal prestige_complete(star_dust_earned: String)

const PRESTIGE_DIVISOR: float = 1_000_000_000.0  # 1 billion
static var MINIMUM_PRESTIGE_ENERGY: BigNumber = BigNumber.new(1, 9)  # 1 billion


static func calculate_star_dust(total_energy_earned: BigNumber) -> BigNumber:
	if total_energy_earned.less_than(MINIMUM_PRESTIGE_ENERGY):
		return BigNumber.zero()

	var divided := total_energy_earned.divide(BigNumber.new(PRESTIGE_DIVISOR))
	return divided.sqrt_()


static func calculate_energy_for_star_dust(target_star_dust: BigNumber) -> BigNumber:
	var squared := target_star_dust.power(2)
	return squared.multiply(PRESTIGE_DIVISOR)


static func calculate_progress_to_next(total_energy_earned: BigNumber) -> float:
	var current_sd := calculate_star_dust(total_energy_earned)
	var next_sd := current_sd.add(BigNumber.new(1))

	var energy_for_current := calculate_energy_for_star_dust(current_sd)
	var energy_for_next := calculate_energy_for_star_dust(next_sd)

	var current_progress := total_energy_earned.subtract(energy_for_current)
	var total_needed := energy_for_next.subtract(energy_for_current)

	if total_needed.is_zero:
		return 0.0

	return current_progress.divide(total_needed).to_double()


static func can_prestige() -> bool:
	return GameManager.potential_star_dust.greater_than(BigNumber.zero())


static func perform_prestige() -> BigNumber:
	var star_dust_earned := GameManager.potential_star_dust

	if star_dust_earned.is_zero:
		print("PrestigeSystem: Cannot prestige - insufficient progress")
		return BigNumber.zero()

	print("PrestigeSystem: Performing Galaxy Reset for %s Star Dust" % star_dust_earned.to_formatted_string())

	GameManager.add_star_dust(star_dust_earned)
	GameManager.perform_prestige()

	if UpgradeManager:
		UpgradeManager.reset_for_prestige()

	if AudioManager:
		AudioManager.play_prestige_sfx()

	print("PrestigeSystem: Galaxy Reset complete! Total Star Dust: %s" % GameManager.star_dust.to_formatted_string())

	return star_dust_earned


static func get_prestige_status_text() -> String:
	var potential := GameManager.potential_star_dust

	if potential.is_zero:
		var needed := MINIMUM_PRESTIGE_ENERGY.subtract(GameManager.total_void_energy_earned)
		return "Need %s more energy to prestige" % needed.to_formatted_string()

	return "Galaxy Reset available!\nReward: +%s Star Dust" % potential.to_formatted_string()


static func get_prestige_info() -> Dictionary:
	var current_sd := GameManager.star_dust
	var potential_sd := GameManager.potential_star_dust
	var total_after := current_sd.add(potential_sd)

	return {
		"can_prestige": not potential_sd.is_zero,
		"current_star_dust": current_sd,
		"potential_star_dust": potential_sd,
		"total_after_prestige": total_after,
		"prestige_count": GameManager.prestige_count,
		"total_energy_earned": GameManager.total_void_energy_earned,
		"progress_to_next": calculate_progress_to_next(GameManager.total_void_energy_earned)
	}
