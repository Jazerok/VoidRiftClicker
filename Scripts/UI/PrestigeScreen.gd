class_name PrestigeScreen
extends Control

## PrestigeScreen - Full-screen skill tree for prestige upgrades

enum PrestigeBranch { CLICK, PASSIVE, GLOBAL, ABILITY }

enum PrestigeBonusType {
	GLOBAL_MULTIPLIER,
	CLICK_MULTIPLIER,
	PASSIVE_MULTIPLIER,
	STARTING_ENERGY,
	STAR_DUST_BONUS,
	CRIT_CHANCE,
	ABILITY_COOLDOWN,
	ABILITY_DURATION,
	ABILITY_POWER,
	GENERATOR_DISCOUNT
}

class PrestigeNode:
	var id: String = ""
	var node_name: String = ""
	var description: String = ""
	var cost: int = 1
	var branch: int = PrestigeBranch.GLOBAL
	var node_position: Vector2 = Vector2.ZERO
	var prerequisites: Array = []
	var is_purchased: bool = false
	var bonus_type: int = PrestigeBonusType.GLOBAL_MULTIPLIER
	var bonus_value: float = 1.0

var _nodes: Array[PrestigeNode] = []
var _node_buttons: Dictionary = {}
var _tree_container: Control = null
var _lines_container: Control = null
var _star_dust_label: Label = null
var _galaxy_reset_button: Button = null
var _reset_info_label: Label = null
var _anim_time: float = 0.0

# Colors
const CLICK_COLOR := Color(1.0, 0.4, 0.2)
const PASSIVE_COLOR := Color(0.3, 0.9, 0.4)
const GLOBAL_COLOR := Color(1.0, 0.85, 0.3)
const ABILITY_COLOR := Color(0.6, 0.4, 1.0)
const LOCKED_COLOR := Color(0.3, 0.3, 0.35)
const LINE_COLOR := Color(0.3, 0.5, 0.7, 0.6)

var _center := Vector2(960, 500)

# Panning
var _is_panning: bool = false
var _pan_offset := Vector2.ZERO
var _last_mouse_pos := Vector2.ZERO
var _content_area: Control = null


func _ready() -> void:
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP

	_initialize_nodes()
	call_deferred("_build_ui")
	print("PrestigeScreen: Ready!")


func _process(delta: float) -> void:
	if not visible:
		return

	_anim_time += delta
	_update_star_dust_display()
	_update_reset_button()
	_animate_nodes(delta)


func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and key.keycode == KEY_ESCAPE:
			hide()
			get_viewport().set_input_as_handled()

	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT:
			if mouse_button.pressed:
				var mouse_pos := get_global_mouse_position()
				if _content_area:
					var content_rect := _content_area.get_global_rect()
					if content_rect.has_point(mouse_pos):
						_is_panning = true
						_last_mouse_pos = mouse_pos
			else:
				_is_panning = false

	if event is InputEventMouseMotion and _is_panning:
		var current_pos := get_global_mouse_position()
		var delta_pos := current_pos - _last_mouse_pos
		_last_mouse_pos = current_pos

		_pan_offset += delta_pos
		_pan_offset.x = clampf(_pan_offset.x, -400, 400)
		_pan_offset.y = clampf(_pan_offset.y, -300, 400)

		if _tree_container:
			_tree_container.position = _pan_offset
		if _lines_container:
			_lines_container.position = _pan_offset


func _initialize_nodes() -> void:
	# CENTER BRANCH - Global/Starting Bonuses
	_add_node("center_1", "Void Spark", "Begin each run with 1,000 energy", 1, PrestigeBranch.GLOBAL, Vector2(0, -80), [], PrestigeBonusType.STARTING_ENERGY, 1000)
	_add_node("center_2", "Void Ember", "Begin with 50,000 energy", 5, PrestigeBranch.GLOBAL, Vector2(0, -160), ["center_1"], PrestigeBonusType.STARTING_ENERGY, 50000)
	_add_node("center_3", "Void Flame", "x1.5 ALL income permanently", 15, PrestigeBranch.GLOBAL, Vector2(0, -240), ["center_2"], PrestigeBonusType.GLOBAL_MULTIPLIER, 1.5)
	_add_node("center_4", "Void Inferno", "Begin with 10 MILLION energy", 50, PrestigeBranch.GLOBAL, Vector2(0, -320), ["center_3"], PrestigeBonusType.STARTING_ENERGY, 10_000_000)
	_add_node("center_5", "Cosmic Unity", "x2 ALL income permanently!", 150, PrestigeBranch.GLOBAL, Vector2(0, -400), ["center_4"], PrestigeBonusType.GLOBAL_MULTIPLIER, 2.0)

	# LEFT BRANCH - Click Power
	_add_node("click_1", "Swift Fingers", "+25% click power", 2, PrestigeBranch.CLICK, Vector2(-200, -100), [], PrestigeBonusType.CLICK_MULTIPLIER, 1.25)
	_add_node("click_2", "Power Tap", "+50% click power", 8, PrestigeBranch.CLICK, Vector2(-280, -180), ["click_1"], PrestigeBonusType.CLICK_MULTIPLIER, 1.5)
	_add_node("click_3", "Void Strike", "x2 click power!", 25, PrestigeBranch.CLICK, Vector2(-350, -260), ["click_2"], PrestigeBonusType.CLICK_MULTIPLIER, 2.0)
	_add_node("click_4", "Cosmic Punch", "x3 click power!", 75, PrestigeBranch.CLICK, Vector2(-400, -350), ["click_3"], PrestigeBonusType.CLICK_MULTIPLIER, 3.0)
	_add_node("click_5", "Reality Shatter", "x5 click power!!", 200, PrestigeBranch.CLICK, Vector2(-420, -450), ["click_4"], PrestigeBonusType.CLICK_MULTIPLIER, 5.0)
	_add_node("click_crit_1", "Lucky Strike", "+5% base crit chance", 12, PrestigeBranch.CLICK, Vector2(-180, -220), ["click_1"], PrestigeBonusType.CRIT_CHANCE, 0.05)
	_add_node("click_crit_2", "Fortune's Edge", "+10% crit chance", 40, PrestigeBranch.CLICK, Vector2(-150, -320), ["click_crit_1"], PrestigeBonusType.CRIT_CHANCE, 0.10)

	# RIGHT BRANCH - Passive Income
	_add_node("passive_1", "Efficient Drones", "+25% passive income", 2, PrestigeBranch.PASSIVE, Vector2(200, -100), [], PrestigeBonusType.PASSIVE_MULTIPLIER, 1.25)
	_add_node("passive_2", "Optimized Systems", "+50% passive income", 8, PrestigeBranch.PASSIVE, Vector2(280, -180), ["passive_1"], PrestigeBonusType.PASSIVE_MULTIPLIER, 1.5)
	_add_node("passive_3", "Void Harvesters", "x2 passive income!", 25, PrestigeBranch.PASSIVE, Vector2(350, -260), ["passive_2"], PrestigeBonusType.PASSIVE_MULTIPLIER, 2.0)
	_add_node("passive_4", "Galactic Network", "x3 passive income!", 75, PrestigeBranch.PASSIVE, Vector2(400, -350), ["passive_3"], PrestigeBonusType.PASSIVE_MULTIPLIER, 3.0)
	_add_node("passive_5", "Universal Conduit", "x5 passive income!!", 200, PrestigeBranch.PASSIVE, Vector2(420, -450), ["passive_4"], PrestigeBonusType.PASSIVE_MULTIPLIER, 5.0)
	_add_node("passive_discount_1", "Bulk Deals", "Generators cost 10% less", 10, PrestigeBranch.PASSIVE, Vector2(180, -220), ["passive_1"], PrestigeBonusType.GENERATOR_DISCOUNT, 0.10)
	_add_node("passive_discount_2", "Wholesale", "Generators cost 20% less", 35, PrestigeBranch.PASSIVE, Vector2(150, -320), ["passive_discount_1"], PrestigeBonusType.GENERATOR_DISCOUNT, 0.20)

	# BOTTOM BRANCH - Abilities (Left)
	_add_node("ability_1", "Quick Recovery", "Abilities cooldown 10% faster", 5, PrestigeBranch.ABILITY, Vector2(-120, 60), [], PrestigeBonusType.ABILITY_COOLDOWN, 0.10)
	_add_node("ability_2", "Extended Power", "Ability durations +25%", 15, PrestigeBranch.ABILITY, Vector2(-200, 140), ["ability_1"], PrestigeBonusType.ABILITY_DURATION, 0.25)
	_add_node("ability_3", "Rapid Recharge", "Abilities cooldown 25% faster", 40, PrestigeBranch.ABILITY, Vector2(-280, 220), ["ability_2"], PrestigeBonusType.ABILITY_COOLDOWN, 0.25)
	_add_node("ability_4", "Void Mastery", "Ability effects +50% stronger", 100, PrestigeBranch.ABILITY, Vector2(-350, 300), ["ability_3"], PrestigeBonusType.ABILITY_POWER, 0.50)

	# BOTTOM BRANCH - Abilities (Right)
	_add_node("ability_r1", "Energy Efficiency", "Abilities cooldown 10% faster", 5, PrestigeBranch.ABILITY, Vector2(120, 60), [], PrestigeBonusType.ABILITY_COOLDOWN, 0.10)
	_add_node("ability_r2", "Sustained Power", "Ability durations +25%", 15, PrestigeBranch.ABILITY, Vector2(200, 140), ["ability_r1"], PrestigeBonusType.ABILITY_DURATION, 0.25)
	_add_node("ability_r3", "Time Dilation", "Abilities cooldown 25% faster", 40, PrestigeBranch.ABILITY, Vector2(280, 220), ["ability_r2"], PrestigeBonusType.ABILITY_COOLDOWN, 0.25)
	_add_node("ability_r4", "Cosmic Amplifier", "Ability effects +50% stronger", 100, PrestigeBranch.ABILITY, Vector2(350, 300), ["ability_r3"], PrestigeBonusType.ABILITY_POWER, 0.50)

	# Star Dust Bonus nodes
	_add_node("stardust_1", "Resonance I", "+15% Star Dust from resets", 20, PrestigeBranch.GLOBAL, Vector2(-100, -300), ["center_2"], PrestigeBonusType.STAR_DUST_BONUS, 0.15)
	_add_node("stardust_2", "Resonance II", "+25% Star Dust from resets", 60, PrestigeBranch.GLOBAL, Vector2(100, -300), ["center_3"], PrestigeBonusType.STAR_DUST_BONUS, 0.25)
	_add_node("stardust_3", "Resonance III", "+50% Star Dust from resets!", 150, PrestigeBranch.GLOBAL, Vector2(0, -480), ["center_5"], PrestigeBonusType.STAR_DUST_BONUS, 0.50)

	print("PrestigeScreen: Initialized %d nodes" % _nodes.size())


func _add_node(id: String, node_name: String, desc: String, cost: int, branch: int, pos: Vector2, prereqs: Array, bonus_type: int, bonus_value: float) -> void:
	var node := PrestigeNode.new()
	node.id = id
	node.node_name = node_name
	node.description = desc
	node.cost = cost
	node.branch = branch
	node.node_position = pos
	node.prerequisites = prereqs
	node.bonus_type = bonus_type
	node.bonus_value = bonus_value
	_nodes.append(node)


func _build_ui() -> void:
	# Background
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.03, 0.06, 0.98)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	# Star background
	var star_bg := StarBackground.new()
	star_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(star_bg)

	# Title
	var title := Label.new()
	title.text = "✦ GALAXY ASCENSION ✦"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_TOP_WIDE)
	title.offset_top = 20
	title.offset_bottom = 70
	title.add_theme_font_size_override("font_size", 36)
	title.add_theme_color_override("font_color", Color(0.85, 0.75, 1.0))
	add_child(title)

	# Star Dust display
	var sd_container := HBoxContainer.new()
	sd_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	sd_container.offset_top = 70
	sd_container.offset_bottom = 110
	sd_container.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(sd_container)

	var sd_icon := Label.new()
	sd_icon.text = "✦ Star Dust: "
	sd_icon.add_theme_font_size_override("font_size", 24)
	sd_icon.add_theme_color_override("font_color", Color(1.0, 0.9, 0.5))
	sd_container.add_child(sd_icon)

	_star_dust_label = Label.new()
	_star_dust_label.text = "0"
	_star_dust_label.add_theme_font_size_override("font_size", 28)
	_star_dust_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.6))
	sd_container.add_child(_star_dust_label)

	# Pan hint
	var pan_hint := Label.new()
	pan_hint.text = "Click and drag to pan around the skill tree"
	pan_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pan_hint.set_anchors_preset(Control.PRESET_TOP_WIDE)
	pan_hint.offset_top = 105
	pan_hint.offset_bottom = 125
	pan_hint.add_theme_font_size_override("font_size", 12)
	pan_hint.add_theme_color_override("font_color", Color(0.5, 0.55, 0.65, 0.8))
	add_child(pan_hint)

	# Content area
	_content_area = Control.new()
	_content_area.set_anchors_preset(Control.PRESET_FULL_RECT)
	_content_area.offset_top = 130
	_content_area.offset_bottom = -140
	_content_area.clip_contents = true
	_content_area.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_content_area)

	# Lines container
	_lines_container = Control.new()
	_lines_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_lines_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_area.add_child(_lines_container)

	# Tree container
	_tree_container = Control.new()
	_tree_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	_tree_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_content_area.add_child(_tree_container)

	_center = Vector2(960, 400)

	for node in _nodes:
		_create_node_button(node)

	_draw_connection_lines()

	# Galaxy Reset section
	var reset_container := VBoxContainer.new()
	reset_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	reset_container.offset_top = -130
	reset_container.offset_bottom = -20
	reset_container.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(reset_container)

	_reset_info_label = Label.new()
	_reset_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_reset_info_label.add_theme_font_size_override("font_size", 16)
	_reset_info_label.add_theme_color_override("font_color", Color(0.7, 0.8, 0.9))
	reset_container.add_child(_reset_info_label)

	var reset_btn_container := CenterContainer.new()
	reset_container.add_child(reset_btn_container)

	_galaxy_reset_button = Button.new()
	_galaxy_reset_button.text = "✦ GALAXY RESET ✦"
	_galaxy_reset_button.custom_minimum_size = Vector2(250, 50)
	_galaxy_reset_button.pressed.connect(_on_galaxy_reset_pressed)

	var reset_style := StyleBoxFlat.new()
	reset_style.bg_color = Color(0.45, 0.18, 0.55, 0.9)
	reset_style.border_width_left = 2
	reset_style.border_width_right = 2
	reset_style.border_width_top = 2
	reset_style.border_width_bottom = 2
	reset_style.border_color = Color(0.75, 0.45, 0.95, 0.8)
	reset_style.corner_radius_top_left = 12
	reset_style.corner_radius_top_right = 12
	reset_style.corner_radius_bottom_left = 12
	reset_style.corner_radius_bottom_right = 12
	_galaxy_reset_button.add_theme_stylebox_override("normal", reset_style)

	var reset_hover := reset_style.duplicate() as StyleBoxFlat
	reset_hover.bg_color = Color(0.55, 0.25, 0.65, 0.95)
	reset_hover.border_color = Color(0.9, 0.6, 1.0, 1.0)
	_galaxy_reset_button.add_theme_stylebox_override("hover", reset_hover)

	_galaxy_reset_button.add_theme_font_size_override("font_size", 20)
	_galaxy_reset_button.add_theme_color_override("font_color", Color(1, 0.95, 0.8))
	reset_btn_container.add_child(_galaxy_reset_button)

	# Close button
	var close_btn := Button.new()
	close_btn.text = "✕ CLOSE"
	close_btn.custom_minimum_size = Vector2(100, 40)
	close_btn.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	close_btn.offset_left = -120
	close_btn.offset_right = -20
	close_btn.offset_top = 20
	close_btn.offset_bottom = 60
	close_btn.pressed.connect(hide)

	var close_style := StyleBoxFlat.new()
	close_style.bg_color = Color(0.4, 0.15, 0.15, 0.9)
	close_style.corner_radius_top_left = 8
	close_style.corner_radius_top_right = 8
	close_style.corner_radius_bottom_left = 8
	close_style.corner_radius_bottom_right = 8
	close_style.border_width_left = 2
	close_style.border_width_right = 2
	close_style.border_width_top = 2
	close_style.border_width_bottom = 2
	close_style.border_color = Color(0.6, 0.3, 0.3, 0.8)
	close_btn.add_theme_stylebox_override("normal", close_style)

	var close_hover := close_style.duplicate() as StyleBoxFlat
	close_hover.bg_color = Color(0.6, 0.2, 0.2, 0.95)
	close_btn.add_theme_stylebox_override("hover", close_hover)
	close_btn.add_theme_font_size_override("font_size", 14)
	add_child(close_btn)

	# Branch labels
	_add_branch_label("CLICK POWER", Vector2(_center.x - 350, _center.y - 480), CLICK_COLOR)
	_add_branch_label("PASSIVE INCOME", Vector2(_center.x + 350, _center.y - 480), PASSIVE_COLOR)
	_add_branch_label("GLOBAL BONUSES", Vector2(_center.x, _center.y - 530), GLOBAL_COLOR)
	_add_branch_label("ABILITIES", Vector2(_center.x, _center.y + 350), ABILITY_COLOR)


func _add_branch_label(text: String, pos: Vector2, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = pos - Vector2(100, 0)
	label.custom_minimum_size = Vector2(200, 30)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", color)
	_tree_container.add_child(label)


func _create_node_button(node: PrestigeNode) -> void:
	var btn := PrestigeNodeButton.new()
	btn.setup(node, _get_branch_color(node.branch))
	btn.position = _center + node.node_position - btn.custom_minimum_size / 2
	btn.node_pressed.connect(_on_node_pressed)
	_tree_container.add_child(btn)
	_node_buttons[node.id] = btn


func _get_branch_color(branch: int) -> Color:
	match branch:
		PrestigeBranch.CLICK: return CLICK_COLOR
		PrestigeBranch.PASSIVE: return PASSIVE_COLOR
		PrestigeBranch.GLOBAL: return GLOBAL_COLOR
		PrestigeBranch.ABILITY: return ABILITY_COLOR
		_: return LOCKED_COLOR


func _draw_connection_lines() -> void:
	for node in _nodes:
		if node.prerequisites.is_empty():
			continue

		for prereq_id in node.prerequisites:
			var prereq: PrestigeNode = null
			for n in _nodes:
				if n.id == prereq_id:
					prereq = n
					break

			if prereq == null:
				continue

			var line := Line2D.new()
			line.add_point(_center + prereq.node_position)
			line.add_point(_center + node.node_position)
			line.width = 3
			line.default_color = LINE_COLOR
			line.begin_cap_mode = Line2D.LINE_CAP_ROUND
			line.end_cap_mode = Line2D.LINE_CAP_ROUND
			_lines_container.add_child(line)


func _update_star_dust_display() -> void:
	if _star_dust_label == null:
		return
	_star_dust_label.text = GameManager.star_dust.to_formatted_string()


func _update_reset_button() -> void:
	if _galaxy_reset_button == null or _reset_info_label == null:
		return

	var potential: BigNumber = GameManager.potential_star_dust
	var can_reset := not potential.is_zero

	_galaxy_reset_button.disabled = not can_reset

	if can_reset:
		_reset_info_label.text = "Reset to gain +%s Star Dust!" % potential.to_formatted_string()
		_galaxy_reset_button.modulate = Color(1, 1, 1, 1)
	else:
		var needed: BigNumber = PrestigeSystem.MINIMUM_PRESTIGE_ENERGY.subtract(GameManager.total_void_energy_earned)
		_reset_info_label.text = "Need %s more energy to reset" % needed.to_formatted_string()
		_galaxy_reset_button.modulate = Color(0.5, 0.5, 0.5, 1)


func _animate_nodes(delta: float) -> void:
	for id in _node_buttons:
		_node_buttons[id].update_animation(_anim_time)


func _on_node_pressed(node_id: String) -> void:
	var node: PrestigeNode = null
	for n in _nodes:
		if n.id == node_id:
			node = n
			break

	if node == null:
		return

	if node.is_purchased:
		print("PrestigeScreen: Node %s already purchased" % node_id)
		return

	if not _are_prerequisites_met(node):
		print("PrestigeScreen: Prerequisites not met for %s" % node_id)
		AudioManager.play_error_sfx()
		return

	var cost := BigNumber.new(node.cost)
	if not GameManager.can_afford_star_dust(cost):
		print("PrestigeScreen: Cannot afford %s (need %d SD)" % [node_id, node.cost])
		AudioManager.play_error_sfx()
		return

	# Purchase!
	GameManager.spend_star_dust(cost)
	node.is_purchased = true
	_apply_node_bonus(node)

	if _node_buttons.has(node_id):
		_node_buttons[node_id].set_purchased(true)

	_update_all_node_states()

	AudioManager.play_purchase_sfx()
	SaveManager.mark_unsaved_changes()

	print("PrestigeScreen: Purchased %s!" % node.node_name)


func _are_prerequisites_met(node: PrestigeNode) -> bool:
	if node.prerequisites.is_empty():
		return true

	for prereq_id in node.prerequisites:
		var prereq: PrestigeNode = null
		for n in _nodes:
			if n.id == prereq_id:
				prereq = n
				break
		if prereq == null or not prereq.is_purchased:
			return false
	return true


func _apply_node_bonus(node: PrestigeNode) -> void:
	match node.bonus_type:
		PrestigeBonusType.GLOBAL_MULTIPLIER:
			GameManager.increase_global_multiplier(node.bonus_value)
		PrestigeBonusType.CLICK_MULTIPLIER:
			GameManager.increase_click_multiplier(node.bonus_value)
		PrestigeBonusType.PASSIVE_MULTIPLIER:
			GameManager.increase_passive_multiplier(node.bonus_value)
		PrestigeBonusType.STARTING_ENERGY:
			GameManager.add_prestige_starting_energy(node.bonus_value)
		PrestigeBonusType.STAR_DUST_BONUS:
			GameManager.add_star_dust_multiplier(node.bonus_value)
		PrestigeBonusType.CRIT_CHANCE:
			GameManager.add_base_crit_chance(node.bonus_value)
		PrestigeBonusType.ABILITY_COOLDOWN:
			GameManager.add_ability_cooldown_reduction(node.bonus_value)
		PrestigeBonusType.ABILITY_DURATION:
			GameManager.add_ability_duration_bonus(node.bonus_value)
		PrestigeBonusType.ABILITY_POWER:
			GameManager.add_ability_power_bonus(node.bonus_value)
		PrestigeBonusType.GENERATOR_DISCOUNT:
			GameManager.add_generator_discount(node.bonus_value)


func _update_all_node_states() -> void:
	for node in _nodes:
		if _node_buttons.has(node.id):
			var prereqs_met := _are_prerequisites_met(node)
			var can_afford := GameManager.can_afford_star_dust(BigNumber.new(node.cost))
			_node_buttons[node.id].update_state(node.is_purchased, prereqs_met, can_afford)


func _on_galaxy_reset_pressed() -> void:
	var star_dust_earned: BigNumber = PrestigeSystem.perform_prestige()
	if not star_dust_earned.is_zero:
		print("PrestigeScreen: Galaxy Reset! Earned %s Star Dust" % star_dust_earned.to_formatted_string())
		_update_all_node_states()


func open() -> void:
	visible = true
	_update_all_node_states()
	move_to_front()

	_pan_offset = Vector2.ZERO
	if _tree_container:
		_tree_container.position = Vector2.ZERO
	if _lines_container:
		_lines_container.position = Vector2.ZERO


func toggle() -> void:
	if visible:
		hide()
	else:
		open()


func get_purchased_node_ids() -> Array[String]:
	var result: Array[String] = []
	for node in _nodes:
		if node.is_purchased:
			result.append(node.id)
	return result


func restore_purchased_nodes(node_ids: Array) -> void:
	for id in node_ids:
		for node in _nodes:
			if node.id == id:
				node.is_purchased = true
				_apply_node_bonus(node)
				if _node_buttons.has(id):
					_node_buttons[id].set_purchased(true)
				break
	_update_all_node_states()


# ═══════════════════════════════════════════════════════════════════════════════
# SUPPORTING CLASSES
# ═══════════════════════════════════════════════════════════════════════════════

class PrestigeNodeButton extends Button:
	signal node_pressed(node_id: String)

	var _node: PrestigeNode = null
	var _branch_color: Color
	var _is_purchased: bool = false
	var _prereqs_met: bool = true
	var _can_afford: bool = false
	var _glow_effect: Control = null
	var _icon_container: Control = null
	var _cost_label: Label = null
	var _local_time: float = 0.0

	func setup(node: PrestigeNode, branch_color: Color) -> void:
		_node = node
		_branch_color = branch_color
		custom_minimum_size = Vector2(90, 90)
		clip_contents = false

		# Glow effect
		_glow_effect = Control.new()
		_glow_effect.set_anchors_preset(Control.PRESET_FULL_RECT)
		_glow_effect.position = Vector2(-15, -15)
		_glow_effect.custom_minimum_size = Vector2(120, 120)
		_glow_effect.size = Vector2(120, 120)
		_glow_effect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_glow_effect.draw.connect(_draw_glow)
		add_child(_glow_effect)
		move_child(_glow_effect, 0)

		# Button style
		var style := StyleBoxFlat.new()
		style.bg_color = Color(branch_color.r * 0.2, branch_color.g * 0.2, branch_color.b * 0.2, 0.95)
		style.border_width_left = 3
		style.border_width_right = 3
		style.border_width_top = 3
		style.border_width_bottom = 3
		style.border_color = branch_color * 0.9
		style.corner_radius_top_left = 45
		style.corner_radius_top_right = 45
		style.corner_radius_bottom_left = 45
		style.corner_radius_bottom_right = 45
		add_theme_stylebox_override("normal", style)

		var hover_style := style.duplicate() as StyleBoxFlat
		hover_style.bg_color = Color(branch_color.r * 0.4, branch_color.g * 0.4, branch_color.b * 0.4, 0.98)
		hover_style.border_color = branch_color * 1.2
		add_theme_stylebox_override("hover", hover_style)

		var pressed_style := style.duplicate() as StyleBoxFlat
		pressed_style.bg_color = branch_color * 0.6
		add_theme_stylebox_override("pressed", pressed_style)

		tooltip_text = "%s\n%s\nCost: %d Star Dust" % [node.node_name, node.description, node.cost]

		# Icon container
		_icon_container = Control.new()
		_icon_container.set_anchors_preset(Control.PRESET_FULL_RECT)
		_icon_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_icon_container.draw.connect(_draw_star_icon)
		add_child(_icon_container)

		# Cost label
		_cost_label = Label.new()
		_cost_label.text = "%d" % node.cost
		_cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_cost_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		_cost_label.set_anchors_preset(Control.PRESET_FULL_RECT)
		_cost_label.offset_bottom = -8
		_cost_label.add_theme_font_size_override("font_size", 14)
		_cost_label.add_theme_color_override("font_color", Color(1, 0.95, 0.7, 1))
		_cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_cost_label)

		pressed.connect(_on_pressed)

	func _draw_glow() -> void:
		if _glow_effect == null:
			return

		var center := Vector2(60, 60)
		var base_alpha := 0.6 if _is_purchased else (0.4 if _prereqs_met and _can_afford else 0.15)
		var pulse_alpha := base_alpha + sin(_local_time * 3) * 0.1

		for i in range(5, -1, -1):
			var radius := 35 + i * 8
			var alpha := pulse_alpha * (1.0 - i / 6.0) * 0.3
			var glow_color := Color(_branch_color.r, _branch_color.g, _branch_color.b, alpha)
			_glow_effect.draw_circle(center, radius, glow_color)

	func _draw_star_icon() -> void:
		if _icon_container == null:
			return

		var center := Vector2(45, 38)
		var star_size := 18.0 if _is_purchased else 14.0
		var rotation := _local_time * 0.5

		var star_color: Color
		if _is_purchased:
			star_color = Color(1, 0.95, 0.6, 1)
		elif _prereqs_met and _can_afford:
			star_color = Color(_branch_color.r * 1.3, _branch_color.g * 1.3, _branch_color.b * 1.3, 0.9)
		elif _prereqs_met:
			star_color = Color(0.6, 0.6, 0.7, 0.7)
		else:
			star_color = Color(0.4, 0.4, 0.45, 0.5)

		if _is_purchased or (_prereqs_met and _can_afford):
			var glow_color := Color(star_color.r, star_color.g, star_color.b, 0.3)
			_icon_container.draw_circle(center, star_size + 6, glow_color)

		_draw_star(_icon_container, center, star_size, 5, rotation, star_color)

	func _draw_star(canvas: Control, center: Vector2, size_val: float, points: int, rotation: float, color: Color) -> void:
		var outer_points: Array[Vector2] = []
		var inner_points: Array[Vector2] = []
		var inner_size := size_val * 0.45

		for i in points:
			var outer_angle := rotation + (i * TAU / points) - PI / 2
			var inner_angle := outer_angle + TAU / (points * 2)

			outer_points.append(center + Vector2(cos(outer_angle), sin(outer_angle)) * size_val)
			inner_points.append(center + Vector2(cos(inner_angle), sin(inner_angle)) * inner_size)

		var polygon: PackedVector2Array = []
		for i in points:
			polygon.append(outer_points[i])
			polygon.append(inner_points[i])

		canvas.draw_polygon(polygon, PackedColorArray([color]))

	func _on_pressed() -> void:
		if _node != null:
			node_pressed.emit(_node.id)

	func set_purchased(purchased: bool) -> void:
		_is_purchased = purchased
		_update_visual()

	func update_state(purchased: bool, prereqs_met: bool, can_afford: bool) -> void:
		_is_purchased = purchased
		_prereqs_met = prereqs_met
		_can_afford = can_afford
		_update_visual()

	func _update_visual() -> void:
		if _cost_label != null:
			if _is_purchased:
				_cost_label.text = "✓"
				_cost_label.add_theme_color_override("font_color", Color(0.5, 1, 0.6, 1))
			else:
				_cost_label.text = "%d" % (_node.cost if _node else 0)
				_cost_label.add_theme_color_override("font_color", Color(1, 0.95, 0.7, 1) if _can_afford else Color(0.7, 0.6, 0.6, 0.8))

		if _is_purchased:
			modulate = Color(1.1, 1.1, 1.1, 1.0)
		elif not _prereqs_met:
			modulate = Color(0.5, 0.5, 0.5, 0.7)
		elif not _can_afford:
			modulate = Color(0.75, 0.75, 0.75, 0.9)
		else:
			modulate = Color(1.0, 1.0, 1.0, 1.0)

		if _glow_effect:
			_glow_effect.queue_redraw()
		if _icon_container:
			_icon_container.queue_redraw()

	func update_animation(time: float) -> void:
		_local_time = time

		if _is_purchased:
			var pulse := 1.0 + sin(time * 2) * 0.04
			scale = Vector2(pulse, pulse)
		elif _prereqs_met and _can_afford:
			var pulse := 1.0 + sin(time * 3) * 0.06
			scale = Vector2(pulse, pulse)
		else:
			scale = Vector2.ONE

		if _glow_effect:
			_glow_effect.queue_redraw()
		if _icon_container:
			_icon_container.queue_redraw()


class StarBackground extends Control:
	class Star:
		var pos: Vector2
		var star_size: float
		var brightness: float
		var twinkle_speed: float
		var twinkle_offset: float

	var _stars: Array[Star] = []
	var _time: float = 0.0

	func _ready() -> void:
		for i in 200:
			var star := Star.new()
			star.pos = Vector2(randf_range(0, 1920), randf_range(0, 1080))
			star.star_size = randf_range(0.5, 2.0)
			star.brightness = randf_range(0.2, 0.8)
			star.twinkle_speed = randf_range(1, 4)
			star.twinkle_offset = randf_range(0, TAU)
			_stars.append(star)

	func _process(delta: float) -> void:
		_time += delta
		queue_redraw()

	func _draw() -> void:
		for star in _stars:
			var twinkle := 0.5 + 0.5 * sin(_time * star.twinkle_speed + star.twinkle_offset)
			var alpha := star.brightness * twinkle
			draw_circle(star.pos, star.star_size, Color(0.8, 0.85, 1.0, alpha))
