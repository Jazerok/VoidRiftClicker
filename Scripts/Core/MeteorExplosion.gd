class_name MeteorExplosion
extends Control

## Impressive explosion effect when meteor is clicked

var _glow_color: Color
var _core_color: Color
var _size: float
var _is_comet: bool
var _timer: float = 0.0
var _duration: float = 1.2

# Debris particles
var _debris: Array[Dictionary] = []

# Sparkles
var _sparkles: Array[Dictionary] = []


func initialize(glow_color: Color, core_color: Color, size: float, is_comet: bool) -> void:
	_glow_color = glow_color
	_core_color = core_color
	_size = size
	_is_comet = is_comet
	_duration = 1.5 if is_comet else 1.0
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Create debris particles
	var debris_count := 20 if is_comet else 12
	for i in debris_count:
		var angle := randf_range(0, PI * 2)
		var speed := randf_range(150, 400) * (1.5 if is_comet else 1.0)
		_debris.append({
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"size": randf_range(size * 0.1, size * 0.4),
			"rotation": randf_range(0, PI * 2),
			"rot_speed": randf_range(-10, 10),
			"col": glow_color if randf() > 0.5 else core_color
		})

	# Create sparkles
	var sparkle_count := 30 if is_comet else 15
	for i in sparkle_count:
		var angle := randf_range(0, PI * 2)
		var speed := randf_range(80, 250)
		var life := randf_range(0.3, 0.8)
		_sparkles.append({
			"pos": Vector2.ZERO,
			"vel": Vector2(cos(angle), sin(angle)) * speed,
			"life": life,
			"max_life": life,
			"col": Color.WHITE
		})

	custom_minimum_size = Vector2(size * 10, size * 10)


func _process(delta: float) -> void:
	_timer += delta

	if _timer >= _duration:
		queue_free()
		return

	# Update debris
	for d in _debris:
		d.pos += d.vel * delta
		d.vel *= 0.96
		d.rotation += d.rot_speed * delta
		d.size *= 0.98

	# Update sparkles
	for s in _sparkles:
		s.pos += s.vel * delta
		s.vel *= 0.92
		s.life -= delta

	queue_redraw()


func _draw() -> void:
	var progress := _timer / _duration
	var alpha := 1 - pow(progress, 0.5)

	var center := Vector2(_size * 5, _size * 5)

	# Initial bright flash
	if _timer < 0.15:
		var flash_progress := _timer / 0.15
		var flash_size := _size * (2 + flash_progress * 4)
		var flash_alpha := (1 - flash_progress) * 0.9

		draw_circle(center, flash_size * 0.3, Color(1, 1, 1, flash_alpha))
		draw_circle(center, flash_size * 0.6, Color(_core_color.r, _core_color.g, _core_color.b, flash_alpha * 0.7))
		draw_circle(center, flash_size, Color(_glow_color.r, _glow_color.g, _glow_color.b, flash_alpha * 0.4))

	# Expanding shockwave rings
	for ring in 4:
		var ring_delay := ring * 0.08
		var ring_progress := clampf((_timer - ring_delay) / (_duration * 0.6), 0, 1)

		if ring_progress > 0 and ring_progress < 1:
			var ring_size := _size * (1 + ring_progress * 6)
			var ring_alpha := sin(ring_progress * PI) * 0.8
			var ring_width := lerpf(6.0, 1.0, ring_progress)

			var ring_color := _glow_color if ring % 2 == 0 else _core_color
			ring_color.a = ring_alpha

			draw_arc(center, ring_size, 0, PI * 2, 48, ring_color, ring_width)

			var glow_ring := ring_color
			glow_ring.a = ring_alpha * 0.3
			draw_arc(center, ring_size + 4, 0, PI * 2, 48, glow_ring, ring_width + 4)

	# Draw debris chunks
	for d in _debris:
		if d.size < 1:
			continue

		var debris_pos: Vector2 = center + d.pos
		var debris_col: Color = d.col
		debris_col.a = alpha

		var points: PackedVector2Array = []
		for i in 4:
			var angle: float = d.rotation + i * PI * 0.5
			var dist: float = d.size * (1.0 if i % 2 == 0 else 0.6)
			points.append(debris_pos + Vector2(cos(angle), sin(angle)) * dist)

		draw_polygon(points, [debris_col, debris_col, debris_col, debris_col])

		var debris_glow := debris_col
		debris_glow.a = alpha * 0.4
		draw_circle(debris_pos, d.size * 1.5, debris_glow)

	# Draw sparkles
	for s in _sparkles:
		if s.life <= 0:
			continue

		var sparkle_pos: Vector2 = center + s.pos
		var sparkle_alpha: float = s.life / s.max_life
		var sparkle_size := 3 + sparkle_alpha * 4

		var sparkle_col: Color = s.col
		sparkle_col.a = sparkle_alpha

		draw_line(sparkle_pos - Vector2(sparkle_size, 0), sparkle_pos + Vector2(sparkle_size, 0), sparkle_col, 2)
		draw_line(sparkle_pos - Vector2(0, sparkle_size), sparkle_pos + Vector2(0, sparkle_size), sparkle_col, 2)

		var sparkle_glow := Color(0.5, 0.9, 1, sparkle_alpha * 0.5) if _is_comet else Color(1, 0.8, 0.4, sparkle_alpha * 0.5)
		draw_circle(sparkle_pos, sparkle_size * 0.8, sparkle_glow)

	# Center residual glow
	if progress < 0.7:
		var glow_alpha := (1 - progress / 0.7) * 0.6
		var glow_size := _size * (1 + progress * 2)

		var center_glow := _glow_color
		center_glow.a = glow_alpha * 0.3
		draw_circle(center, glow_size * 2, center_glow)

		center_glow.a = glow_alpha * 0.5
		draw_circle(center, glow_size, center_glow)

		var core_glow := _core_color
		core_glow.a = glow_alpha * 0.7
		draw_circle(center, glow_size * 0.5, core_glow)

	# Center flash
	var flash_color := Color(1, 1, 1, alpha * 0.8)
	draw_circle(center, _size * (1 - progress * 0.5), flash_color)
