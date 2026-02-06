class_name Meteor
extends Control

## Meteor - A clickable bonus object that flies across the screen

enum MeteorType {
	SMALL,
	MEDIUM,
	LARGE,
	COMET
}

enum RewardType {
	COMBO_MULTIPLIER,
	FRENZY_BOOST,
	ENERGY_BURST,
	CRIT_BOOST
}

signal meteor_clicked(meteor: Meteor)
signal meteor_expired(meteor: Meteor)

var meteor_type: int = MeteorType.SMALL
var reward_type: int = RewardType.COMBO_MULTIPLIER
var meteor_size: float = 25.0
var velocity: Vector2 = Vector2.ZERO

# Visual properties
var _core_color: Color
var _glow_color: Color
var _trail_color: Color
var _pulse_timer: float = 0.0
var _trail_timer: float = 0.0
var _rotation: float = 0.0
var _rotation_speed: float = 1.0

# Trail particles
var _trail_positions: Array[Vector2] = []
var _trail_index: int = 0
var _trail_update_timer: float = 0.0

# Click detection
var _is_hovered: bool = false
var _was_clicked: bool = false

# Lifetime
var _lifetime: float = 0.0
var _max_lifetime: float = 15.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	# Initialize trail positions
	_trail_positions.resize(6)
	for i in _trail_positions.size():
		_trail_positions[i] = global_position

	_rotation_speed = randf_range(0.5, 2.0) * (1 if randf() > 0.5 else -1)


func initialize(type: int, start_pos: Vector2, vel: Vector2) -> void:
	meteor_type = type
	position = start_pos
	velocity = vel

	# Set size based on type
	match type:
		MeteorType.SMALL:
			meteor_size = randf_range(12, 18)
		MeteorType.MEDIUM:
			meteor_size = randf_range(28, 40)
		MeteorType.LARGE:
			meteor_size = randf_range(50, 70)
		MeteorType.COMET:
			meteor_size = randf_range(35, 50)
		_:
			meteor_size = 25

	var control_size := meteor_size * 3
	custom_minimum_size = Vector2(control_size, control_size)
	size = Vector2(control_size, control_size)

	_set_colors_for_type(type)
	_assign_reward(type)




func _set_colors_for_type(type: int) -> void:
	match type:
		MeteorType.SMALL:
			_core_color = Color(0.6, 0.5, 0.4)
			_glow_color = Color(1.0, 0.6, 0.3, 0.6)
			_trail_color = Color(1.0, 0.5, 0.2, 0.4)
		MeteorType.MEDIUM:
			_core_color = Color(0.4, 0.5, 0.7)
			_glow_color = Color(0.4, 0.7, 1.0, 0.7)
			_trail_color = Color(0.3, 0.6, 1.0, 0.5)
		MeteorType.LARGE:
			_core_color = Color(0.5, 0.3, 0.6)
			_glow_color = Color(0.8, 0.4, 1.0, 0.8)
			_trail_color = Color(0.7, 0.3, 1.0, 0.6)
		MeteorType.COMET:
			_core_color = Color(0.9, 0.95, 1.0)
			_glow_color = Color(0.5, 0.9, 1.0, 0.9)
			_trail_color = Color(0.4, 0.8, 1.0, 0.7)


func _assign_reward(type: int) -> void:
	var roll := randf()

	match type:
		MeteorType.SMALL:
			reward_type = RewardType.COMBO_MULTIPLIER if roll < 0.7 else RewardType.ENERGY_BURST
		MeteorType.MEDIUM:
			if roll < 0.5:
				reward_type = RewardType.COMBO_MULTIPLIER
			elif roll < 0.8:
				reward_type = RewardType.FRENZY_BOOST
			else:
				reward_type = RewardType.ENERGY_BURST
		MeteorType.LARGE:
			if roll < 0.4:
				reward_type = RewardType.FRENZY_BOOST
			elif roll < 0.7:
				reward_type = RewardType.ENERGY_BURST
			else:
				reward_type = RewardType.CRIT_BOOST
		MeteorType.COMET:
			reward_type = RewardType.FRENZY_BOOST if roll < 0.5 else RewardType.CRIT_BOOST
		_:
			reward_type = RewardType.COMBO_MULTIPLIER


func _process(delta: float) -> void:
	if _was_clicked:
		return

	position += velocity * delta
	_rotation += _rotation_speed * delta
	_pulse_timer += delta * 3.0

	# Update trail
	_trail_update_timer += delta
	if _trail_update_timer > 0.02:
		_trail_update_timer = 0
		_trail_positions[_trail_index] = global_position + Vector2(meteor_size * 0.5, meteor_size * 0.5)
		_trail_index = (_trail_index + 1) % _trail_positions.size()

	# Check lifetime
	_lifetime += delta
	if _lifetime > _max_lifetime:
		meteor_expired.emit(self)
		queue_free()
		return

	# Check if off screen
	var viewport := get_viewport_rect()
	var padding := meteor_size * 3
	if position.x < -padding or position.x > viewport.size.x + padding or \
	   position.y < -padding or position.y > viewport.size.y + padding:
		meteor_expired.emit(self)
		queue_free()

	queue_redraw()


func _draw() -> void:
	var center := Vector2(meteor_size, meteor_size)
	var pulse := 1.0 + sin(_pulse_timer) * 0.15

	_draw_trail(center)

	# Draw outer glow
	for i in range(2, 0, -1):
		var glow_size := meteor_size * (0.8 + i * 0.6) * pulse
		var glow := _glow_color
		glow.a = _glow_color.a * (0.15 / i)
		draw_circle(center, glow_size, glow)

	if meteor_type == MeteorType.COMET:
		_draw_comet(center, pulse)
	else:
		_draw_rocky_meteor(center, pulse)

	# Draw highlight
	var highlight_offset := Vector2(-meteor_size * 0.25, -meteor_size * 0.25)
	var highlight_size := meteor_size * 0.2
	var highlight_color := Color(1, 1, 1, 0.6 * pulse)
	draw_circle(center + highlight_offset, highlight_size, highlight_color)

	# Draw hover effect
	if _is_hovered:
		var hover_glow := Color(1, 1, 1, 0.3 + sin(_pulse_timer * 2) * 0.2)
		draw_circle(center, meteor_size * 1.3, hover_glow)
		_draw_click_hint(center)


func _draw_trail(center: Vector2) -> void:
	for i in _trail_positions.size():
		var idx := (_trail_index + i) % _trail_positions.size()
		var trail_pos: Vector2 = _trail_positions[idx] - global_position

		var age := float(i) / _trail_positions.size()
		var trail_size := meteor_size * 0.6 * (1 - age * 0.7)

		var trail_col := _trail_color
		trail_col.a = _trail_color.a * (1 - age)

		if meteor_type == MeteorType.COMET:
			trail_size *= 1.5
			trail_col.a *= 1.3

		draw_circle(trail_pos, trail_size, trail_col)


func _draw_rocky_meteor(center: Vector2, pulse: float) -> void:
	var base_size := meteor_size * pulse

	var points := 8
	var vertices: PackedVector2Array = []
	var colors: PackedColorArray = []

	for i in points:
		var angle := (float(i) / points) * PI * 2 + _rotation
		var radius_variation := 0.8 + sin(i * 2.5 + _rotation * 0.5) * 0.2
		var radius := base_size * radius_variation

		vertices.append(center + Vector2(cos(angle) * radius, sin(angle) * radius))
		colors.append(_core_color)

	draw_polygon(vertices, colors)
	_draw_craters(center, base_size)

	var core_glow := _glow_color
	core_glow.a = 0.4
	draw_circle(center, base_size * 0.5, core_glow)


func _draw_craters(center: Vector2, size: float) -> void:
	var crater_color := _core_color.darkened(0.3)

	var crater1 := center + Vector2(size * 0.3, size * 0.1).rotated(_rotation)
	draw_circle(crater1, size * 0.15, crater_color)

	var crater2 := center + Vector2(-size * 0.2, size * 0.35).rotated(_rotation)
	draw_circle(crater2, size * 0.12, crater_color)

	if meteor_type == MeteorType.LARGE:
		var crater3 := center + Vector2(size * 0.1, -size * 0.3).rotated(_rotation)
		draw_circle(crater3, size * 0.18, crater_color)


func _draw_comet(center: Vector2, pulse: float) -> void:
	var base_size := meteor_size * pulse

	draw_circle(center, base_size * 0.8, _core_color)

	var facets := 6
	for i in facets:
		var angle := (float(i) / facets) * PI * 2 + _rotation * 0.5
		var facet_dir := Vector2(cos(angle), sin(angle))

		var crystal: PackedVector2Array = [
			center,
			center + facet_dir * base_size * 1.2 + facet_dir.rotated(0.3) * base_size * 0.3,
			center + facet_dir * base_size * 1.2 + facet_dir.rotated(-0.3) * base_size * 0.3
		]

		var crystal_color := _glow_color
		crystal_color.a = 0.5 + sin(_pulse_timer + i) * 0.2

		draw_polygon(crystal, [crystal_color, crystal_color, crystal_color])

	draw_circle(center, base_size * 0.4, Color(1, 1, 1, 0.8))
	_draw_sparkles(center, base_size)


func _draw_sparkles(center: Vector2, size: float) -> void:
	for i in 5:
		var angle := _pulse_timer * 0.5 + i * 1.2
		var distance := size * (0.8 + sin(_pulse_timer * 2 + i) * 0.4)
		var sparkle_pos := center + Vector2(cos(angle), sin(angle)) * distance

		var sparkle_size := size * 0.1 * (0.5 + sin(_pulse_timer * 3 + i * 2) * 0.5)
		var sparkle_color := Color(1, 1, 1, 0.8)

		draw_line(sparkle_pos - Vector2(sparkle_size, 0), sparkle_pos + Vector2(sparkle_size, 0), sparkle_color, 2)
		draw_line(sparkle_pos - Vector2(0, sparkle_size), sparkle_pos + Vector2(0, sparkle_size), sparkle_color, 2)


func _draw_click_hint(center: Vector2) -> void:
	var ring_size := meteor_size * 1.5 + sin(_pulse_timer * 4) * meteor_size * 0.2
	var ring_color := Color(1, 1, 0.5, 0.5)
	draw_arc(center, ring_size, 0, PI * 2, 32, ring_color, 3)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_on_clicked()
			get_viewport().set_input_as_handled()


func _input(event: InputEvent) -> void:
	if _was_clicked:
		return

	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.pressed and mouse_event.button_index == MOUSE_BUTTON_LEFT:
			var mouse_pos := get_global_mouse_position()
			var meteor_center := global_position + Vector2(meteor_size, meteor_size)
			var distance := mouse_pos.distance_to(meteor_center)

			if distance <= meteor_size * 1.5:
				_on_clicked()
				get_viewport().set_input_as_handled()


func _on_mouse_entered() -> void:
	_is_hovered = true


func _on_mouse_exited() -> void:
	_is_hovered = false


func _on_clicked() -> void:
	if _was_clicked:
		return
	_was_clicked = true



	# Play sound
	if AudioManager:
		if meteor_type == MeteorType.COMET:
			AudioManager.play_comet_explode_sfx()
		else:
			AudioManager.play_meteor_explode_sfx()

	_apply_reward()
	meteor_clicked.emit(self)
	_play_explosion_effect()


func _apply_reward() -> void:
	match reward_type:
		RewardType.COMBO_MULTIPLIER:
			_apply_combo_multiplier()
		RewardType.FRENZY_BOOST:
			_apply_frenzy_boost()
		RewardType.ENERGY_BURST:
			_apply_energy_burst()
		RewardType.CRIT_BOOST:
			_apply_crit_boost()


func _apply_combo_multiplier() -> void:
	var multiplier: float
	var duration: float

	match meteor_type:
		MeteorType.SMALL:
			multiplier = 1.5
			duration = 5.0
		MeteorType.MEDIUM:
			multiplier = 2.0
			duration = 8.0
		MeteorType.LARGE:
			multiplier = 3.0
			duration = 10.0
		MeteorType.COMET:
			multiplier = 5.0
			duration = 15.0
		_:
			multiplier = 1.5
			duration = 5.0

	GameManager.apply_temporary_multiplier(multiplier, duration, "Meteor Combo")
	pass


func _apply_frenzy_boost() -> void:
	var boost: float

	match meteor_type:
		MeteorType.SMALL:
			boost = 0.75
		MeteorType.MEDIUM:
			boost = 0.5
		MeteorType.LARGE:
			boost = 0.25
		MeteorType.COMET:
			boost = 2.0
		_:
			boost = 0.5

	GameManager.boost_frenzy(boost)
	pass


func _apply_energy_burst() -> void:
	var income_multiplier: float

	match meteor_type:
		MeteorType.SMALL:
			income_multiplier = 10
		MeteorType.MEDIUM:
			income_multiplier = 30
		MeteorType.LARGE:
			income_multiplier = 100
		MeteorType.COMET:
			income_multiplier = 300
		_:
			income_multiplier = 10

	var bonus: BigNumber = GameManager.effective_passive_income.multiply(income_multiplier)
	if bonus.is_zero:
		bonus = GameManager.effective_click_power.multiply(income_multiplier)

	GameManager.add_void_energy(bonus)
	pass


func _apply_crit_boost() -> void:
	var chance: float
	var duration: float

	match meteor_type:
		MeteorType.SMALL:
			chance = 0.1
			duration = 10.0
		MeteorType.MEDIUM:
			chance = 0.2
			duration = 15.0
		MeteorType.LARGE:
			chance = 0.3
			duration = 20.0
		MeteorType.COMET:
			chance = 0.5
			duration = 30.0
		_:
			chance = 0.1
			duration = 10.0

	GameManager.apply_temporary_crit_boost(chance, duration)
	pass


func _play_explosion_effect() -> void:
	var meteor_visual_center := global_position + Vector2(meteor_size, meteor_size)

	var explosion := MeteorExplosion.new()
	explosion.initialize(_glow_color, _core_color, meteor_size, meteor_type == MeteorType.COMET)
	get_parent().add_child(explosion)

	var explosion_half_size := meteor_size * 5
	explosion.global_position = meteor_visual_center - Vector2(explosion_half_size, explosion_half_size)

	queue_free()
