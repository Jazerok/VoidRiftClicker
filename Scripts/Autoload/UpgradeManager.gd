extends Node

## UpgradeManager - Central manager for all upgrades in the game

signal upgrade_purchased(upgrade_id: String, new_count: int)
signal upgrade_revealed(upgrade_id: String)
signal upgrade_unlocked(upgrade_id: String)
signal upgrades_refreshed()

var _upgrades: Dictionary = {}
var _upgrade_order: Array[String] = []


func _ready() -> void:
	_register_all_upgrades()
	pass


func _process(delta: float) -> void:
	_check_upgrade_states()
	_update_special_upgrades(delta)


func _register_all_upgrades() -> void:
	# Click Power Upgrades
	_register_upgrade(ClickUpgrade.create_quantum_tap())
	_register_upgrade(ClickUpgrade.create_void_infusion())
	_register_upgrade(ClickUpgrade.create_dimensional_force())
	_register_upgrade(ClickUpgrade.create_reality_breaker())

	# Generators
	_register_upgrade(PassiveUpgrade.create_probe_drone())
	_register_upgrade(PassiveUpgrade.create_mining_satellite())
	_register_upgrade(PassiveUpgrade.create_harvester_ship())
	_register_upgrade(PassiveUpgrade.create_orbital_station())
	_register_upgrade(PassiveUpgrade.create_dyson_collector())
	_register_upgrade(PassiveUpgrade.create_wormhole_siphon())
	_register_upgrade(PassiveUpgrade.create_galaxy_harvester())
	_register_upgrade(PassiveUpgrade.create_universe_engine())

	# Multipliers
	_register_upgrade(MultiplierUpgrade.create_efficiency_1())
	_register_upgrade(MultiplierUpgrade.create_generator_boost_1())
	_register_upgrade(MultiplierUpgrade.create_efficiency_2())
	_register_upgrade(MultiplierUpgrade.create_generator_boost_2())
	_register_upgrade(MultiplierUpgrade.create_efficiency_3())
	_register_upgrade(MultiplierUpgrade.create_synergy_bonus())

	# Special/Ability Upgrades
	_register_upgrade(SpecialUpgrade.create_critical_click())
	_register_upgrade(SpecialUpgrade.create_double_tap())
	_register_upgrade(SpecialUpgrade.create_patient_collector())
	_register_upgrade(SpecialUpgrade.create_lucky_star())
	_register_upgrade(SpecialUpgrade.create_overdrive_ability())
	_register_upgrade(SpecialUpgrade.create_energy_surge_ability())
	_register_upgrade(SpecialUpgrade.create_time_warp_ability())
	_register_upgrade(SpecialUpgrade.create_void_blast_ability())
	_register_upgrade(SpecialUpgrade.create_fortunes_favor_ability())

	# Initialize visibility
	for upgrade in _upgrades.values():
		upgrade.check_visibility()
		upgrade.check_unlock()


func _register_upgrade(upgrade: BaseUpgrade) -> void:
	if upgrade.id.is_empty():
		push_error("UpgradeManager: Attempted to register upgrade with empty ID!")
		return

	if _upgrades.has(upgrade.id):
		push_error("UpgradeManager: Duplicate upgrade ID: %s" % upgrade.id)
		return

	_upgrades[upgrade.id] = upgrade
	_upgrade_order.append(upgrade.id)


func get_upgrade(id: String) -> BaseUpgrade:
	return _upgrades.get(id)


func get_upgrades_by_category(category: int) -> Array[BaseUpgrade]:
	var result: Array[BaseUpgrade] = []
	for upgrade in _upgrades.values():
		if upgrade.category == category:
			result.append(upgrade)
	return result


func get_visible_upgrades() -> Array[BaseUpgrade]:
	var result: Array[BaseUpgrade] = []
	for upgrade in _upgrades.values():
		if upgrade.is_visible:
			result.append(upgrade)
	return result


func get_all_upgrades() -> Array[BaseUpgrade]:
	var result: Array[BaseUpgrade] = []
	for id in _upgrade_order:
		result.append(_upgrades[id])
	return result


func get_total_upgrades_owned() -> int:
	var count := 0
	for upgrade: BaseUpgrade in _upgrades.values():
		if upgrade.is_owned:
			count += 1
	return count


func get_total_upgrade_purchases() -> int:
	var total := 0
	for upgrade: BaseUpgrade in _upgrades.values():
		total += upgrade.owned_count
	return total


func purchase_upgrade(id: String) -> bool:
	var upgrade := get_upgrade(id)
	if not upgrade:
		push_error("UpgradeManager: Unknown upgrade ID: %s" % id)
		return false

	var success := upgrade.purchase()
	if success:
		upgrade_purchased.emit(id, upgrade.owned_count)
		_check_upgrade_states()

	return success


func purchase_upgrade_bulk(id: String, count: int) -> int:
	var upgrade := get_upgrade(id)
	if not upgrade:
		return 0

	var purchased := upgrade.purchase_bulk(count)
	if purchased > 0:
		upgrade_purchased.emit(id, upgrade.owned_count)
		_check_upgrade_states()

	return purchased


func purchase_upgrade_max(id: String) -> int:
	var upgrade := get_upgrade(id)
	if not upgrade:
		return 0

	var affordable := upgrade.get_affordable_count(GameManager.void_energy)
	return purchase_upgrade_bulk(id, affordable)


func _check_upgrade_states() -> void:
	for upgrade: BaseUpgrade in _upgrades.values():
		var was_visible: bool = upgrade.is_visible
		var was_unlocked: bool = upgrade.is_unlocked

		if upgrade.check_visibility() and not was_visible:
			upgrade_revealed.emit(upgrade.id)
			pass

		if upgrade.check_unlock() and not was_unlocked:
			upgrade_unlocked.emit(upgrade.id)
			pass

	_check_synergy_unlock()


func _check_synergy_unlock() -> void:
	var synergy := get_upgrade("mult_synergy") as MultiplierUpgrade
	if not synergy or synergy.is_unlocked:
		return

	var generators := get_upgrades_by_category(BaseUpgrade.UpgradeCategory.GENERATOR)
	var types_owned := 0
	for g in generators:
		if g.is_owned:
			types_owned += 1

	if types_owned >= 5:
		synergy.is_visible = true
		synergy.is_unlocked = true
		upgrade_revealed.emit(synergy.id)
		upgrade_unlocked.emit(synergy.id)
		pass


func _update_special_upgrades(delta: float) -> void:
	for upgrade: BaseUpgrade in _upgrades.values():
		if upgrade is SpecialUpgrade and upgrade.is_owned:
			(upgrade as SpecialUpgrade).update_timers(delta)


func reset_for_prestige() -> void:
	for upgrade: BaseUpgrade in _upgrades.values():
		if upgrade.category == BaseUpgrade.UpgradeCategory.PRESTIGE:
			continue
		upgrade.reset(false)

	# Re-apply prestige effects
	for upgrade in get_upgrades_by_category(BaseUpgrade.UpgradeCategory.PRESTIGE):
		for i in upgrade.owned_count:
			upgrade.apply_effect()

	upgrades_refreshed.emit()
	pass


func get_save_data() -> Dictionary:
	var data := {}
	for id in _upgrades:
		data[id] = _upgrades[id].get_save_data()
	return data


func load_save_data(data: Dictionary) -> void:
	for id in data:
		if _upgrades.has(id):
			var upgrade_data: Dictionary = data[id]
			_upgrades[id].load_save_data(upgrade_data)
		else:
			pass

	_reapply_all_effects()
	upgrades_refreshed.emit()
	pass


func _reapply_all_effects() -> void:
	for id in _upgrade_order:
		var upgrade: BaseUpgrade = _upgrades[id]
		for i in upgrade.owned_count:
			upgrade.apply_effect()


func get_critical_multiplier() -> float:
	for upgrade: BaseUpgrade in _upgrades.values():
		if upgrade is SpecialUpgrade and upgrade.is_owned:
			var crit: float = (upgrade as SpecialUpgrade).check_critical_click()
			if crit > 1.0:
				return crit
	return 1.0


func get_night_shift_multiplier() -> float:
	var night_shift := get_upgrade("special_night_shift") as SpecialUpgrade
	if night_shift:
		return night_shift.check_night_shift()
	return 1.0


func get_speed_demon_multiplier() -> float:
	var speed_demon := get_upgrade("special_speed_demon") as SpecialUpgrade
	if speed_demon:
		return speed_demon.check_speed_demon()
	return 1.0


func is_double_tap_active() -> bool:
	var double_tap := get_upgrade("special_double_tap") as SpecialUpgrade
	return double_tap and double_tap.is_owned


func activate_overdrive() -> bool:
	var overdrive := get_upgrade("special_overdrive") as SpecialUpgrade
	return overdrive and overdrive.activate_manual()
