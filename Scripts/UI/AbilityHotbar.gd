class_name AbilityHotbar
extends Control

## AbilityHotbar - Bottom screen hotbar for activatable abilities

class Ability:
	var id: String = ""
	var ability_name: String = ""
	var description: String = ""
	var hotkey: String = ""
	var cooldown: float = 60.0
	var duration: float = 0.0
	var cooldown_remaining: float = 0.0
	var active_time_remaining: float = 0.0
	var is_active: bool:
		get: return active_time_remaining > 0
	var is_on_cooldown: bool:
		get: return cooldown_remaining > 0
	var is_unlocked: bool = false
	var icon_color: Color = Color.WHITE
	var on_activate: Callable

var _abilities: Array[Ability] = []
var _ability_buttons: Dictionary = {}
var _cooldown_overlays: Dictionary = {}
var _cooldown_labels: Dictionary = {}
var _active_indicators: Dictionary = {}
var _button_container: HBoxContainer = null

# Colors
const ABILITY_READY := Color(0.2, 0.7, 0.9, 1.0)
const ABILITY_COOLDOWN := Color(0.3, 0.3, 0.3, 0.9)
const ABILITY_ACTIVE := Color(0.3, 0.9, 0.4, 1.0)
const ABILITY_LOCKED := Color(0.2, 0.2, 0.2, 0.7)


func _ready() -> void:
	_initialize_abilities()
	_build_ui()
	print("AbilityHotbar: Ready!")


func _process(delta: float) -> void:
	for ability in _abilities:
		if ability.active_time_remaining > 0:
			ability.active_time_remaining -= delta
			if ability.active_time_remaining <= 0:
				ability.active_time_remaining = 0
				_on_ability_ended(ability)

		if ability.cooldown_remaining > 0:
			ability.cooldown_remaining -= delta
			if ability.cooldown_remaining < 0:
				ability.cooldown_remaining = 0

	_update_ability_display()


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo:
			var index := -1
			match key_event.keycode:
				KEY_1: index = 0
				KEY_2: index = 1
				KEY_3: index = 2
				KEY_4: index = 3
				KEY_5: index = 4
				KEY_6: index = 5
				KEY_7: index = 6
				KEY_8: index = 7
				KEY_9: index = 8

			if index >= 0 and index < _abilities.size():
				_try_activate_ability(_abilities[index])


func _initialize_abilities() -> void:
	# Ability 1: Critical Click
	var critical := Ability.new()
	critical.id = "critical_click"
	critical.ability_name = "Critical"
	critical.description = "100% critical chance for 8 seconds"
	critical.hotkey = "1"
	critical.cooldown = 45.0
	critical.duration = 8.0
	critical.is_unlocked = false
	critical.icon_color = Color(1.0, 0.3, 0.3)
	critical.on_activate = func(): GameManager.activate_crit_boost(20.0, 8.0)
	_abilities.append(critical)

	# Ability 2: Double Tap
	var double_tap := Ability.new()
	double_tap.id = "double_tap"
	double_tap.ability_name = "Double Tap"
	double_tap.description = "Clicks count as 2 for 10 seconds"
	double_tap.hotkey = "2"
	double_tap.cooldown = 30.0
	double_tap.duration = 10.0
	double_tap.is_unlocked = false
	double_tap.icon_color = Color(0.3, 0.7, 1.0)
	double_tap.on_activate = func(): GameManager.activate_multiplier("double_tap", 2.0, 10.0)
	_abilities.append(double_tap)

	# Ability 3: Patient Collector
	var patience := Ability.new()
	patience.id = "patient_collector"
	patience.ability_name = "Patience"
	patience.description = "x5 passive income for 12 seconds"
	patience.hotkey = "3"
	patience.cooldown = 60.0
	patience.duration = 12.0
	patience.is_unlocked = false
	patience.icon_color = Color(0.6, 0.8, 0.4)
	patience.on_activate = func(): GameManager.activate_multiplier("patient_collector", 5.0, 12.0, true)
	_abilities.append(patience)

	# Ability 4: Lucky Star
	var lucky := Ability.new()
	lucky.id = "lucky_star"
	lucky.ability_name = "Lucky Star"
	lucky.description = "Random x2-x10 all income for 15 seconds"
	lucky.hotkey = "4"
	lucky.cooldown = 90.0
	lucky.duration = 15.0
	lucky.is_unlocked = false
	lucky.icon_color = Color(1.0, 0.9, 0.2)
	lucky.on_activate = func():
		var mult := randf_range(2.0, 10.0)
		GameManager.activate_multiplier("lucky_star", mult, 15.0)
		print("Lucky Star: x%.1f multiplier!" % mult)
	_abilities.append(lucky)

	# Ability 5: Overdrive
	var overdrive := Ability.new()
	overdrive.id = "overdrive"
	overdrive.ability_name = "Overdrive"
	overdrive.description = "x5 all income for 5 seconds"
	overdrive.hotkey = "5"
	overdrive.cooldown = 45.0
	overdrive.duration = 5.0
	overdrive.is_unlocked = false
	overdrive.icon_color = Color(1.0, 0.6, 0.2)
	overdrive.on_activate = func(): GameManager.activate_multiplier("overdrive", 5.0, 5.0)
	_abilities.append(overdrive)

	# Ability 6: Energy Surge
	var surge := Ability.new()
	surge.id = "energy_surge"
	surge.ability_name = "Surge"
	surge.description = "Gain 10 seconds of passive income instantly"
	surge.hotkey = "6"
	surge.cooldown = 60.0
	surge.duration = 0.0
	surge.is_unlocked = false
	surge.icon_color = Color(0.9, 0.9, 0.3)
	surge.on_activate = func():
		var bonus := GameManager.effective_passive_income.multiply(10)
		GameManager.add_void_energy(bonus)
		print("Energy Surge: +%s" % bonus.to_formatted_string())
	_abilities.append(surge)

	# Ability 7: Time Warp
	var time_warp := Ability.new()
	time_warp.id = "time_warp"
	time_warp.ability_name = "Time Warp"
	time_warp.description = "x3 passive income for 15 seconds"
	time_warp.hotkey = "7"
	time_warp.cooldown = 90.0
	time_warp.duration = 15.0
	time_warp.is_unlocked = false
	time_warp.icon_color = Color(0.5, 0.3, 0.9)
	time_warp.on_activate = func(): GameManager.activate_multiplier("time_warp", 3.0, 15.0, true)
	_abilities.append(time_warp)

	# Ability 8: Void Blast
	var void_blast := Ability.new()
	void_blast.id = "void_blast"
	void_blast.ability_name = "Void Blast"
	void_blast.description = "x20 mega-click"
	void_blast.hotkey = "8"
	void_blast.cooldown = 30.0
	void_blast.duration = 0.0
	void_blast.is_unlocked = false
	void_blast.icon_color = Color(0.8, 0.2, 0.8)
	void_blast.on_activate = func():
		var mega_click := GameManager.effective_click_power.multiply(20)
		GameManager.add_void_energy(mega_click)
		print("Void Blast: +%s" % mega_click.to_formatted_string())
	_abilities.append(void_blast)

	# Ability 9: Fortune's Favor
	var fortune := Ability.new()
	fortune.id = "fortunes_favor"
	fortune.ability_name = "Fortune"
	fortune.description = "x3 critical chance for 20 seconds"
	fortune.hotkey = "9"
	fortune.cooldown = 120.0
	fortune.duration = 20.0
	fortune.is_unlocked = false
	fortune.icon_color = Color(0.3, 0.9, 0.6)
	fortune.on_activate = func(): GameManager.activate_crit_boost(3.0, 20.0)
	_abilities.append(fortune)


func _build_ui() -> void:
	var center_container := CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	center_container.offset_top = -90
	center_container.offset_bottom = -10
	center_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	add_child(center_container)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.03, 0.05, 0.1, 0.85)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.2, 0.4, 0.6, 0.5)
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 12
	panel_style.corner_radius_bottom_right = 12
	panel_style.content_margin_left = 15
	panel_style.content_margin_right = 15
	panel_style.content_margin_top = 8
	panel_style.content_margin_bottom = 8

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", panel_style)
	center_container.add_child(panel)

	_button_container = HBoxContainer.new()
	_button_container.add_theme_constant_override("separation", 6)
	panel.add_child(_button_container)

	for ability in _abilities:
		_create_ability_button(ability)


func _create_ability_button(ability: Ability) -> void:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 2)
	_button_container.add_child(container)

	var button := Button.new()
	button.custom_minimum_size = Vector2(50, 50)
	button.tooltip_text = "%s\n%s\nCooldown: %ss\nHotkey: %s" % [ability.ability_name, ability.description, ability.cooldown, ability.hotkey]

	var style := StyleBoxFlat.new()
	style.bg_color = ability.icon_color * 0.3
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = ability.icon_color
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	button.add_theme_stylebox_override("normal", style)

	var hover_style := style.duplicate() as StyleBoxFlat
	hover_style.bg_color = ability.icon_color * 0.5
	hover_style.border_color = ability.icon_color * 1.2
	button.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = ability.icon_color * 0.7
	button.add_theme_stylebox_override("pressed", pressed_style)

	# Hotkey label
	var hotkey_label := Label.new()
	hotkey_label.text = ability.hotkey
	hotkey_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hotkey_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hotkey_label.add_theme_font_size_override("font_size", 18)
	hotkey_label.add_theme_color_override("font_color", Color.WHITE)
	button.add_child(hotkey_label)

	# Cooldown overlay
	var cooldown_overlay := ColorRect.new()
	cooldown_overlay.color = Color(0.1, 0.1, 0.1, 0.7)
	cooldown_overlay.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	cooldown_overlay.offset_top = 0
	cooldown_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(cooldown_overlay)

	# Cooldown timer label
	var cooldown_label := Label.new()
	cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cooldown_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	cooldown_label.add_theme_font_size_override("font_size", 12)
	cooldown_label.add_theme_color_override("font_color", Color.WHITE)
	cooldown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(cooldown_label)

	# Active indicator
	var active_indicator := Panel.new()
	active_indicator.set_anchors_preset(Control.PRESET_FULL_RECT)
	active_indicator.offset_left = -4
	active_indicator.offset_top = -4
	active_indicator.offset_right = 4
	active_indicator.offset_bottom = 4

	var active_style := StyleBoxFlat.new()
	active_style.bg_color = Color.TRANSPARENT
	active_style.border_width_left = 3
	active_style.border_width_right = 3
	active_style.border_width_top = 3
	active_style.border_width_bottom = 3
	active_style.border_color = ABILITY_ACTIVE
	active_style.corner_radius_top_left = 10
	active_style.corner_radius_top_right = 10
	active_style.corner_radius_bottom_left = 10
	active_style.corner_radius_bottom_right = 10
	active_indicator.add_theme_stylebox_override("panel", active_style)
	active_indicator.visible = false
	active_indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(active_indicator)

	var ability_ref := ability
	button.pressed.connect(func(): _try_activate_ability(ability_ref))

	container.add_child(button)

	# Name label
	var name_label := Label.new()
	name_label.text = ability.ability_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 10)
	name_label.add_theme_color_override("font_color", ability.icon_color)
	container.add_child(name_label)

	_ability_buttons[ability.id] = button
	_cooldown_overlays[ability.id] = cooldown_overlay
	_cooldown_labels[ability.id] = cooldown_label
	_active_indicators[ability.id] = active_indicator


func _try_activate_ability(ability: Ability) -> void:
	if not ability.is_unlocked:
		print("Ability %s is locked!" % ability.ability_name)
		AudioManager.play_error_sfx()
		return

	if ability.is_on_cooldown:
		print("Ability %s is on cooldown: %.1fs" % [ability.ability_name, ability.cooldown_remaining])
		AudioManager.play_error_sfx()
		return

	if ability.is_active:
		print("Ability %s is already active!" % ability.ability_name)
		return

	print("Activating ability: %s" % ability.ability_name)
	ability.on_activate.call()

	if ability.duration > 0:
		ability.active_time_remaining = ability.duration
	ability.cooldown_remaining = ability.cooldown

	AudioManager.play_purchase_sfx()


func _on_ability_ended(ability: Ability) -> void:
	print("Ability ended: %s" % ability.ability_name)
	GameManager.deactivate_multiplier(ability.id)


func _update_ability_display() -> void:
	for ability in _abilities:
		if not _ability_buttons.has(ability.id):
			continue

		var button: Button = _ability_buttons[ability.id]
		var overlay: ColorRect = _cooldown_overlays[ability.id]
		var label: Label = _cooldown_labels[ability.id]
		var indicator: Panel = _active_indicators[ability.id]

		if ability.is_on_cooldown:
			var ratio := ability.cooldown_remaining / ability.cooldown
			overlay.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
			overlay.offset_top = -50 * ratio
			overlay.visible = true
			label.text = "%.0f" % ability.cooldown_remaining
			label.visible = true
			button.disabled = true
		else:
			overlay.visible = false
			label.visible = false
			button.disabled = false

		indicator.visible = ability.is_active

		if not ability.is_unlocked:
			button.modulate = ABILITY_LOCKED
		elif ability.is_active:
			button.modulate = ABILITY_ACTIVE
		elif ability.is_on_cooldown:
			button.modulate = ABILITY_COOLDOWN
		else:
			button.modulate = Color.WHITE


func unlock_ability(ability_id: String) -> void:
	for ability in _abilities:
		if ability.id == ability_id:
			ability.is_unlocked = true
			print("Ability unlocked: %s" % ability.ability_name)
			return


func is_ability_active(ability_id: String) -> bool:
	for ability in _abilities:
		if ability.id == ability_id:
			return ability.is_active
	return false


func is_ability_unlocked(ability_id: String) -> bool:
	for ability in _abilities:
		if ability.id == ability_id:
			return ability.is_unlocked
	return false


func get_unlocked_ability_ids() -> Array[String]:
	var result: Array[String] = []
	for ability in _abilities:
		if ability.is_unlocked:
			result.append(ability.id)
	return result


func set_unlocked_abilities(unlocked_ids: Array) -> void:
	for ability in _abilities:
		ability.is_unlocked = unlocked_ids.has(ability.id)
	print("AbilityHotbar: Restored %d unlocked abilities" % unlocked_ids.size())


func sync_with_upgrades() -> void:
	var ability_to_upgrade := {
		"critical_click": "ability_critical_click",
		"double_tap": "ability_double_tap",
		"patient_collector": "ability_patient_collector",
		"lucky_star": "ability_lucky_star",
		"overdrive": "ability_overdrive",
		"energy_surge": "ability_energy_surge",
		"time_warp": "ability_time_warp",
		"void_blast": "ability_void_blast",
		"fortunes_favor": "ability_fortunes_favor"
	}

	for ability in _abilities:
		if ability_to_upgrade.has(ability.id):
			var upgrade_id: String = ability_to_upgrade[ability.id]
			var upgrade := UpgradeManager.get_upgrade(upgrade_id)
			if upgrade and upgrade.is_owned:
				ability.is_unlocked = true
				print("AbilityHotbar: Synced ability '%s' as unlocked" % ability.id)
