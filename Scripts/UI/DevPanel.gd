class_name DevPanel
extends Control

## DevPanel - Developer tools for testing the game

var _panel: PanelContainer = null
var _is_expanded: bool = false


func _ready() -> void:
	call_deferred("_build_dev_panel")
	call_deferred("move_to_front")
	print("DevPanel: Ready!")


func _build_dev_panel() -> void:
	# Create toggle button near top-center
	var toggle_btn := Button.new()
	toggle_btn.text = "DEV"
	toggle_btn.custom_minimum_size = Vector2(50, 30)
	add_child(toggle_btn)

	# Position near center-top
	toggle_btn.anchor_left = 0.5
	toggle_btn.anchor_right = 0.5
	toggle_btn.anchor_top = 0.0
	toggle_btn.anchor_bottom = 0.0
	toggle_btn.offset_left = 200
	toggle_btn.offset_right = 260
	toggle_btn.offset_top = 10
	toggle_btn.offset_bottom = 40
	toggle_btn.pressed.connect(_toggle_panel)

	var toggle_style := StyleBoxFlat.new()
	toggle_style.bg_color = Color(0.6, 0.2, 0.2, 0.9)
	toggle_style.corner_radius_top_left = 5
	toggle_style.corner_radius_top_right = 5
	toggle_style.corner_radius_bottom_left = 5
	toggle_style.corner_radius_bottom_right = 5
	toggle_btn.add_theme_stylebox_override("normal", toggle_style)
	toggle_btn.add_theme_stylebox_override("hover", toggle_style)
	toggle_btn.add_theme_stylebox_override("pressed", toggle_style)

	# Create expandable panel
	_panel = PanelContainer.new()
	_panel.custom_minimum_size = Vector2(200, 0)
	add_child(_panel)

	_panel.anchor_left = 0.5
	_panel.anchor_right = 0.5
	_panel.anchor_top = 0.0
	_panel.anchor_bottom = 0.0
	_panel.offset_left = 100
	_panel.offset_right = 310
	_panel.offset_top = 50
	_panel.offset_bottom = 350
	_panel.visible = false
	_panel.z_index = 100

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.6, 0.2, 0.2, 0.8)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.content_margin_left = 10
	panel_style.content_margin_right = 10
	panel_style.content_margin_top = 10
	panel_style.content_margin_bottom = 10
	_panel.add_theme_stylebox_override("panel", panel_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_panel.add_child(vbox)

	# Title
	var title := Label.new()
	title.text = "Developer Tools"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_color", Color(1, 0.5, 0.5))
	title.add_theme_font_size_override("font_size", 14)
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	# Add Energy buttons
	var energy_label := Label.new()
	energy_label.text = "Add Void Energy:"
	energy_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(energy_label)

	var energy_hbox := HBoxContainer.new()
	energy_hbox.add_theme_constant_override("separation", 5)
	vbox.add_child(energy_hbox)

	_add_dev_button(energy_hbox, "+100", func(): _add_energy(100))
	_add_dev_button(energy_hbox, "+1K", func(): _add_energy(1000))
	_add_dev_button(energy_hbox, "+1M", func(): _add_energy(1000000))

	var energy_hbox2 := HBoxContainer.new()
	energy_hbox2.add_theme_constant_override("separation", 5)
	vbox.add_child(energy_hbox2)

	_add_dev_button(energy_hbox2, "+1B", func(): _add_energy(1e9))
	_add_dev_button(energy_hbox2, "+1T", func(): _add_energy(1e12))
	_add_dev_button(energy_hbox2, "+1Q", func(): _add_energy(1e15))

	vbox.add_child(HSeparator.new())

	# Meteor testing
	var meteor_label := Label.new()
	meteor_label.text = "Spawn Meteors:"
	meteor_label.add_theme_font_size_override("font_size", 11)
	vbox.add_child(meteor_label)

	var meteor_hbox := HBoxContainer.new()
	meteor_hbox.add_theme_constant_override("separation", 5)
	vbox.add_child(meteor_hbox)

	_add_dev_button(meteor_hbox, "Small", func(): _spawn_meteor(0))
	_add_dev_button(meteor_hbox, "Med", func(): _spawn_meteor(1))
	_add_dev_button(meteor_hbox, "Large", func(): _spawn_meteor(2))

	var meteor_hbox2 := HBoxContainer.new()
	meteor_hbox2.add_theme_constant_override("separation", 5)
	vbox.add_child(meteor_hbox2)

	_add_dev_button(meteor_hbox2, "Comet", func(): _spawn_meteor(3))
	_add_dev_button(meteor_hbox2, "Shower", _spawn_meteor_shower)

	vbox.add_child(HSeparator.new())

	# Reset button
	var reset_label := Label.new()
	reset_label.text = "Danger Zone:"
	reset_label.add_theme_font_size_override("font_size", 11)
	reset_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4))
	vbox.add_child(reset_label)

	var reset_btn := Button.new()
	reset_btn.text = "RESET ALL PROGRESS"
	reset_btn.custom_minimum_size = Vector2(0, 35)
	reset_btn.pressed.connect(_reset_progress)

	var reset_style := StyleBoxFlat.new()
	reset_style.bg_color = Color(0.5, 0.1, 0.1, 0.9)
	reset_style.corner_radius_top_left = 5
	reset_style.corner_radius_top_right = 5
	reset_style.corner_radius_bottom_left = 5
	reset_style.corner_radius_bottom_right = 5
	reset_btn.add_theme_stylebox_override("normal", reset_style)

	var reset_hover_style := StyleBoxFlat.new()
	reset_hover_style.bg_color = Color(0.7, 0.1, 0.1, 0.95)
	reset_hover_style.corner_radius_top_left = 5
	reset_hover_style.corner_radius_top_right = 5
	reset_hover_style.corner_radius_bottom_left = 5
	reset_hover_style.corner_radius_bottom_right = 5
	reset_btn.add_theme_stylebox_override("hover", reset_hover_style)
	reset_btn.add_theme_stylebox_override("pressed", reset_hover_style)

	vbox.add_child(reset_btn)

	# Delete save file button
	var delete_save_btn := Button.new()
	delete_save_btn.text = "Delete Save File"
	delete_save_btn.custom_minimum_size = Vector2(0, 30)
	delete_save_btn.pressed.connect(_delete_save_file)

	var delete_style := StyleBoxFlat.new()
	delete_style.bg_color = Color(0.3, 0.1, 0.1, 0.9)
	delete_style.corner_radius_top_left = 5
	delete_style.corner_radius_top_right = 5
	delete_style.corner_radius_bottom_left = 5
	delete_style.corner_radius_bottom_right = 5
	delete_save_btn.add_theme_stylebox_override("normal", delete_style)
	delete_save_btn.add_theme_stylebox_override("hover", reset_hover_style)
	delete_save_btn.add_theme_stylebox_override("pressed", reset_hover_style)

	vbox.add_child(delete_save_btn)


func _add_dev_button(container: HBoxContainer, text: String, on_click: Callable) -> void:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(55, 28)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.pressed.connect(on_click)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.3, 0.15, 0.9)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("normal", style)

	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(0.2, 0.45, 0.2, 0.95)
	hover_style.corner_radius_top_left = 4
	hover_style.corner_radius_top_right = 4
	hover_style.corner_radius_bottom_left = 4
	hover_style.corner_radius_bottom_right = 4
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", hover_style)

	btn.add_theme_font_size_override("font_size", 11)
	container.add_child(btn)


func _toggle_panel() -> void:
	_is_expanded = not _is_expanded
	if _panel != null:
		_panel.visible = _is_expanded
		if _is_expanded:
			_panel.move_to_front()
	print("DevPanel: Toggled to %s" % ("open" if _is_expanded else "closed"))


func _add_energy(amount: float) -> void:
	GameManager.add_void_energy(BigNumber.new(amount))
	print("DevPanel: Added %s Void Energy" % amount)


func _reset_progress() -> void:
	print("DevPanel: Resetting all progress...")

	GameManager.reset_all_progress()
	UpgradeManager.reset_for_prestige()
	AchievementManager.reset_all()

	SaveManager.delete_save()
	SaveManager.save_game()

	print("DevPanel: Progress reset complete!")


func _delete_save_file() -> void:
	print("DevPanel: Deleting save file...")
	SaveManager.delete_save()
	print("DevPanel: Save file deleted. Restart the game to start fresh.")


func _spawn_meteor(type: int) -> void:
	print("DevPanel: SpawnMeteor called with type %d" % type)
	var meteor_type: int
	match type:
		0: meteor_type = Meteor.MeteorType.SMALL
		1: meteor_type = Meteor.MeteorType.MEDIUM
		2: meteor_type = Meteor.MeteorType.LARGE
		3: meteor_type = Meteor.MeteorType.COMET
		_: meteor_type = Meteor.MeteorType.SMALL

	MeteorManager.spawn_meteor(meteor_type)
	print("DevPanel: Spawned meteor type %d" % meteor_type)


func _spawn_meteor_shower() -> void:
	print("DevPanel: SpawnMeteorShower called")
	MeteorManager.start_meteor_shower()
	print("DevPanel: Started meteor shower!")
