class_name UpgradePanel
extends Control

## UpgradePanel - Floating bubble-style upgrade panels on left and right sides

var _upgrade_buttons: Dictionary = {}
var _category_expanded: Dictionary = {}
var _category_containers: Dictionary = {}
var _category_headers: Dictionary = {}
var _current_buy_mode: int = UpgradeButton.BuyMode.SINGLE

var _left_panel: Control = null
var _right_panel: Control = null
var _left_content: VBoxContainer = null
var _right_content: VBoxContainer = null
var _buy_mode_container: HBoxContainer = null

var _right_tab_bar: HBoxContainer = null
var _right_tab_content: PanelContainer = null
var _right_tab_content_inner: VBoxContainer = null
var _right_tab_buttons: Dictionary = {}
var _active_right_tab: int = BaseUpgrade.UpgradeCategory.INTERACTIVE

# Colors
const BUBBLE_BG := Color(0.06, 0.04, 0.12, 0.92)
const BUBBLE_BORDER := Color(0.5, 0.3, 0.8, 0.7)
const HEADER_COLOR := Color(0.25, 0.15, 0.4, 0.95)
const HEADER_HOVER := Color(0.35, 0.2, 0.55, 0.98)

var _custom_font: Font = null


func _ready() -> void:
	visible = false
	modulate = Color(0, 0, 0, 0)

	_custom_font = load("res://Assets/Fonts/arial.ttf")

	_category_expanded[BaseUpgrade.UpgradeCategory.CLICK_POWER] = true
	_category_expanded[BaseUpgrade.UpgradeCategory.GENERATOR] = true
	_category_expanded[BaseUpgrade.UpgradeCategory.MULTIPLIER] = true
	_category_expanded[BaseUpgrade.UpgradeCategory.INTERACTIVE] = true

	call_deferred("_build_floating_panels")
	call_deferred("_deferred_initialize")

	pass


func _deferred_initialize() -> void:
	if UpgradeManager:
		UpgradeManager.upgrade_revealed.connect(_on_upgrade_revealed)
		UpgradeManager.upgrade_unlocked.connect(_on_upgrade_unlocked)
		UpgradeManager.upgrade_purchased.connect(_on_upgrade_purchased)
		UpgradeManager.upgrades_refreshed.connect(_rebuild_upgrade_list)
	_rebuild_upgrade_list()


func _exit_tree() -> void:
	if UpgradeManager:
		UpgradeManager.upgrade_revealed.disconnect(_on_upgrade_revealed)
		UpgradeManager.upgrade_unlocked.disconnect(_on_upgrade_unlocked)
		UpgradeManager.upgrade_purchased.disconnect(_on_upgrade_purchased)
		UpgradeManager.upgrades_refreshed.disconnect(_rebuild_upgrade_list)


func _build_floating_panels() -> void:
	var ui_layer := get_parent()
	if ui_layer == null:
		printerr("UpgradePanel: No parent found!")
		return

	# LEFT panel (Generators)
	_left_panel = _create_bubble_panel("LeftUpgradePanel")
	ui_layer.add_child(_left_panel)

	_left_panel.anchor_left = 0
	_left_panel.anchor_right = 0
	_left_panel.anchor_top = 0
	_left_panel.anchor_bottom = 1
	_left_panel.offset_left = 10
	_left_panel.offset_right = 310
	_left_panel.offset_top = 130
	_left_panel.offset_bottom = -100
	_left_panel.grow_horizontal = Control.GROW_DIRECTION_END
	_left_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_left_panel.move_to_front()

	var left_scroll := ScrollContainer.new()
	left_scroll.set_anchors_preset(Control.PRESET_FULL_RECT)
	left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	left_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	left_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	left_scroll.mouse_filter = Control.MOUSE_FILTER_PASS
	_left_panel.add_child(left_scroll)

	_left_content = VBoxContainer.new()
	_left_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_left_content.add_theme_constant_override("separation", 8)
	_left_content.mouse_filter = Control.MOUSE_FILTER_PASS
	left_scroll.add_child(_left_content)

	_add_buy_mode_buttons(_left_content)
	_create_category(_left_content, BaseUpgrade.UpgradeCategory.GENERATOR, "GENERATORS")

	# RIGHT panel with tabs
	_right_panel = _create_bubble_panel("RightUpgradePanel")
	ui_layer.add_child(_right_panel)

	_right_panel.anchor_left = 1
	_right_panel.anchor_right = 1
	_right_panel.anchor_top = 0
	_right_panel.anchor_bottom = 1
	_right_panel.offset_left = -310
	_right_panel.offset_right = -10
	_right_panel.offset_top = 130
	_right_panel.offset_bottom = -100
	_right_panel.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	_right_panel.grow_vertical = Control.GROW_DIRECTION_BOTH
	_right_panel.move_to_front()

	_right_content = VBoxContainer.new()
	_right_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_right_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_right_content.add_theme_constant_override("separation", 0)
	_right_content.mouse_filter = Control.MOUSE_FILTER_PASS
	_right_panel.add_child(_right_content)

	# Tab bar
	_right_tab_bar = HBoxContainer.new()
	_right_tab_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_right_tab_bar.add_theme_constant_override("separation", 4)
	_right_content.add_child(_right_tab_bar)

	var tabs := [
		[BaseUpgrade.UpgradeCategory.INTERACTIVE, "SPECIAL"],
		[BaseUpgrade.UpgradeCategory.CLICK_POWER, "CLICK POWER"],
		[BaseUpgrade.UpgradeCategory.MULTIPLIER, "MULTIPLIERS"]
	]

	for tab_data in tabs:
		var category: int = tab_data[0]
		var label: String = tab_data[1]
		var tab_btn := _create_tab_button(label, category)
		_right_tab_bar.add_child(tab_btn)
		_right_tab_buttons[category] = tab_btn

	# Content panel
	_right_tab_content = PanelContainer.new()
	_right_tab_content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_right_tab_content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_right_tab_content.mouse_filter = Control.MOUSE_FILTER_PASS

	var content_style := StyleBoxFlat.new()
	content_style.bg_color = Color(0.05, 0.03, 0.1, 0.98)
	content_style.border_width_left = 2
	content_style.border_width_right = 2
	content_style.border_width_top = 0
	content_style.border_width_bottom = 2
	content_style.border_color = Color(0.7, 0.5, 1.0, 1.0)
	content_style.corner_radius_bottom_left = 8
	content_style.corner_radius_bottom_right = 8
	content_style.content_margin_left = 8
	content_style.content_margin_right = 8
	content_style.content_margin_top = 8
	content_style.content_margin_bottom = 8
	_right_tab_content.add_theme_stylebox_override("panel", content_style)
	_right_content.add_child(_right_tab_content)

	_right_tab_content_inner = VBoxContainer.new()
	_right_tab_content_inner.set_anchors_preset(Control.PRESET_FULL_RECT)
	_right_tab_content_inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_right_tab_content_inner.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_right_tab_content_inner.add_theme_constant_override("separation", 6)
	_right_tab_content_inner.mouse_filter = Control.MOUSE_FILTER_PASS
	_right_tab_content.add_child(_right_tab_content_inner)

	_create_tab_category(_right_tab_content_inner, BaseUpgrade.UpgradeCategory.INTERACTIVE, "SPECIAL")
	_create_tab_category(_right_tab_content_inner, BaseUpgrade.UpgradeCategory.CLICK_POWER, "CLICK POWER")
	_create_tab_category(_right_tab_content_inner, BaseUpgrade.UpgradeCategory.MULTIPLIER, "MULTIPLIERS")

	_switch_right_tab(_active_right_tab)
	pass


func _create_bubble_panel(panel_name: String) -> Control:
	var panel := Control.new()
	panel.name = panel_name
	panel.mouse_filter = Control.MOUSE_FILTER_PASS
	panel.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	return panel


func _create_tab_button(label: String, category: int) -> Button:
	var btn := Button.new()
	btn.text = label
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(85, 38)
	btn.mouse_filter = Control.MOUSE_FILTER_STOP

	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.12, 0.08, 0.2, 0.95)
	normal_style.border_width_left = 2
	normal_style.border_width_right = 2
	normal_style.border_width_top = 2
	normal_style.border_color = Color(0.4, 0.25, 0.6, 0.7)
	normal_style.corner_radius_top_left = 8
	normal_style.corner_radius_top_right = 8
	normal_style.content_margin_left = 4
	normal_style.content_margin_right = 4
	normal_style.content_margin_top = 4
	normal_style.content_margin_bottom = 4
	btn.add_theme_stylebox_override("normal", normal_style)

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(0.2, 0.12, 0.35, 1.0)
	hover_style.border_width_left = 2
	hover_style.border_width_right = 2
	hover_style.border_width_top = 2
	hover_style.border_color = Color(0.6, 0.4, 0.85, 0.9)
	hover_style.corner_radius_top_left = 8
	hover_style.corner_radius_top_right = 8
	hover_style.content_margin_left = 4
	hover_style.content_margin_right = 4
	hover_style.content_margin_top = 4
	hover_style.content_margin_bottom = 4
	btn.add_theme_stylebox_override("hover", hover_style)

	btn.add_theme_font_size_override("font_size", 12)
	btn.add_theme_color_override("font_color", Color(0.75, 0.65, 0.9))
	btn.add_theme_color_override("font_hover_color", Color(1.0, 0.9, 1.0))

	var captured_category := category
	btn.pressed.connect(func(): _switch_right_tab(captured_category))

	return btn


func _create_tab_category(parent: VBoxContainer, category: int, _title: String) -> void:
	var container := VBoxContainer.new()
	container.name = "TabContent_%d" % category
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	container.add_theme_constant_override("separation", 6)
	container.mouse_filter = Control.MOUSE_FILTER_PASS
	container.visible = false
	parent.add_child(container)

	_category_containers[category] = container


func _switch_right_tab(category: int) -> void:
	_active_right_tab = category
	AudioManager.play_sfx("click", 0.4)

	for cat: int in _right_tab_buttons:
		var btn: Button = _right_tab_buttons[cat]
		var is_active: bool = (cat == category)

		if is_active:
			var active_style := StyleBoxFlat.new()
			active_style.bg_color = Color(0.05, 0.03, 0.1, 0.98)
			active_style.border_width_left = 2
			active_style.border_width_right = 2
			active_style.border_width_top = 2
			active_style.border_color = Color(0.7, 0.5, 1.0, 1.0)
			active_style.corner_radius_top_left = 8
			active_style.corner_radius_top_right = 8
			active_style.content_margin_left = 4
			active_style.content_margin_right = 4
			active_style.content_margin_top = 4
			active_style.content_margin_bottom = 4
			btn.add_theme_stylebox_override("normal", active_style)
			btn.add_theme_stylebox_override("hover", active_style)
			btn.add_theme_color_override("font_color", Color(1.0, 0.9, 1.0))
		else:
			var inactive_style := StyleBoxFlat.new()
			inactive_style.bg_color = Color(0.12, 0.08, 0.2, 0.95)
			inactive_style.border_width_left = 2
			inactive_style.border_width_right = 2
			inactive_style.border_width_top = 2
			inactive_style.border_color = Color(0.4, 0.25, 0.6, 0.7)
			inactive_style.corner_radius_top_left = 8
			inactive_style.corner_radius_top_right = 8
			inactive_style.content_margin_left = 4
			inactive_style.content_margin_right = 4
			inactive_style.content_margin_top = 4
			inactive_style.content_margin_bottom = 4
			btn.add_theme_stylebox_override("normal", inactive_style)
			btn.add_theme_color_override("font_color", Color(0.75, 0.65, 0.9))

	# Show/hide containers
	var right_categories := [BaseUpgrade.UpgradeCategory.INTERACTIVE, BaseUpgrade.UpgradeCategory.CLICK_POWER, BaseUpgrade.UpgradeCategory.MULTIPLIER]
	for cat in right_categories:
		if _category_containers.has(cat):
			_category_containers[cat].visible = (cat == category)


func _add_buy_mode_buttons(container: VBoxContainer) -> void:
	_buy_mode_container = HBoxContainer.new()
	_buy_mode_container.alignment = BoxContainer.ALIGNMENT_CENTER
	_buy_mode_container.add_theme_constant_override("separation", 5)
	container.add_child(_buy_mode_container)

	var modes := [
		["x1", UpgradeButton.BuyMode.SINGLE],
		["x10", UpgradeButton.BuyMode.TEN],
		["x100", UpgradeButton.BuyMode.HUNDRED],
		["MAX", UpgradeButton.BuyMode.MAX]
	]

	for mode_data in modes:
		var label: String = mode_data[0]
		var mode: int = mode_data[1]

		var btn := Button.new()
		btn.text = label
		btn.toggle_mode = true
		btn.button_pressed = (mode == UpgradeButton.BuyMode.SINGLE)
		btn.custom_minimum_size = Vector2(48, 22)

		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.12, 0.2, 0.9)
		style.corner_radius_top_left = 5
		style.corner_radius_top_right = 5
		style.corner_radius_bottom_left = 5
		style.corner_radius_bottom_right = 5
		style.border_width_left = 1
		style.border_width_right = 1
		style.border_width_top = 1
		style.border_width_bottom = 1
		style.border_color = Color(0.3, 0.5, 0.7, 0.5)
		btn.add_theme_stylebox_override("normal", style)

		var pressed_style := StyleBoxFlat.new()
		pressed_style.bg_color = Color(0.15, 0.35, 0.55, 0.95)
		pressed_style.corner_radius_top_left = 5
		pressed_style.corner_radius_top_right = 5
		pressed_style.corner_radius_bottom_left = 5
		pressed_style.corner_radius_bottom_right = 5
		pressed_style.border_width_left = 1
		pressed_style.border_width_right = 1
		pressed_style.border_width_top = 1
		pressed_style.border_width_bottom = 1
		pressed_style.border_color = Color(0.4, 0.7, 1.0, 0.8)
		btn.add_theme_stylebox_override("pressed", pressed_style)

		btn.add_theme_font_size_override("font_size", 11)

		var captured_mode := mode
		btn.pressed.connect(func(): set_buy_mode(captured_mode))

		_buy_mode_container.add_child(btn)

	container.add_child(HSeparator.new())


func _create_category(parent: VBoxContainer, category: int, title: String) -> void:
	var category_bubble := PanelContainer.new()
	category_bubble.mouse_filter = Control.MOUSE_FILTER_PASS

	var bubble_style := StyleBoxFlat.new()
	bubble_style.bg_color = Color(0.06, 0.1, 0.16, 0.9)
	bubble_style.corner_radius_top_left = 10
	bubble_style.corner_radius_top_right = 10
	bubble_style.corner_radius_bottom_left = 10
	bubble_style.corner_radius_bottom_right = 10
	bubble_style.content_margin_left = 8
	bubble_style.content_margin_right = 8
	bubble_style.content_margin_top = 6
	bubble_style.content_margin_bottom = 8
	category_bubble.add_theme_stylebox_override("panel", bubble_style)
	parent.add_child(category_bubble)

	var category_vbox := VBoxContainer.new()
	category_vbox.add_theme_constant_override("separation", 4)
	category_vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	category_bubble.add_child(category_vbox)

	# Header button
	var header := Button.new()
	var expanded: bool = _category_expanded.get(category, true)
	header.text = ("▼ " if expanded else "▶ ") + title
	header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	header.custom_minimum_size = Vector2(0, 28)
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", Color(0.85, 0.92, 1.0))

	var header_style := StyleBoxFlat.new()
	header_style.bg_color = HEADER_COLOR
	header_style.corner_radius_top_left = 6
	header_style.corner_radius_top_right = 6
	header_style.corner_radius_bottom_left = 0 if expanded else 6
	header_style.corner_radius_bottom_right = 0 if expanded else 6
	header_style.content_margin_left = 10
	header.add_theme_stylebox_override("normal", header_style)

	var hover_style := header_style.duplicate()
	hover_style.bg_color = HEADER_HOVER
	header.add_theme_stylebox_override("hover", hover_style)
	header.add_theme_stylebox_override("pressed", hover_style)

	var cat := category
	header.pressed.connect(func(): _toggle_category(cat))

	category_vbox.add_child(header)
	_category_headers[category] = header

	# Container for upgrades
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 4)
	container.visible = expanded
	container.mouse_filter = Control.MOUSE_FILTER_PASS
	category_vbox.add_child(container)
	_category_containers[category] = container


func _toggle_category(category: int) -> void:
	_category_expanded[category] = not _category_expanded.get(category, true)
	var expanded: bool = _category_expanded[category]

	if _category_headers.has(category):
		var header: Button = _category_headers[category]
		var base_name := header.text.substr(2)
		header.text = ("▼ " if expanded else "▶ ") + base_name

	if _category_containers.has(category):
		_category_containers[category].visible = expanded


func _rebuild_upgrade_list() -> void:
	for container in _category_containers.values():
		for child in container.get_children():
			child.queue_free()
	_upgrade_buttons.clear()

	var all_upgrades: Array = UpgradeManager.get_all_upgrades()
	pass

	for upgrade in all_upgrades:
		_add_upgrade_button(upgrade)

	call_deferred("_refresh_active_tab")


func _refresh_active_tab() -> void:
	_switch_right_tab(_active_right_tab)


func _add_upgrade_button(upgrade: BaseUpgrade) -> void:
	if _upgrade_buttons.has(upgrade.id):
		return

	var category := upgrade.category
	if category == BaseUpgrade.UpgradeCategory.MYSTERY:
		category = BaseUpgrade.UpgradeCategory.INTERACTIVE

	if category == BaseUpgrade.UpgradeCategory.PRESTIGE:
		return

	if not _category_containers.has(category):
		printerr("No container for category %d" % category)
		return

	var container: VBoxContainer = _category_containers[category]

	var button := _create_upgrade_bubble_button()
	container.add_child(button)
	button.setup(upgrade)
	button.current_buy_mode = _current_buy_mode
	button.upgrade_hovered.connect(_on_upgrade_hovered)
	button.upgrade_purchased.connect(_on_upgrade_button_purchased)

	_upgrade_buttons[upgrade.id] = button


func _create_upgrade_bubble_button() -> UpgradeButton:
	var button := UpgradeButton.new()
	button.custom_minimum_size = Vector2(0, 54)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.focus_mode = Control.FOCUS_ALL
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.18, 0.95)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	button.add_theme_stylebox_override("normal", style)

	var hover_style := style.duplicate()
	hover_style.bg_color = Color(0.15, 0.1, 0.25, 0.98)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)

	var disabled_style := style.duplicate()
	disabled_style.bg_color = Color(0.08, 0.06, 0.12, 0.7)
	button.add_theme_stylebox_override("disabled", disabled_style)

	# Layout
	var vbox := VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 4)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	button.add_child(vbox)

	# Top row: Name and Cost
	var top_row := HBoxContainer.new()
	top_row.name = "TopRow"
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(top_row)

	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	name_label.clip_text = false
	if _custom_font:
		name_label.add_theme_font_override("font", _custom_font)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.98, 1.0))
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(name_label)

	var cost_label := Label.new()
	cost_label.name = "CostLabel"
	cost_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cost_label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if _custom_font:
		cost_label.add_theme_font_override("font", _custom_font)
	cost_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.4))
	cost_label.add_theme_font_size_override("font_size", 15)
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_row.add_child(cost_label)

	# Bottom row: Effect and Count
	var bottom_row := HBoxContainer.new()
	bottom_row.name = "BottomRow"
	bottom_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(bottom_row)

	var effect_label := Label.new()
	effect_label.name = "EffectLabel"
	effect_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	effect_label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if _custom_font:
		effect_label.add_theme_font_override("font", _custom_font)
	effect_label.add_theme_color_override("font_color", Color(0.65, 0.9, 0.65))
	effect_label.add_theme_font_size_override("font_size", 14)
	effect_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_row.add_child(effect_label)

	var count_label := Label.new()
	count_label.name = "CountLabel"
	count_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	count_label.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
	if _custom_font:
		count_label.add_theme_font_override("font", _custom_font)
	count_label.add_theme_color_override("font_color", Color(0.75, 0.9, 1.0))
	count_label.add_theme_font_size_override("font_size", 14)
	count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bottom_row.add_child(count_label)

	# Set label references
	button.name_label = name_label
	button.effect_label = effect_label
	button.cost_label = cost_label
	button.count_label = count_label

	return button


func set_buy_mode(mode: int) -> void:
	_current_buy_mode = mode

	for button in _upgrade_buttons.values():
		button.current_buy_mode = mode
		button.update_display()

	if _buy_mode_container:
		var idx := 0
		for child in _buy_mode_container.get_children():
			if child is Button:
				child.button_pressed = (idx == mode)
				idx += 1


func _on_upgrade_revealed(upgrade_id: String) -> void:
	var upgrade := UpgradeManager.get_upgrade(upgrade_id)
	if upgrade:
		_add_upgrade_button(upgrade)


func _on_upgrade_unlocked(upgrade_id: String) -> void:
	if _upgrade_buttons.has(upgrade_id):
		_upgrade_buttons[upgrade_id].update_display()


func _on_upgrade_purchased(upgrade_id: String, _new_count: int) -> void:
	if _upgrade_buttons.has(upgrade_id):
		_upgrade_buttons[upgrade_id].update_display()


func _on_upgrade_button_purchased(_upgrade_id: String) -> void:
	for button in _upgrade_buttons.values():
		button.update_display()


func _on_upgrade_hovered(_upgrade_id: String) -> void:
	pass


func refresh_all() -> void:
	for button in _upgrade_buttons.values():
		button.update_display()


func toggle() -> void:
	if _left_panel:
		_left_panel.visible = not _left_panel.visible
	if _right_panel:
		_right_panel.visible = not _right_panel.visible
	if _left_panel and _left_panel.visible:
		refresh_all()
