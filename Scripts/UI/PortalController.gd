class_name PortalController
extends Node2D

## PortalController - Controls the main clickable portal visuals and animations

@export var portal_sprite: Sprite2D
@export var outer_ring: Sprite2D
@export var inner_glow: Sprite2D
@export var ambient_particles: GPUParticles2D
@export var click_particles: GPUParticles2D
@export var frenzy_particles: GPUParticles2D
@export var glow_light: PointLight2D
@export var click_area: Area2D

# Configuration
@export var base_rotation_speed: float = 15.0
@export var frenzy_rotation_speed: float = 60.0
@export var base_scale: float = 1.0
@export var click_scale: float = 0.9
@export var hover_scale: float = 1.05

# State
var _current_rotation_speed: float
var _target_scale: float
var _current_scale: float
var _is_hovering: bool = false
var _is_pressed: bool = false
var _pulse_timer: float = 0.0
var _time_since_click: float = 0.0

# Colors
const NORMAL_COLOR := Color(0.6, 0.4, 0.9)
const FRENZY_COLOR := Color(1.0, 0.6, 0.2)
var _target_color: Color = NORMAL_COLOR


func _ready() -> void:
	_current_rotation_speed = base_rotation_speed
	_target_scale = base_scale
	_current_scale = base_scale

	if click_area:
		click_area.mouse_entered.connect(_on_mouse_entered)
		click_area.mouse_exited.connect(_on_mouse_exited)
		click_area.input_event.connect(_on_input_event)

	if GameManager:
		GameManager.frenzy_state_changed.connect(_on_frenzy_state_changed)
		GameManager.click_registered.connect(_on_click_registered)

	if frenzy_particles:
		frenzy_particles.emitting = false

	print("PortalController: Ready")


func _process(delta: float) -> void:
	_pulse_timer += delta
	_time_since_click += delta

	_update_rotation(delta)
	_update_scale(delta)
	_update_glow(delta)
	_update_color(delta)

	if _is_pressed and _is_hovering:
		_try_click()


func _exit_tree() -> void:
	if click_area:
		click_area.mouse_entered.disconnect(_on_mouse_entered)
		click_area.mouse_exited.disconnect(_on_mouse_exited)
		click_area.input_event.disconnect(_on_input_event)

	if GameManager:
		GameManager.frenzy_state_changed.disconnect(_on_frenzy_state_changed)
		GameManager.click_registered.disconnect(_on_click_registered)


func _update_rotation(delta: float) -> void:
	if portal_sprite:
		portal_sprite.rotation += deg_to_rad(_current_rotation_speed * delta)

	if outer_ring:
		outer_ring.rotation -= deg_to_rad(_current_rotation_speed * 0.5 * delta)


func _update_scale(delta: float) -> void:
	if _is_pressed and _is_hovering:
		_target_scale = click_scale
	elif _is_hovering:
		_target_scale = hover_scale
	else:
		_target_scale = base_scale

	_current_scale = lerpf(_current_scale, _target_scale, delta * 15.0)

	var scale_vec := Vector2(_current_scale, _current_scale)
	if portal_sprite:
		portal_sprite.scale = scale_vec
	if outer_ring:
		outer_ring.scale = scale_vec
	if inner_glow:
		inner_glow.scale = scale_vec


func _update_glow(delta: float) -> void:
	if inner_glow:
		var pulse := 0.8 + sin(_pulse_timer * 2.0) * 0.2
		inner_glow.modulate.a = pulse

	if glow_light:
		var base_power := 1.0
		var pulse := 1.0 + sin(_pulse_timer * 3.0) * 0.1

		var income := GameManager.effective_passive_income.to_double()
		if income > 0:
			base_power += log(income + 1) / log(10) * 0.1

		if GameManager.is_frenzy_active:
			base_power *= 1.5
			pulse = 1.0 + sin(_pulse_timer * 8.0) * 0.2

		glow_light.energy = base_power * pulse


func _update_color(delta: float) -> void:
	if portal_sprite == null:
		return

	portal_sprite.modulate = portal_sprite.modulate.lerp(_target_color, delta * 3.0)

	if inner_glow:
		var glow_target := _target_color
		glow_target.a = 0.5
		inner_glow.modulate = inner_glow.modulate.lerp(glow_target, delta * 3.0)


func _on_mouse_entered() -> void:
	_is_hovering = true
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func _on_mouse_exited() -> void:
	_is_hovering = false
	_is_pressed = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _on_input_event(_viewport: Node, event: InputEvent, _shape_idx: int) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_is_pressed = mouse_event.pressed
			if mouse_event.pressed:
				_try_click()


func _try_click() -> void:
	if _time_since_click < 0.05:
		return

	var success := GameManager.process_click()

	if success:
		_time_since_click = 0
		_play_click_effect()


func _play_click_effect() -> void:
	if click_particles:
		click_particles.restart()
		click_particles.emitting = true

	if inner_glow:
		inner_glow.modulate = Color.WHITE

	AudioManager.play_click_sfx()


func _on_frenzy_state_changed(is_active: bool, _multiplier: float) -> void:
	if is_active:
		_current_rotation_speed = frenzy_rotation_speed
		_target_color = FRENZY_COLOR
		if frenzy_particles:
			frenzy_particles.emitting = true
	else:
		_current_rotation_speed = base_rotation_speed
		_target_color = NORMAL_COLOR
		if frenzy_particles:
			frenzy_particles.emitting = false


func _on_click_registered(_formatted_amount: String) -> void:
	pass


func play_special_effect() -> void:
	if portal_sprite:
		portal_sprite.modulate = Color.WHITE
	if outer_ring:
		outer_ring.modulate = Color.WHITE
	if inner_glow:
		inner_glow.modulate = Color.WHITE

	if click_particles:
		click_particles.restart()
		click_particles.emitting = true
	if frenzy_particles:
		frenzy_particles.restart()
		frenzy_particles.emitting = true

	get_tree().create_timer(0.5).timeout.connect(func():
		if portal_sprite:
			portal_sprite.modulate = _target_color
		if outer_ring:
			outer_ring.modulate = _target_color
	)


func update_visual_intensity() -> void:
	var income := GameManager.effective_passive_income.to_double()
	var intensity := 1.0

	if income > 0:
		intensity = 1.0 + log(income + 1) / log(10) * 0.1
		intensity = clampf(intensity, 1.0, 3.0)

	base_rotation_speed = 15.0 * intensity
	if not GameManager.is_frenzy_active:
		_current_rotation_speed = base_rotation_speed
