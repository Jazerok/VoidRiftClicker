class_name ClickHandler
extends Node2D

## ClickHandler - Manages click detection and rate limiting

@export var portal_sprite: Sprite2D
@export var anim_player: AnimationPlayer
@export var click_area: Area2D
@export var click_particles: GPUParticles2D
@export var damage_number_scene: PackedScene

# Click tracking
var _is_hovering: bool = false
var _is_pressed: bool = false
var _time_since_last_click: float = 0.0

var _min_click_interval: float:
	get: return 1.0 / GameManager.max_clicks_per_second

# Visual feedback
const HOVER_SCALE := 1.05
const CLICK_SCALE := 0.95
const SCALE_RETURN_SPEED := 10.0

var _target_scale: float = 1.0
var _rotation_speed: float = 20.0


func _ready() -> void:
	if click_area:
		click_area.mouse_entered.connect(_on_mouse_entered)
		click_area.mouse_exited.connect(_on_mouse_exited)
		click_area.input_pickable = true

	if GameManager:
		GameManager.click_registered.connect(_on_click_registered)
		GameManager.frenzy_state_changed.connect(_on_frenzy_state_changed)

	pass


func _process(delta: float) -> void:
	_time_since_last_click += delta

	if portal_sprite:
		portal_sprite.rotation += delta * deg_to_rad(_rotation_speed)

	if portal_sprite:
		var current_scale := portal_sprite.scale.x
		var new_scale := lerpf(current_scale, _target_scale, delta * SCALE_RETURN_SPEED)
		portal_sprite.scale = Vector2(new_scale, new_scale)

	if _is_pressed and _is_hovering:
		_try_click()


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse_event := event as InputEventMouseButton
		if mouse_event.button_index == MOUSE_BUTTON_LEFT:
			_is_pressed = mouse_event.pressed

			if mouse_event.pressed and _is_hovering:
				_try_click()


func _try_click() -> void:
	if _time_since_last_click < _min_click_interval:
		return

	var click_registered := GameManager.process_click()

	if click_registered:
		_time_since_last_click = 0
		_apply_click_effect()


func _apply_click_effect() -> void:
	_target_scale = CLICK_SCALE

	get_tree().create_timer(0.05).timeout.connect(func():
		_target_scale = HOVER_SCALE if _is_hovering else 1.0
	)

	if anim_player and anim_player.has_animation("click"):
		anim_player.play("click")

	if click_particles:
		click_particles.restart()
		click_particles.emitting = true


func _on_mouse_entered() -> void:
	_is_hovering = true
	_target_scale = HOVER_SCALE
	Input.set_default_cursor_shape(Input.CURSOR_POINTING_HAND)


func _on_mouse_exited() -> void:
	_is_hovering = false
	_target_scale = 1.0
	_is_pressed = false
	Input.set_default_cursor_shape(Input.CURSOR_ARROW)


func _on_click_registered(formatted_amount: String) -> void:
	if damage_number_scene:
		_spawn_damage_number(formatted_amount)


func _on_frenzy_state_changed(is_active: bool, multiplier: float) -> void:
	if is_active:
		_rotation_speed = 60.0
		if portal_sprite:
			portal_sprite.modulate = Color(1.5, 1.0, 1.5)
	else:
		_rotation_speed = 20.0
		if portal_sprite:
			portal_sprite.modulate = Color.WHITE


func _spawn_damage_number(formatted_amount: String) -> void:
	var damage_number := damage_number_scene.instantiate() as Node2D
	if not damage_number:
		return

	var mouse_pos := get_global_mouse_position()
	var random_x := randf_range(-50, 50)
	var random_y := randf_range(-30, -60)
	damage_number.global_position = mouse_pos + Vector2(random_x, random_y)

	var label := damage_number.get_node_or_null("Label") as Label
	if label:
		label.text = "+%s" % formatted_amount

		if GameManager.is_frenzy_active:
			label.modulate = Color(1.0, 0.8, 0.2)

	get_tree().root.add_child(damage_number)


func _exit_tree() -> void:
	if click_area:
		click_area.mouse_entered.disconnect(_on_mouse_entered)
		click_area.mouse_exited.disconnect(_on_mouse_exited)

	if GameManager:
		GameManager.click_registered.disconnect(_on_click_registered)
		GameManager.frenzy_state_changed.disconnect(_on_frenzy_state_changed)
