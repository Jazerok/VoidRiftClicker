class_name HUD
extends Control

## HUD - The main Heads-Up Display showing currency and stats

@export var void_energy_label: Label
@export var passive_income_label: Label
@export var click_power_label: Label
@export var shards_label: Label
@export var star_dust_label: Label
@export var frenzy_indicator: Control
@export var frenzy_label: Label
@export var frenzy_timer_label: Label
@export var cps_label: Label
@export var prestige_progress: ProgressBar
@export var prestige_reward_label: Label

var _prestige_screen = null
var _prestige_button: Button = null
var _settings_button: Button = null
var _settings_panel: PanelContainer = null
var _settings_panel_visible: bool = false

var _master_volume_slider: HSlider = null
var _sfx_volume_slider: HSlider = null
var _music_volume_slider: HSlider = null
var _master_volume_label: Label = null
var _sfx_volume_label: Label = null
var _music_volume_label: Label = null
var _mute_toggle: CheckButton = null
var _active_slider: HSlider = null

var _pulse_timer: float = 0.0
var _energy_label_scale: float = 1.0


func _ready() -> void:
	_find_child_nodes()

	if frenzy_indicator:
		frenzy_indicator.visible = false

	if cps_label:
		cps_label.visible = false

	_create_prestige_button()
	_create_mute_button()

	call_deferred("_deferred_initialize")
	call_deferred("_start_background_music")

	pass


func _create_prestige_button() -> void:
	var hbox = get_node_or_null("TopBar/HBox")
	if hbox == null:
		hbox = get_node_or_null("TopBar/MarginContainer/HBox")
	if hbox == null:
		printerr("HUD: Could not find TopBar HBox for prestige button!")
		return

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	var btn_container := VBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	hbox.add_child(btn_container)

	_prestige_button = Button.new()
	_prestige_button.text = "✦ PRESTIGE (P)"
	_prestige_button.custom_minimum_size = Vector2(140, 50)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.4, 0.2, 0.5, 0.9)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.7, 0.4, 0.9, 0.8)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	_prestige_button.add_theme_stylebox_override("normal", style)

	var hover_style := style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.5, 0.3, 0.6, 0.95)
	hover_style.border_color = Color(0.9, 0.6, 1.0, 1.0)
	_prestige_button.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color(0.6, 0.35, 0.7, 1.0)
	_prestige_button.add_theme_stylebox_override("pressed", pressed_style)

	_prestige_button.add_theme_font_size_override("font_size", 14)
	_prestige_button.add_theme_color_override("font_color", Color(0.95, 0.85, 1.0))
	_prestige_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_prestige_button.focus_mode = Control.FOCUS_ALL
	_prestige_button.pressed.connect(_on_prestige_button_pressed)

	btn_container.add_child(_prestige_button)
	pass


func _create_mute_button() -> void:
	_settings_button = Button.new()
	_settings_button.name = "SettingsButton"
	_settings_button.text = "⚙"
	add_child(_settings_button)

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.08, 0.25, 0.9)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.5, 0.3, 0.7, 0.8)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	_settings_button.add_theme_stylebox_override("normal", style)

	var hover_style := style.duplicate() as StyleBoxFlat
	hover_style.bg_color = Color(0.25, 0.15, 0.4, 0.95)
	hover_style.border_color = Color(0.7, 0.5, 0.9, 1.0)
	_settings_button.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := style.duplicate() as StyleBoxFlat
	pressed_style.bg_color = Color(0.35, 0.2, 0.5, 1.0)
	_settings_button.add_theme_stylebox_override("pressed", pressed_style)

	_settings_button.add_theme_font_size_override("font_size", 24)
	_settings_button.add_theme_color_override("font_color", Color(0.9, 0.8, 1.0))
	_settings_button.mouse_filter = Control.MOUSE_FILTER_STOP
	_settings_button.focus_mode = Control.FOCUS_ALL
	_settings_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	_settings_button.pressed.connect(_on_settings_pressed)
	_settings_button.gui_input.connect(_on_settings_gui_input)

	_create_settings_panel()
	call_deferred("_position_settings_button")
	pass


func _position_settings_button() -> void:
	if _settings_button == null:
		return

	var viewport_size := get_viewport_rect().size
	_settings_button.set_deferred("position", Vector2(viewport_size.x - 370, viewport_size.y - 70))
	_settings_button.set_deferred("size", Vector2(55, 55))


func _on_settings_pressed() -> void:
	_toggle_settings_panel()


func _on_settings_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.pressed and mb.button_index == MOUSE_BUTTON_LEFT:
			_toggle_settings_panel()
			_settings_button.accept_event()


func _toggle_settings_panel() -> void:
	_settings_panel_visible = not _settings_panel_visible

	if _settings_panel != null:
		_settings_panel.visible = _settings_panel_visible

		if _settings_panel_visible and AudioManager:
			if _sfx_volume_slider:
				_sfx_volume_slider.value = AudioManager.get_sfx_volume() * 100
			if _music_volume_slider:
				_music_volume_slider.value = AudioManager.get_music_volume() * 100
			if _mute_toggle:
				_mute_toggle.button_pressed = AudioManager.is_muted


func _update_settings_button_position() -> void:
	if _settings_button == null:
		return

	var viewport_size := get_viewport_rect().size
	_settings_button.position = Vector2(viewport_size.x - 370, viewport_size.y - 70)
	_settings_button.size = Vector2(55, 55)

	if _settings_panel != null and _settings_panel.visible:
		_settings_panel.position = Vector2(viewport_size.x - 370, viewport_size.y - 310)


func _create_settings_panel() -> void:
	_settings_panel = PanelContainer.new()
	_settings_panel.custom_minimum_size = Vector2(280, 220)
	add_child(_settings_panel)

	_settings_panel.position = Vector2(10, 130)
	_settings_panel.size = Vector2(280, 220)

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.05, 0.15, 0.95)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.5, 0.3, 0.7, 0.8)
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.content_margin_left = 15
	panel_style.content_margin_right = 15
	panel_style.content_margin_top = 10
	panel_style.content_margin_bottom = 10
	_settings_panel.add_theme_stylebox_override("panel", panel_style)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	_settings_panel.add_child(vbox)

	var title := Label.new()
	title.text = "⚙ AUDIO SETTINGS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.9, 0.7, 1.0))
	vbox.add_child(title)

	vbox.add_child(HSeparator.new())

	# Volume sliders
	var master_container := _create_volume_slider("Master Volume", 0.1)
	_master_volume_slider = master_container.get_meta("slider")
	_master_volume_label = master_container.get_meta("label")
	_master_volume_slider.value_changed.connect(_on_master_volume_changed)
	vbox.add_child(master_container)

	var sfx_container := _create_volume_slider("SFX Volume", 1.0)
	_sfx_volume_slider = sfx_container.get_meta("slider")
	_sfx_volume_label = sfx_container.get_meta("label")
	_sfx_volume_slider.value_changed.connect(_on_sfx_volume_changed)
	vbox.add_child(sfx_container)

	var music_container := _create_volume_slider("Music Volume", 0.7)
	_music_volume_slider = music_container.get_meta("slider")
	_music_volume_label = music_container.get_meta("label")
	_music_volume_slider.value_changed.connect(_on_music_volume_changed)
	vbox.add_child(music_container)

	# Mute toggle
	var mute_container := HBoxContainer.new()
	mute_container.add_theme_constant_override("separation", 10)
	vbox.add_child(mute_container)

	_mute_toggle = CheckButton.new()
	_mute_toggle.text = "Mute All"
	_mute_toggle.add_theme_color_override("font_color", Color(0.85, 0.75, 0.95))
	_mute_toggle.toggled.connect(_on_mute_toggled)
	mute_container.add_child(_mute_toggle)

	_settings_panel.visible = false
	_settings_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_settings_panel.z_index = 100


func _create_volume_slider(label_text: String, default_value: float) -> VBoxContainer:
	var container := VBoxContainer.new()
	container.add_theme_constant_override("separation", 2)

	var hbox := HBoxContainer.new()
	container.add_child(hbox)

	var label := Label.new()
	label.text = label_text
	label.custom_minimum_size = Vector2(100, 0)
	label.add_theme_color_override("font_color", Color(0.8, 0.7, 0.9))
	label.add_theme_font_size_override("font_size", 13)
	hbox.add_child(label)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hbox.add_child(spacer)

	var value_label := Label.new()
	value_label.text = "%d%%" % int(default_value * 100)
	value_label.custom_minimum_size = Vector2(45, 0)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_color_override("font_color", Color(0.6, 0.9, 0.7))
	value_label.add_theme_font_size_override("font_size", 13)
	hbox.add_child(value_label)

	var slider := HSlider.new()
	slider.min_value = 0
	slider.max_value = 100
	slider.value = default_value * 100
	slider.step = 1
	slider.custom_minimum_size = Vector2(230, 20)
	container.add_child(slider)

	container.set_meta("slider", slider)
	container.set_meta("label", value_label)

	return container


func _on_master_volume_changed(value: float) -> void:
	var volume := value / 100.0
	var master_idx := AudioServer.get_bus_index("Master")
	if master_idx < 0:
		master_idx = 0
	AudioServer.set_bus_volume_db(master_idx, linear_to_db(volume))
	if _master_volume_label:
		_master_volume_label.text = "%d%%" % int(value)


func _on_sfx_volume_changed(value: float) -> void:
	var volume := value / 100.0
	AudioManager.set_sfx_volume(volume)
	if _sfx_volume_label:
		_sfx_volume_label.text = "%d%%" % int(value)


func _on_music_volume_changed(value: float) -> void:
	var volume := value / 100.0
	AudioManager.set_music_volume(volume)
	if _music_volume_label:
		_music_volume_label.text = "%d%%" % int(value)


func _on_mute_toggled(toggled: bool) -> void:
	AudioManager.set_muted(toggled)


func _start_background_music() -> void:
	if AudioManager:
		AudioManager.start_ambient_music()
		pass


func _process(delta: float) -> void:
	_update_settings_button_position()
	_update_prestige_preview()

	if void_energy_label:
		_energy_label_scale = lerpf(_energy_label_scale, 1.0, delta * 10.0)
		void_energy_label.scale = Vector2(_energy_label_scale, _energy_label_scale)

	if frenzy_indicator and frenzy_indicator.visible:
		_pulse_timer += delta * 4
		var pulse := 1.0 + sin(_pulse_timer) * 0.1
		frenzy_indicator.scale = Vector2(pulse, pulse)

		if frenzy_timer_label:
			var time_left := GameManager.frenzy_time_remaining
			frenzy_timer_label.text = "%.1fs" % time_left


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_button := event as InputEventMouseButton
		if mouse_button.pressed and mouse_button.button_index == MOUSE_BUTTON_LEFT:
			if _settings_button and _settings_button.visible:
				var settings_rect := _settings_button.get_global_rect()
				if settings_rect.has_point(mouse_button.position):
					_toggle_settings_panel()
					get_viewport().set_input_as_handled()
					return

			if _settings_panel_visible and _mute_toggle and _mute_toggle.get_global_rect().has_point(mouse_button.position):
				_mute_toggle.button_pressed = not _mute_toggle.button_pressed
				_on_mute_toggled(_mute_toggle.button_pressed)
				get_viewport().set_input_as_handled()
				return

			if _prestige_button and _prestige_button.get_global_rect().has_point(mouse_button.global_position):
				_on_prestige_button_pressed()
				get_viewport().set_input_as_handled()

	if _settings_panel_visible and event is InputEventMouseMotion and Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_handle_slider_drag(event.position)

	if _settings_panel_visible and event is InputEventMouseButton:
		var mb := event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_handle_slider_click(mb.position, mb.pressed)

	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and key.keycode == KEY_ESCAPE:
			if _settings_panel_visible and _settings_panel:
				_settings_panel_visible = false
				_settings_panel.visible = false
				get_viewport().set_input_as_handled()


func _handle_slider_click(pos: Vector2, pressed: bool) -> void:
	if pressed:
		if _master_volume_slider and _master_volume_slider.get_global_rect().has_point(pos):
			_active_slider = _master_volume_slider
			_update_slider_from_position(_master_volume_slider, pos)
		elif _sfx_volume_slider and _sfx_volume_slider.get_global_rect().has_point(pos):
			_active_slider = _sfx_volume_slider
			_update_slider_from_position(_sfx_volume_slider, pos)
		elif _music_volume_slider and _music_volume_slider.get_global_rect().has_point(pos):
			_active_slider = _music_volume_slider
			_update_slider_from_position(_music_volume_slider, pos)
	else:
		_active_slider = null


func _handle_slider_drag(pos: Vector2) -> void:
	if _active_slider != null:
		_update_slider_from_position(_active_slider, pos)


func _update_slider_from_position(slider: HSlider, pos: Vector2) -> void:
	var rect := slider.get_global_rect()
	var ratio := clampf((pos.x - rect.position.x) / rect.size.x, 0, 1)
	var new_value := slider.min_value + ratio * (slider.max_value - slider.min_value)
	slider.value = new_value

	if slider == _master_volume_slider:
		_on_master_volume_changed(new_value)
	elif slider == _sfx_volume_slider:
		_on_sfx_volume_changed(new_value)
	elif slider == _music_volume_slider:
		_on_music_volume_changed(new_value)


func _on_prestige_button_pressed() -> void:
	pass

	if _prestige_screen == null:
		_prestige_screen = get_node_or_null("../PrestigeScreen")
		if _prestige_screen == null:
			var ui := get_parent()
			if ui:
				_prestige_screen = ui.get_node_or_null("PrestigeScreen")
		if _prestige_screen == null:
			_prestige_screen = get_tree().root.find_child("PrestigeScreen", true, false)

	if _prestige_screen:
		_prestige_screen.toggle()
	else:
		printerr("HUD: Could not find PrestigeScreen!")


func _deferred_initialize() -> void:
	if GameManager:
		GameManager.void_energy_changed.connect(_on_void_energy_changed)
		GameManager.dimensional_shards_changed.connect(_on_shards_changed)
		GameManager.star_dust_changed.connect(_on_star_dust_changed)
		GameManager.click_power_changed.connect(_on_click_power_changed)
		GameManager.passive_income_changed.connect(_on_passive_income_changed)
		GameManager.frenzy_state_changed.connect(_on_frenzy_state_changed)
		GameManager.click_registered.connect(_on_click_registered)

		_initialize_display()
		pass
	else:
		printerr("HUD: GameManager not found!")


func _find_child_nodes() -> void:
	if void_energy_label == null:
		void_energy_label = get_node_or_null("TopBar/HBox/EnergyContainer/VoidEnergyLabel")
	if void_energy_label == null:
		void_energy_label = get_node_or_null("TopBar/MarginContainer/HBox/EnergyContainer/VoidEnergyLabel")

	if passive_income_label == null:
		passive_income_label = get_node_or_null("TopBar/HBox/IncomeContainer/PassiveIncomeLabel")
	if passive_income_label == null:
		passive_income_label = get_node_or_null("TopBar/MarginContainer/HBox/IncomeContainer/PassiveIncomeLabel")

	if click_power_label == null:
		click_power_label = get_node_or_null("TopBar/HBox/ClickContainer/ClickPowerLabel")
	if click_power_label == null:
		click_power_label = get_node_or_null("TopBar/MarginContainer/HBox/ClickContainer/ClickPowerLabel")

	if cps_label == null:
		cps_label = get_node_or_null("CPSLabel")
	if frenzy_indicator == null:
		frenzy_indicator = get_node_or_null("FrenzyIndicator")
	if frenzy_label == null:
		frenzy_label = get_node_or_null("FrenzyIndicator/FrenzyLabel")
	if frenzy_timer_label == null:
		frenzy_timer_label = get_node_or_null("FrenzyIndicator/VBox/FrenzyTimerLabel")


func _exit_tree() -> void:
	if GameManager:
		GameManager.void_energy_changed.disconnect(_on_void_energy_changed)
		GameManager.dimensional_shards_changed.disconnect(_on_shards_changed)
		GameManager.star_dust_changed.disconnect(_on_star_dust_changed)
		GameManager.click_power_changed.disconnect(_on_click_power_changed)
		GameManager.passive_income_changed.disconnect(_on_passive_income_changed)
		GameManager.frenzy_state_changed.disconnect(_on_frenzy_state_changed)
		GameManager.click_registered.disconnect(_on_click_registered)


func _initialize_display() -> void:
	_on_void_energy_changed(GameManager.void_energy.to_formatted_string())
	_on_shards_changed(GameManager.dimensional_shards.to_formatted_string())
	_on_star_dust_changed(GameManager.star_dust.to_formatted_string())
	_on_click_power_changed(GameManager.effective_click_power.to_formatted_string())
	_on_passive_income_changed(GameManager.effective_passive_income.to_formatted_string())


func _on_void_energy_changed(formatted_amount: String) -> void:
	if void_energy_label:
		void_energy_label.text = formatted_amount


func _on_shards_changed(formatted_amount: String) -> void:
	if shards_label:
		shards_label.text = formatted_amount


func _on_star_dust_changed(formatted_amount: String) -> void:
	if star_dust_label:
		star_dust_label.text = formatted_amount


func _on_click_power_changed(formatted_power: String) -> void:
	if click_power_label:
		click_power_label.text = "+%s/click" % formatted_power


func _on_passive_income_changed(formatted_rate: String) -> void:
	if passive_income_label:
		passive_income_label.text = "+%s/sec" % formatted_rate


func _on_frenzy_state_changed(is_active: bool, multiplier: float) -> void:
	if frenzy_indicator:
		frenzy_indicator.visible = is_active
		if is_active and frenzy_label:
			frenzy_label.text = "✦ COSMIC SURGE x%.1f ✦" % multiplier


func _on_click_registered(_formatted_amount: String) -> void:
	_energy_label_scale = 1.15


func _update_prestige_preview() -> void:
	var potential: BigNumber = GameManager.potential_star_dust

	if prestige_reward_label:
		if potential.is_zero:
			prestige_reward_label.text = "Prestige: Not yet available"
		else:
			prestige_reward_label.text = "Prestige: +%s Star Dust" % potential.to_formatted_string()

	if prestige_progress:
		var current_sd := potential.to_double()
		var next_sd := current_sd + 1
		var energy_for_next := next_sd * next_sd * 1e9
		var current_energy := GameManager.total_void_energy_earned.to_double()

		if current_sd == 0:
			prestige_progress.value = current_energy / 1e9 * 100
		else:
			var energy_for_current := current_sd * current_sd * 1e9
			var progress := (current_energy - energy_for_current) / (energy_for_next - energy_for_current)
			prestige_progress.value = clampf(progress * 100, 0, 100)


func refresh_all() -> void:
	_initialize_display()


func show_notification(message: String, _duration: float = 2.0) -> void:
	pass
