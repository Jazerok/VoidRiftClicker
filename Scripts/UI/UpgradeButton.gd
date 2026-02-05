class_name UpgradeButton
extends Button

## UpgradeButton - A UI button representing a purchasable upgrade

signal upgrade_purchased(upgrade_id: String)
signal upgrade_hovered(upgrade_id: String)

enum BuyMode { SINGLE, TEN, HUNDRED, MAX }

var _upgrade: BaseUpgrade = null
var upgrade_id: String:
	get: return _upgrade.id if _upgrade else ""

# UI Elements (set by UpgradePanel)
var name_label: Label = null
var cost_label: Label = null
var count_label: Label = null
var effect_label: Label = null
var _icon_rect: TextureRect = null

var current_buy_mode: int = BuyMode.SINGLE

# Colors
const AFFORDABLE_COLOR := Color(1.0, 1.0, 1.0)
const UNAFFORDABLE_COLOR := Color(0.7, 0.7, 0.7)
const LOCKED_COLOR := Color(0.5, 0.5, 0.5)
const MAXED_COLOR := Color(1.0, 1.0, 1.0)


func _ready() -> void:
	name_label = get_node_or_null("VBox/NameLabel")
	cost_label = get_node_or_null("VBox/CostLabel")
	count_label = get_node_or_null("VBox/CountLabel")
	effect_label = get_node_or_null("VBox/EffectLabel")
	_icon_rect = get_node_or_null("Icon")

	pressed.connect(_on_pressed)
	mouse_entered.connect(_on_mouse_entered)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed:
			print("UpgradeButton._gui_input: Mouse button %d on %s" % [mouse_event.button_index, _upgrade.id if _upgrade else "unknown"])


func _process(_delta: float) -> void:
	if _upgrade != null:
		_update_affordability()


func setup(upgrade: BaseUpgrade) -> void:
	_upgrade = upgrade
	print("UpgradeButton.setup: %s - Visible=%s, Unlocked=%s, Owned=%d" % [upgrade.id, upgrade.is_visible, upgrade.is_unlocked, upgrade.owned_count])
	_ensure_labels_found()
	update_display()


func _ensure_labels_found() -> void:
	if name_label != null and cost_label != null and effect_label != null and count_label != null:
		return

	# Try 2-row layout
	if name_label == null:
		name_label = get_node_or_null("VBox/TopRow/NameLabel")
	if cost_label == null:
		cost_label = get_node_or_null("VBox/TopRow/CostLabel")
	if effect_label == null:
		effect_label = get_node_or_null("VBox/BottomRow/EffectLabel")
	if count_label == null:
		count_label = get_node_or_null("VBox/BottomRow/CountLabel")

	# Recursive search as last resort
	if name_label == null or cost_label == null:
		_find_labels_recursive(self)


func _find_labels_recursive(node: Node) -> void:
	for child in node.get_children():
		if child is Label:
			var label := child as Label
			match child.name:
				"NameLabel":
					if name_label == null:
						name_label = label
				"CostLabel":
					if cost_label == null:
						cost_label = label
				"CountLabel":
					if count_label == null:
						count_label = label
				"EffectLabel":
					if effect_label == null:
						effect_label = label
		_find_labels_recursive(child)


func update_display() -> void:
	if _upgrade == null:
		return

	# Show mystery placeholder if hidden
	if _upgrade.is_mystery and not _upgrade.is_unlocked:
		_display_as_mystery()
		return

	if name_label != null:
		name_label.text = _upgrade.display_name

	if count_label != null:
		if _upgrade.max_purchases == 1:
			count_label.text = "OWNED" if _upgrade.is_owned else ""
		elif _upgrade.max_purchases > 0:
			count_label.text = "x%d/%d" % [_upgrade.owned_count, _upgrade.max_purchases]
		else:
			count_label.text = "x%d" % _upgrade.owned_count

	_update_cost_display()

	if effect_label != null:
		effect_label.text = _upgrade.get_effect_description()

	if _icon_rect != null and _upgrade.icon != null:
		_icon_rect.texture = _upgrade.icon

	_update_affordability()


func _display_as_mystery() -> void:
	if name_label != null:
		name_label.text = "???"
	if cost_label != null:
		cost_label.text = "???"
	if count_label != null:
		count_label.text = ""
	if effect_label != null:
		effect_label.text = "Requirements not met"

	disabled = true
	modulate = LOCKED_COLOR


func _update_cost_display() -> void:
	if _upgrade == null or cost_label == null:
		return

	if not _upgrade.can_purchase_more:
		cost_label.text = "MAXED"
		return

	var is_prestige := _upgrade.category == BaseUpgrade.UpgradeCategory.PRESTIGE
	var currency: BigNumber = GameManager.star_dust if is_prestige else GameManager.void_energy
	var suffix := " SD" if is_prestige else ""

	var cost: BigNumber
	var prefix := ""

	match current_buy_mode:
		BuyMode.TEN:
			var count_ten := mini(10, _get_affordable_or_max_with_currency(10, currency))
			cost = _upgrade.get_bulk_cost(count_ten)
			prefix = "x%d: " % count_ten
		BuyMode.HUNDRED:
			var count_hundred := mini(100, _get_affordable_or_max_with_currency(100, currency))
			cost = _upgrade.get_bulk_cost(count_hundred)
			prefix = "x%d: " % count_hundred
		BuyMode.MAX:
			var max_count := _upgrade.get_affordable_count(currency)
			if max_count == 0:
				max_count = 1
			cost = _upgrade.get_bulk_cost(max_count)
			prefix = "x%d: " % max_count
		_:  # SINGLE
			cost = _upgrade.get_current_cost()

	cost_label.text = prefix + cost.to_formatted_string() + suffix


func _get_affordable_or_max_with_currency(requested: int, currency: BigNumber) -> int:
	if _upgrade == null:
		return 1

	var affordable := _upgrade.get_affordable_count(currency)
	if affordable == 0:
		return requested
	return mini(affordable, requested)


func _update_affordability() -> void:
	if _upgrade == null:
		return

	disabled = false

	if not _upgrade.is_unlocked:
		modulate = LOCKED_COLOR
		return

	if not _upgrade.can_purchase_more:
		modulate = MAXED_COLOR
		return

	var cost := _get_current_cost()
	var is_prestige := _upgrade.category == BaseUpgrade.UpgradeCategory.PRESTIGE
	var can_afford: bool
	if is_prestige:
		can_afford = GameManager.can_afford_star_dust(cost)
	else:
		can_afford = GameManager.can_afford(cost)

	modulate = AFFORDABLE_COLOR if can_afford else UNAFFORDABLE_COLOR


func _get_current_cost() -> BigNumber:
	if _upgrade == null:
		return BigNumber.zero()

	match current_buy_mode:
		BuyMode.TEN:
			return _upgrade.get_bulk_cost(10)
		BuyMode.HUNDRED:
			return _upgrade.get_bulk_cost(100)
		BuyMode.MAX:
			var affordable := _upgrade.get_affordable_count(GameManager.void_energy)
			return _upgrade.get_bulk_cost(maxi(1, affordable))
		_:
			return _upgrade.get_current_cost()


func _on_pressed() -> void:
	print("UpgradeButton._on_pressed: Clicked! Upgrade=%s" % [_upgrade.id if _upgrade else "null"])

	if _upgrade == null:
		print("UpgradeButton._on_pressed: _upgrade is null!")
		AudioManager.play_error_sfx()
		return

	if not _upgrade.is_unlocked:
		print("UpgradeButton._on_pressed: %s is not unlocked!" % _upgrade.id)
		AudioManager.play_error_sfx()
		return

	if not _upgrade.can_purchase_more:
		print("UpgradeButton._on_pressed: %s cannot purchase more (maxed)!" % _upgrade.id)
		AudioManager.play_error_sfx()
		return

	var success := false

	match current_buy_mode:
		BuyMode.TEN:
			success = UpgradeManager.purchase_upgrade_bulk(_upgrade.id, 10) > 0
		BuyMode.HUNDRED:
			success = UpgradeManager.purchase_upgrade_bulk(_upgrade.id, 100) > 0
		BuyMode.MAX:
			success = UpgradeManager.purchase_upgrade_max(_upgrade.id) > 0
		_:  # SINGLE
			success = UpgradeManager.purchase_upgrade(_upgrade.id)

	if success:
		AudioManager.play_purchase_sfx()
		upgrade_purchased.emit(_upgrade.id)
		update_display()
	else:
		AudioManager.play_error_sfx()


func _on_mouse_entered() -> void:
	if _upgrade != null:
		upgrade_hovered.emit(_upgrade.id)


func get_upgrade_tooltip_text() -> String:
	if _upgrade == null:
		return ""

	var tooltip := "[b]%s[/b]\n" % _upgrade.display_name
	tooltip += "%s\n\n" % _upgrade.description
	tooltip += "Effect: %s\n" % _upgrade.get_effect_description()
	tooltip += "Owned: %d" % _upgrade.owned_count

	if _upgrade.max_purchases > 0:
		tooltip += "/%d" % _upgrade.max_purchases

	return tooltip
