extends Node

## MeteorManager - Spawns and manages meteor showers and comets

signal meteor_spawned(meteor: Node)
signal meteor_caught(meteor: Node)
signal meteor_shower_started(count: int)

@export var min_spawn_interval: float = 30.0
@export var max_spawn_interval: float = 90.0
@export var min_comet_interval: float = 300.0
@export var max_comet_interval: float = 900.0
@export var shower_chance: float = 0.1
@export var base_meteor_speed: float = 150.0

var _meteor_timer: float = 0.0
var _next_meteor_time: float = 0.0
var _comet_timer: float = 0.0
var _next_comet_time: float = 0.0
var _active_meteors: Array = []
var _meteor_container: Control

var total_meteors_spawned: int = 0
var total_meteors_clicked: int = 0
var total_comets_clicked: int = 0


func _ready() -> void:
	_next_meteor_time = randf_range(min_spawn_interval * 0.5, max_spawn_interval * 0.5)
	_next_comet_time = randf_range(min_comet_interval, max_comet_interval)
	print("MeteorManager: Ready! First meteor in %.1fs, first comet in %.1fs" % [_next_meteor_time, _next_comet_time])


func _process(delta: float) -> void:
	_meteor_timer += delta
	if _meteor_timer >= _next_meteor_time:
		_meteor_timer = 0
		_next_meteor_time = randf_range(min_spawn_interval, max_spawn_interval)
		start_meteor_shower()

	_comet_timer += delta
	if _comet_timer >= _next_comet_time:
		_comet_timer = 0
		_next_comet_time = randf_range(min_comet_interval, max_comet_interval)
		spawn_comet()

	# Clean up destroyed meteors
	_active_meteors = _active_meteors.filter(func(m): return is_instance_valid(m))


func set_meteor_container(container: Control) -> void:
	_meteor_container = container
	print("MeteorManager: Container set")


func _get_or_create_container() -> Control:
	if _meteor_container and is_instance_valid(_meteor_container):
		return _meteor_container

	var root := get_tree().root
	var ui := root.find_child("UI", true, false) as CanvasLayer
	if ui:
		var meteor_layer := ui.get_node_or_null("MeteorLayer") as Control
		if not meteor_layer:
			meteor_layer = Control.new()
			meteor_layer.name = "MeteorLayer"
			meteor_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
			meteor_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
			ui.add_child(meteor_layer)
			ui.move_child(meteor_layer, 0)
			print("MeteorManager: Created MeteorLayer in UI")
		_meteor_container = meteor_layer
		return meteor_layer

	var any_control := root.find_child("*", true, false) as Control
	if any_control:
		_meteor_container = any_control
		print("MeteorManager: Using %s as container" % any_control.name)
		return any_control

	push_error("MeteorManager: No suitable container found!")
	return null


func spawn_random_meteor() -> void:
	var roll := randf()
	var meteor_type: int

	if roll < 0.60:
		meteor_type = Meteor.MeteorType.SMALL
	elif roll < 0.85:
		meteor_type = Meteor.MeteorType.MEDIUM
	else:
		meteor_type = Meteor.MeteorType.LARGE

	spawn_meteor(meteor_type)


func spawn_comet() -> void:
	print("MeteorManager: Spawning rare COMET!")
	spawn_meteor(Meteor.MeteorType.COMET)


func spawn_meteor(meteor_type: int) -> void:
	print("MeteorManager: Attempting to spawn %s meteor..." % Meteor.MeteorType.keys()[meteor_type])

	var container := _get_or_create_container()
	if not container:
		push_error("MeteorManager: Cannot spawn meteor - no container!")
		return

	print("MeteorManager: Using container: %s" % container.name)

	var meteor := Meteor.new()
	container.add_child(meteor)

	var trajectory := _calculate_trajectory(meteor_type)
	meteor.initialize(meteor_type, trajectory[0], trajectory[1])

	meteor.meteor_clicked.connect(_on_meteor_clicked)
	meteor.meteor_expired.connect(_on_meteor_expired)

	_active_meteors.append(meteor)
	total_meteors_spawned += 1

	meteor_spawned.emit(meteor)


func start_meteor_shower() -> void:
	var count := randi_range(5, 12)

	var has_comet := randf() < 0.08
	var comet_index := randi_range(0, count - 1) if has_comet else -1

	if has_comet:
		print("MeteorManager: METEOR SHOWER with COMET! Spawning %d meteors!" % count)
	else:
		print("MeteorManager: Meteor shower! Spawning %d meteors." % count)

	meteor_shower_started.emit(count)

	for i in count:
		var delay := i * 0.4
		var spawn_comet_flag := (i == comet_index)

		get_tree().create_timer(delay).timeout.connect(func():
			if spawn_comet_flag:
				spawn_comet()
			else:
				spawn_random_meteor()
		)


func _calculate_trajectory(meteor_type: int) -> Array:
	var viewport := get_tree().root.get_viewport().get_visible_rect()
	var screen_width := viewport.size.x
	var screen_height := viewport.size.y

	var speed: float
	match meteor_type:
		Meteor.MeteorType.SMALL:
			speed = base_meteor_speed * 1.5
		Meteor.MeteorType.MEDIUM:
			speed = base_meteor_speed * 1.2
		Meteor.MeteorType.LARGE:
			speed = base_meteor_speed * 0.9
		Meteor.MeteorType.COMET:
			speed = base_meteor_speed * 1.8
		_:
			speed = base_meteor_speed

	speed *= randf_range(0.8, 1.2)

	var edge := randi_range(0, 3)
	var start_pos: Vector2
	var target_pos: Vector2
	var padding := 100.0

	match edge:
		0:  # Top
			start_pos = Vector2(randf_range(padding, screen_width - padding), -padding)
			target_pos = Vector2(randf_range(padding, screen_width - padding), screen_height + padding)
		1:  # Right
			start_pos = Vector2(screen_width + padding, randf_range(padding, screen_height - padding))
			target_pos = Vector2(-padding, randf_range(padding, screen_height - padding))
		2:  # Bottom
			start_pos = Vector2(randf_range(padding, screen_width - padding), screen_height + padding)
			target_pos = Vector2(randf_range(padding, screen_width - padding), -padding)
		_:  # Left
			start_pos = Vector2(-padding, randf_range(padding, screen_height - padding))
			target_pos = Vector2(screen_width + padding, randf_range(padding, screen_height - padding))

	var direction := (target_pos - start_pos).normalized()
	var velocity := direction * speed

	return [start_pos, velocity]


func _on_meteor_clicked(meteor: Node) -> void:
	total_meteors_clicked += 1

	if meteor.meteor_type == Meteor.MeteorType.COMET:
		total_comets_clicked += 1
		print("MeteorManager: Comet caught! Total comets: %d" % total_comets_clicked)

	_active_meteors.erase(meteor)
	meteor_caught.emit(meteor)


func _on_meteor_expired(meteor: Node) -> void:
	_active_meteors.erase(meteor)
	print("MeteorManager: Meteor expired (missed)")


func debug_spawn_meteor() -> void:
	spawn_random_meteor()


func debug_spawn_comet() -> void:
	spawn_comet()


func debug_meteor_shower() -> void:
	start_meteor_shower()


func get_active_meteor_count() -> int:
	return _active_meteors.size()


func get_save_data() -> Dictionary:
	return {
		"TotalMeteorsSpawned": total_meteors_spawned,
		"TotalMeteorsClicked": total_meteors_clicked,
		"TotalCometsClicked": total_comets_clicked
	}


func load_save_data(data: Dictionary) -> void:
	total_meteors_spawned = data.get("TotalMeteorsSpawned", 0)
	total_meteors_clicked = data.get("TotalMeteorsClicked", 0)
	total_comets_clicked = data.get("TotalCometsClicked", 0)
