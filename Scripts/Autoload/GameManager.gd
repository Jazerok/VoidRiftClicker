extends Node

## GameManager - The heart of the game that manages all game state

# Signals
signal void_energy_changed(formatted_amount: String)
signal dimensional_shards_changed(formatted_amount: String)
signal star_dust_changed(formatted_amount: String)
signal click_registered(formatted_amount: String)
signal passive_income_changed(formatted_rate: String)
signal click_power_changed(formatted_power: String)
signal frenzy_state_changed(is_active: bool, multiplier: float)
signal prestige_performed(star_dust_earned: String)

# Currencies
var _void_energy: BigNumber = BigNumber.new(0)
var void_energy: BigNumber:
	get: return _void_energy
	set(value):
		_void_energy = value
		void_energy_changed.emit(_void_energy.to_formatted_string())

var total_void_energy_earned: BigNumber = BigNumber.new(0)

var _dimensional_shards: BigNumber = BigNumber.new(0)
var dimensional_shards: BigNumber:
	get: return _dimensional_shards
	set(value):
		_dimensional_shards = value
		dimensional_shards_changed.emit(_dimensional_shards.to_formatted_string())

var _star_dust: BigNumber = BigNumber.new(0)
var star_dust: BigNumber:
	get: return _star_dust
	set(value):
		_star_dust = value
		star_dust_changed.emit(_star_dust.to_formatted_string())

# Click Stats
var base_click_power: BigNumber = BigNumber.new(1)
var click_multiplier: float = 1.0
var effective_click_power: BigNumber:
	get: return base_click_power.multiply(click_multiplier * global_multiplier * frenzy_multiplier * _get_ability_click_multiplier())

var total_clicks: int = 0
var _clicks_this_second: int = 0
var current_cps: float = 0.0
var max_clicks_per_second: int = 14
var _cps_timer: float = 0.0

# Passive Income
var base_passive_income: BigNumber = BigNumber.new(0)
var passive_multiplier: float = 1.0
var effective_passive_income: BigNumber:
	get: return base_passive_income.multiply(passive_multiplier * global_multiplier * _get_ability_passive_multiplier())

# Multipliers
var global_multiplier: float = 1.0
var frenzy_multiplier: float = 1.0
var is_frenzy_active: bool = false

# Ability System
var _active_ability_multipliers: Dictionary = {}
var _ability_timers: Dictionary = {}
var _ability_passive_only: Dictionary = {}
var ability_crit_multiplier: float = 1.0
var _crit_boost_timer: float = 0.0
var _frenzy_buildup_timer: float = 0.0
var _frenzy_duration_timer: float = 0.0

# Prestige
var prestige_count: int = 0
var prestige_starting_energy: float = 0.0
var star_dust_multiplier: float = 1.0
var base_crit_chance: float = 0.05
var ability_cooldown_reduction: float = 0.0
var ability_duration_bonus: float = 0.0
var ability_power_bonus: float = 0.0
var generator_discount: float = 0.0

var potential_star_dust: BigNumber:
	get:
		if total_void_energy_earned.exponent < 9:
			return BigNumber.Zero
		var divided := total_void_energy_earned.divide(BigNumber.new(1, 9))
		var base_sd := divided.sqrt_()
		return base_sd.multiply(star_dust_multiplier)

# Time Tracking
var last_played_timestamp: int = 0
var total_play_time: float = 0.0
var _session_time: float = 0.0

var frenzy_time_remaining: float:
	get: return _frenzy_duration_timer


func _ready() -> void:
	print("GameManager: Initialized successfully")


func _process(delta: float) -> void:
	_session_time += delta
	total_play_time += delta
	_cps_timer += delta

	# Update CPS tracking
	if _cps_timer >= 1.0:
		current_cps = _clicks_this_second
		_clicks_this_second = 0
		_cps_timer = 0
		_update_frenzy_state(delta)

	# Apply passive income
	if not base_passive_income.is_zero:
		var passive_gain := effective_passive_income.multiply(delta)
		add_void_energy(passive_gain, true)

	# Update frenzy timer
	if is_frenzy_active:
		_frenzy_duration_timer -= delta
		if _frenzy_duration_timer <= 0:
			_end_frenzy()

	_update_ability_timers(delta)


# Currency Methods

func add_void_energy(amount: BigNumber, count_as_earned: bool = true) -> void:
	void_energy = void_energy.add(amount)
	if count_as_earned:
		total_void_energy_earned = total_void_energy_earned.add(amount)


func spend_void_energy(amount: BigNumber) -> bool:
	if void_energy.greater_than_or_equal(amount):
		void_energy = void_energy.subtract(amount)
		return true
	return false


func can_afford(cost: BigNumber) -> bool:
	return void_energy.greater_than_or_equal(cost)


func add_dimensional_shards(amount: BigNumber) -> void:
	dimensional_shards = dimensional_shards.add(amount)


func add_star_dust(amount: BigNumber) -> void:
	star_dust = star_dust.add(amount)


func spend_star_dust(amount: BigNumber) -> bool:
	if star_dust.greater_than_or_equal(amount):
		star_dust = star_dust.subtract(amount)
		star_dust_changed.emit(star_dust.to_formatted_string())
		return true
	return false


func can_afford_star_dust(cost: BigNumber) -> bool:
	return star_dust.greater_than_or_equal(cost)


# Click Methods

func process_click() -> bool:
	if _clicks_this_second >= max_clicks_per_second:
		return false

	_clicks_this_second += 1
	total_clicks += 1

	var click_energy := effective_click_power
	add_void_energy(click_energy, true)

	click_registered.emit(click_energy.to_formatted_string())

	if AudioManager:
		AudioManager.play_click_sfx()

	if current_cps >= 10:
		_frenzy_buildup_timer += 0.1

	return true


# Upgrade Methods

func increase_base_click_power(amount: BigNumber) -> void:
	base_click_power = base_click_power.add(amount)
	click_power_changed.emit(effective_click_power.to_formatted_string())


func increase_click_multiplier(multiplier: float) -> void:
	click_multiplier *= multiplier
	click_power_changed.emit(effective_click_power.to_formatted_string())


func increase_base_passive_income(amount: BigNumber) -> void:
	base_passive_income = base_passive_income.add(amount)
	passive_income_changed.emit(effective_passive_income.to_formatted_string())


func increase_passive_multiplier(multiplier: float) -> void:
	passive_multiplier *= multiplier
	passive_income_changed.emit(effective_passive_income.to_formatted_string())


func increase_global_multiplier(multiplier: float) -> void:
	global_multiplier *= multiplier
	click_power_changed.emit(effective_click_power.to_formatted_string())
	passive_income_changed.emit(effective_passive_income.to_formatted_string())


func increase_max_cps(amount: int) -> void:
	max_clicks_per_second += amount


# Prestige Bonus Methods

func add_prestige_starting_energy(amount: float) -> void:
	prestige_starting_energy += amount
	print("Prestige: Starting energy bonus increased to %s" % prestige_starting_energy)


func add_star_dust_multiplier(multiplier: float) -> void:
	star_dust_multiplier += multiplier
	print("Prestige: Star Dust multiplier increased to %.0f%%" % (star_dust_multiplier * 100))


func add_base_crit_chance(chance: float) -> void:
	base_crit_chance += chance
	base_crit_chance = minf(base_crit_chance, 1.0)
	print("Prestige: Base crit chance increased to %.0f%%" % (base_crit_chance * 100))


func add_ability_cooldown_reduction(reduction: float) -> void:
	ability_cooldown_reduction += reduction
	ability_cooldown_reduction = minf(ability_cooldown_reduction, 0.90)
	print("Prestige: Ability cooldown reduction increased to %.0f%%" % (ability_cooldown_reduction * 100))


func add_ability_duration_bonus(bonus: float) -> void:
	ability_duration_bonus += bonus
	print("Prestige: Ability duration bonus increased to %.0f%%" % (ability_duration_bonus * 100))


func add_ability_power_bonus(bonus: float) -> void:
	ability_power_bonus += bonus
	print("Prestige: Ability power bonus increased to %.0f%%" % (ability_power_bonus * 100))


func add_generator_discount(discount: float) -> void:
	generator_discount += discount
	generator_discount = minf(generator_discount, 0.90)
	print("Prestige: Generator discount increased to %.0f%%" % (generator_discount * 100))


func get_effective_ability_cooldown() -> float:
	return 1.0 - ability_cooldown_reduction


func get_effective_ability_duration() -> float:
	return 1.0 + ability_duration_bonus


func get_effective_ability_power() -> float:
	return 1.0 + ability_power_bonus


func get_effective_generator_cost_multiplier() -> float:
	return 1.0 - generator_discount


# Frenzy System

func _update_frenzy_state(delta: float) -> void:
	if current_cps >= 5:
		_frenzy_buildup_timer += delta

		if _frenzy_buildup_timer >= 2.0:
			var target_multiplier := 4.0 if current_cps >= 10 else 2.0

			if not is_frenzy_active:
				_activate_frenzy(target_multiplier)
			elif frenzy_multiplier != target_multiplier:
				frenzy_multiplier = target_multiplier
				_frenzy_duration_timer = 10.0
				frenzy_state_changed.emit(true, frenzy_multiplier)
				click_power_changed.emit(effective_click_power.to_formatted_string())
				print("Cosmic Surge upgraded to x%s!" % frenzy_multiplier)
			else:
				_frenzy_duration_timer = maxf(_frenzy_duration_timer, 5.0)
	else:
		_frenzy_buildup_timer = maxf(0, _frenzy_buildup_timer - delta * 2)


func _activate_frenzy(multiplier: float = 2.0) -> void:
	is_frenzy_active = true
	frenzy_multiplier = multiplier
	_frenzy_duration_timer = 10.0

	frenzy_state_changed.emit(true, frenzy_multiplier)
	click_power_changed.emit(effective_click_power.to_formatted_string())

	print("Cosmic Surge activated! x%s multiplier for 10 seconds!" % multiplier)


func _end_frenzy() -> void:
	is_frenzy_active = false
	frenzy_multiplier = 1.0
	_frenzy_buildup_timer = 0

	frenzy_state_changed.emit(false, 1.0)
	click_power_changed.emit(effective_click_power.to_formatted_string())

	print("Cosmic Surge ended.")


func boost_frenzy(boost: float) -> void:
	if is_frenzy_active:
		frenzy_multiplier += boost
		_frenzy_duration_timer = 10.0

		if AudioManager:
			AudioManager.play_surge_boost_sfx()

		frenzy_state_changed.emit(true, frenzy_multiplier)
		click_power_changed.emit(effective_click_power.to_formatted_string())
		print("Cosmic Surge boosted to x%.2f! Timer refreshed to 10s" % frenzy_multiplier)
	else:
		is_frenzy_active = true
		frenzy_multiplier = 1.0 + boost
		_frenzy_duration_timer = 10.0

		if AudioManager:
			AudioManager.play_cosmic_surge_sfx()

		frenzy_state_changed.emit(true, frenzy_multiplier)
		click_power_changed.emit(effective_click_power.to_formatted_string())
		print("Cosmic Surge started at x%.2f! Duration: 10s" % frenzy_multiplier)


func apply_temporary_multiplier(multiplier: float, duration: float, source: String = "Bonus") -> void:
	var ability_id := "temp_%s_%d" % [source, randi()]
	activate_multiplier(ability_id, multiplier, duration, false)


func apply_temporary_crit_boost(bonus_chance: float, duration: float) -> void:
	var new_multiplier := 1.0 + bonus_chance / base_crit_chance
	if _crit_boost_timer > 0:
		ability_crit_multiplier = maxf(ability_crit_multiplier, new_multiplier)
		_crit_boost_timer = maxf(_crit_boost_timer, duration)
	else:
		ability_crit_multiplier = new_multiplier
		_crit_boost_timer = duration
	print("Crit boost: %.0f%% extra chance for %ss (total multiplier: x%.1f)" % [bonus_chance * 100, duration, ability_crit_multiplier])


func get_effective_crit_chance() -> float:
	return minf(base_crit_chance * ability_crit_multiplier, 1.0)


# Ability System

func activate_multiplier(ability_id: String, multiplier: float, duration: float, passive_only: bool = false) -> void:
	_active_ability_multipliers[ability_id] = multiplier
	_ability_timers[ability_id] = duration
	_ability_passive_only[ability_id] = passive_only

	print("Ability %s activated: x%s for %ss" % [ability_id, multiplier, duration])

	click_power_changed.emit(effective_click_power.to_formatted_string())
	passive_income_changed.emit(effective_passive_income.to_formatted_string())


func deactivate_multiplier(ability_id: String) -> void:
	if _active_ability_multipliers.has(ability_id):
		_active_ability_multipliers.erase(ability_id)
		_ability_timers.erase(ability_id)
		_ability_passive_only.erase(ability_id)

		print("Ability %s deactivated" % ability_id)

		click_power_changed.emit(effective_click_power.to_formatted_string())
		passive_income_changed.emit(effective_passive_income.to_formatted_string())


func activate_crit_boost(multiplier: float, duration: float) -> void:
	ability_crit_multiplier = multiplier
	_crit_boost_timer = duration
	print("Crit boost activated: x%s crit chance for %ss" % [multiplier, duration])


func _update_ability_timers(delta: float) -> void:
	var expired_abilities: Array[String] = []
	for ability_id in _ability_timers:
		_ability_timers[ability_id] -= delta
		if _ability_timers[ability_id] <= 0:
			expired_abilities.append(ability_id)

	for id in expired_abilities:
		deactivate_multiplier(id)

	if _crit_boost_timer > 0:
		_crit_boost_timer -= delta
		if _crit_boost_timer <= 0:
			ability_crit_multiplier = 1.0
			print("Crit boost ended")


func _get_ability_click_multiplier() -> float:
	var mult := 1.0
	for ability_id in _active_ability_multipliers:
		if _ability_passive_only.get(ability_id, false):
			continue
		mult *= _active_ability_multipliers[ability_id]
	return mult


func _get_ability_passive_multiplier() -> float:
	var mult := 1.0
	for ability_id in _active_ability_multipliers:
		mult *= _active_ability_multipliers[ability_id]
	return mult


# Prestige System

func perform_prestige() -> bool:
	prestige_count += 1

	void_energy = BigNumber.new(0)
	total_void_energy_earned = BigNumber.new(0)
	dimensional_shards = BigNumber.new(0)

	base_click_power = BigNumber.new(1)
	click_multiplier = 1.0
	base_passive_income = BigNumber.new(0)
	passive_multiplier = 1.0

	total_clicks = 0

	if is_frenzy_active:
		_end_frenzy()

	if prestige_starting_energy > 0:
		void_energy = BigNumber.new(prestige_starting_energy)
		print("Applied prestige starting energy: %s" % void_energy.to_formatted_string())

	prestige_performed.emit("")

	print("Galaxy Reset complete! Prestige count: %d" % prestige_count)
	return true


# Save/Load

func get_save_data() -> Dictionary:
	return {
		"void_energy_mantissa": void_energy.mantissa,
		"void_energy_exponent": void_energy.exponent,
		"total_earned_mantissa": total_void_energy_earned.mantissa,
		"total_earned_exponent": total_void_energy_earned.exponent,
		"shards_mantissa": dimensional_shards.mantissa,
		"shards_exponent": dimensional_shards.exponent,
		"star_dust_mantissa": star_dust.mantissa,
		"star_dust_exponent": star_dust.exponent,
		"base_click_mantissa": base_click_power.mantissa,
		"base_click_exponent": base_click_power.exponent,
		"click_multiplier": click_multiplier,
		"total_clicks": total_clicks,
		"max_cps": max_clicks_per_second,
		"base_passive_mantissa": base_passive_income.mantissa,
		"base_passive_exponent": base_passive_income.exponent,
		"passive_multiplier": passive_multiplier,
		"global_multiplier": global_multiplier,
		"prestige_count": prestige_count,
		"prestige_starting_energy": prestige_starting_energy,
		"star_dust_multiplier": star_dust_multiplier,
		"base_crit_chance": base_crit_chance,
		"ability_cooldown_reduction": ability_cooldown_reduction,
		"ability_duration_bonus": ability_duration_bonus,
		"ability_power_bonus": ability_power_bonus,
		"generator_discount": generator_discount,
		"total_play_time": total_play_time,
		"last_played": int(Time.get_unix_time_from_system())
	}


func load_save_data(data: Dictionary) -> void:
	_void_energy = BigNumber.new(data.get("void_energy_mantissa", 0), int(data.get("void_energy_exponent", 0)))
	total_void_energy_earned = BigNumber.new(data.get("total_earned_mantissa", 0), int(data.get("total_earned_exponent", 0)))
	_dimensional_shards = BigNumber.new(data.get("shards_mantissa", 0), int(data.get("shards_exponent", 0)))
	_star_dust = BigNumber.new(data.get("star_dust_mantissa", 0), int(data.get("star_dust_exponent", 0)))

	base_click_power = BigNumber.new(data.get("base_click_mantissa", 1), int(data.get("base_click_exponent", 0)))
	click_multiplier = data.get("click_multiplier", 1.0)
	total_clicks = int(data.get("total_clicks", 0))
	max_clicks_per_second = int(data.get("max_cps", 14))

	base_passive_income = BigNumber.new(data.get("base_passive_mantissa", 0), int(data.get("base_passive_exponent", 0)))
	passive_multiplier = data.get("passive_multiplier", 1.0)

	global_multiplier = data.get("global_multiplier", 1.0)

	prestige_count = int(data.get("prestige_count", 0))

	prestige_starting_energy = data.get("prestige_starting_energy", 0.0)
	star_dust_multiplier = data.get("star_dust_multiplier", 1.0)
	base_crit_chance = data.get("base_crit_chance", 0.05)
	ability_cooldown_reduction = data.get("ability_cooldown_reduction", 0.0)
	ability_duration_bonus = data.get("ability_duration_bonus", 0.0)
	ability_power_bonus = data.get("ability_power_bonus", 0.0)
	generator_discount = data.get("generator_discount", 0.0)

	total_play_time = data.get("total_play_time", 0.0)
	last_played_timestamp = int(data.get("last_played", 0))

	void_energy_changed.emit(void_energy.to_formatted_string())
	dimensional_shards_changed.emit(dimensional_shards.to_formatted_string())
	star_dust_changed.emit(star_dust.to_formatted_string())
	click_power_changed.emit(effective_click_power.to_formatted_string())
	passive_income_changed.emit(effective_passive_income.to_formatted_string())


func calculate_offline_progress() -> void:
	if last_played_timestamp == 0:
		return

	var current_time := int(Time.get_unix_time_from_system())
	var seconds_away := current_time - last_played_timestamp

	seconds_away = mini(seconds_away, 86400)

	if seconds_away > 60 and not base_passive_income.is_zero:
		var offline_earnings := effective_passive_income.multiply(seconds_away * 0.5)
		add_void_energy(offline_earnings, true)
		print("Welcome back! Earned %s while away." % offline_earnings.to_formatted_string())


# Dev/Debug Methods

func reset_all_progress() -> void:
	_void_energy = BigNumber.new(0)
	total_void_energy_earned = BigNumber.new(0)
	_dimensional_shards = BigNumber.new(0)
	_star_dust = BigNumber.new(0)

	base_click_power = BigNumber.new(1)
	click_multiplier = 1.0
	total_clicks = 0
	max_clicks_per_second = 14
	_clicks_this_second = 0
	current_cps = 0.0

	base_passive_income = BigNumber.new(0)
	passive_multiplier = 1.0

	global_multiplier = 1.0
	frenzy_multiplier = 1.0
	is_frenzy_active = false

	_active_ability_multipliers.clear()
	_ability_timers.clear()
	_ability_passive_only.clear()
	ability_crit_multiplier = 1.0
	_crit_boost_timer = 0
	_frenzy_buildup_timer = 0
	_frenzy_duration_timer = 0

	prestige_count = 0

	total_play_time = 0
	_session_time = 0

	void_energy_changed.emit(_void_energy.to_formatted_string())
	dimensional_shards_changed.emit(_dimensional_shards.to_formatted_string())
	star_dust_changed.emit(_star_dust.to_formatted_string())
	click_power_changed.emit(effective_click_power.to_formatted_string())
	passive_income_changed.emit(effective_passive_income.to_formatted_string())
	frenzy_state_changed.emit(false, 1.0)

	print("GameManager: All progress reset!")
