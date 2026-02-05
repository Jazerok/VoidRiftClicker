extends Node

## AudioManager - Handles all game audio (music and sound effects)

const SFX_PATH := "res://Assets/Audio/SFX/"
const MUSIC_PATH := "res://Assets/Audio/Music/"
const SFX_POOL_SIZE := 8

var _music_volume: float = 0.7
var _sfx_volume: float = 1.0
var music_enabled: bool = true
var sfx_enabled: bool = true
var is_muted: bool = false

var _music_player: AudioStreamPlayer
var _music_player2: AudioStreamPlayer
var _sfx_pool: Array[AudioStreamPlayer] = []
var _next_sfx_index: int = 0
var _audio_cache: Dictionary = {}
var _current_music_track: String = ""


func _ready() -> void:
	# Create music players
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	_music_player.volume_db = linear_to_db(_music_volume)
	add_child(_music_player)

	_music_player2 = AudioStreamPlayer.new()
	_music_player2.bus = "Master"
	add_child(_music_player2)

	# Create SFX player pool
	for i in SFX_POOL_SIZE:
		var sfx_player := AudioStreamPlayer.new()
		sfx_player.bus = "Master"
		add_child(sfx_player)
		_sfx_pool.append(sfx_player)

	_update_music_volume()
	_update_sfx_volume()

	# Set master volume to 10% on startup
	var master_idx := AudioServer.get_bus_index("Master")
	if master_idx < 0:
		master_idx = 0
	AudioServer.set_bus_volume_db(master_idx, linear_to_db(0.1))

	print("AudioManager: Initialized with SFX pool of %d, Master volume at 10%%" % SFX_POOL_SIZE)


# SFX Playback

func play_sfx(sfx_name: String, volume_scale: float = 1.0) -> void:
	if not sfx_enabled or is_muted:
		return

	var stream := _get_or_load_audio(SFX_PATH + sfx_name)
	if stream == null:
		return

	var player := _sfx_pool[_next_sfx_index]
	_next_sfx_index = (_next_sfx_index + 1) % SFX_POOL_SIZE

	player.stream = stream
	player.volume_db = linear_to_db(_sfx_volume * volume_scale)
	player.play()


func play_click_sfx() -> void:
	if not sfx_enabled:
		return

	var player := _sfx_pool[_next_sfx_index]
	player.pitch_scale = 0.95 + randf_range(0, 0.1)
	play_sfx("click", 0.8)
	player.pitch_scale = 1.0


func play_purchase_sfx() -> void:
	play_sfx("purchase")


func play_achievement_sfx() -> void:
	play_sfx("achievement", 1.2)


func play_prestige_sfx() -> void:
	play_sfx("prestige", 1.0)


func play_error_sfx() -> void:
	play_sfx("error", 0.7)


func play_meteor_spawn_sfx() -> void:
	var player := _sfx_pool[_next_sfx_index]
	player.pitch_scale = 0.9 + randf_range(0, 0.2)
	play_sfx("meteor_whoosh", 0.5)
	player.pitch_scale = 1.0


func play_meteor_explode_sfx() -> void:
	var player := _sfx_pool[_next_sfx_index]
	player.pitch_scale = 0.85 + randf_range(0, 0.3)
	play_sfx("meteor_explode", 0.7)
	player.pitch_scale = 1.0


func play_comet_explode_sfx() -> void:
	play_sfx("comet_explode", 1.0)


func play_cosmic_surge_sfx() -> void:
	play_sfx("cosmic_surge", 0.8)


func play_surge_boost_sfx() -> void:
	var player := _sfx_pool[_next_sfx_index]
	player.pitch_scale = 1.0 + randf_range(0, 0.3)
	play_sfx("surge_boost", 0.6)
	player.pitch_scale = 1.0


func play_upgrade_sfx() -> void:
	play_sfx("upgrade", 0.8)


func toggle_mute() -> void:
	is_muted = not is_muted

	var master_idx := AudioServer.get_bus_index("Master")
	if master_idx < 0:
		master_idx = 0

	AudioServer.set_bus_mute(master_idx, is_muted)

	if is_muted and _music_player.playing:
		_music_player.stream_paused = true
	elif not is_muted:
		_music_player.stream_paused = false

	print("Audio muted: %s" % is_muted)


func set_muted(muted: bool) -> void:
	if is_muted != muted:
		toggle_mute()


func start_ambient_music() -> void:
	play_music("Stage_1", 2.0)


# Music Playback

func play_music(music_name: String, fade_time: float = 1.0) -> void:
	if not music_enabled:
		return

	if _current_music_track == music_name and _music_player.playing:
		return

	var stream := _get_or_load_audio(MUSIC_PATH + music_name)
	if stream == null:
		return

	# Enable looping
	if stream is AudioStreamMP3:
		stream.loop = true
	elif stream is AudioStreamOggVorbis:
		stream.loop = true
	elif stream is AudioStreamWAV:
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = -1

	_current_music_track = music_name

	if fade_time > 0 and _music_player.playing:
		_crossfade_music(stream, fade_time)
	else:
		_music_player.stream = stream
		_music_player.volume_db = linear_to_db(_music_volume)
		_music_player.play()


func stop_music(fade_time: float = 1.0) -> void:
	if fade_time > 0:
		var tween := create_tween()
		tween.tween_property(_music_player, "volume_db", -80.0, fade_time)
		tween.tween_callback(_music_player.stop)
	else:
		_music_player.stop()

	_current_music_track = ""


func _crossfade_music(new_stream: AudioStream, fade_time: float) -> void:
	var old_player := _music_player
	var new_player := _music_player2

	new_player.stream = new_stream
	new_player.volume_db = -80
	new_player.play()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(old_player, "volume_db", -80.0, fade_time)
	tween.tween_property(new_player, "volume_db", linear_to_db(_music_volume), fade_time)
	tween.chain().tween_callback(old_player.stop)

	_music_player = new_player
	_music_player2 = old_player


# Volume Control

func set_music_volume(volume: float) -> void:
	_music_volume = clampf(volume, 0.0, 1.0)
	_update_music_volume()
	if SaveManager:
		SaveManager.mark_unsaved_changes()


func get_music_volume() -> float:
	return _music_volume


func set_sfx_volume(volume: float) -> void:
	_sfx_volume = clampf(volume, 0.0, 1.0)
	_update_sfx_volume()
	if SaveManager:
		SaveManager.mark_unsaved_changes()


func get_sfx_volume() -> float:
	return _sfx_volume


func toggle_music() -> void:
	music_enabled = not music_enabled
	if not music_enabled:
		stop_music(0.5)
	if SaveManager:
		SaveManager.mark_unsaved_changes()


func toggle_sfx() -> void:
	sfx_enabled = not sfx_enabled
	if SaveManager:
		SaveManager.mark_unsaved_changes()


func _update_music_volume() -> void:
	if _music_player and _music_player.playing:
		_music_player.volume_db = linear_to_db(_music_volume)


func _update_sfx_volume() -> void:
	pass  # Volume is applied per-play


# Audio Loading

func _get_or_load_audio(base_path: String) -> AudioStream:
	if _audio_cache.has(base_path):
		return _audio_cache[base_path]

	var extensions: Array[String] = [".ogg", ".wav", ".mp3"]

	for ext in extensions:
		var full_path: String = base_path + ext
		if ResourceLoader.exists(full_path):
			var stream := load(full_path) as AudioStream
			if stream:
				_audio_cache[base_path] = stream
				return stream

	# Generate procedural audio as fallback
	var procedural_stream := _generate_procedural_sound(base_path)
	if procedural_stream:
		_audio_cache[base_path] = procedural_stream
		return procedural_stream

	return null


func _generate_procedural_sound(base_path: String) -> AudioStream:
	var sfx_name := base_path.get_file()

	match sfx_name:
		"click":
			return _generate_tone(800, 0.08, 0.8, true)
		"meteor_whoosh":
			return _generate_noise(0.15, 0.5, true, 2000, 500)
		"meteor_explode":
			return _generate_explosion(0.25, 0.9)
		"comet_explode":
			return _generate_explosion(0.4, 1.0, true)
		"cosmic_surge":
			return _generate_rising_tone(300, 800, 0.5, 0.8)
		"surge_boost":
			return _generate_tone(1200, 0.1, 0.7, true)
		"upgrade":
			return _generate_chime(0.35, 0.8)
		"purchase":
			return _generate_chime(0.3, 0.7)
		"achievement":
			return _generate_fanfare(0.6, 0.9)
		"prestige":
			return _generate_rising_tone(200, 1000, 1.0, 0.8)
		"error":
			return _generate_tone(200, 0.2, 0.6, true, true)

	return null


func _generate_tone(frequency: float, duration: float, volume: float, fade_out: bool, is_square: bool = false) -> AudioStreamWAV:
	var sample_rate := 44100
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)

	for i in num_samples:
		var t := float(i) / sample_rate
		var sample: float
		if is_square:
			sample = 1.0 if sin(2 * PI * frequency * t) > 0 else -1.0
		else:
			sample = sin(2 * PI * frequency * t)

		var envelope := volume
		if fade_out:
			envelope *= 1.0 - float(i) / num_samples

		var value := int(sample * envelope * 32767)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


func _generate_noise(duration: float, volume: float, fade_out: bool, start_freq: float, end_freq: float) -> AudioStreamWAV:
	var sample_rate := 44100
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	var last_sample := 0.0

	for i in num_samples:
		var progress := float(i) / num_samples
		var cutoff := lerpf(start_freq, end_freq, progress) / sample_rate

		var noise := randf_range(-1, 1)
		var filtered := last_sample + cutoff * (noise - last_sample)
		last_sample = filtered

		var envelope := volume
		if fade_out:
			envelope *= 1.0 - progress

		var value := int(filtered * envelope * 32767)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


func _generate_explosion(duration: float, volume: float, shimmer: bool = false) -> AudioStreamWAV:
	var sample_rate := 44100
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	var last_sample := 0.0

	for i in num_samples:
		var progress := float(i) / num_samples

		var cutoff := lerpf(0.8, 0.05, progress)
		var noise := randf_range(-1, 1)
		var filtered := last_sample + cutoff * (noise - last_sample)
		last_sample = filtered

		var sample := filtered
		if shimmer:
			var shimmer_tone := sin(2 * PI * (800 - 400 * progress) * i / sample_rate)
			sample = filtered * 0.7 + shimmer_tone * 0.3 * (1.0 - progress)

		var envelope := volume * pow(1.0 - progress, 0.5)
		if i < sample_rate * 0.01:
			envelope *= i / (sample_rate * 0.01)

		var value := int(sample * envelope * 32767)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


func _generate_rising_tone(start_freq: float, end_freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate := 44100
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)
	var phase := 0.0

	for i in num_samples:
		var progress := float(i) / num_samples
		var frequency := lerpf(start_freq, end_freq, progress * progress)

		phase += 2 * PI * frequency / sample_rate
		var sample := sin(phase)
		sample = sample * 0.6 + sin(phase * 2) * 0.25 + sin(phase * 3) * 0.15

		var envelope := volume
		if progress < 0.1:
			envelope *= progress / 0.1
		if progress > 0.7:
			envelope *= 1.0 - (progress - 0.7) / 0.3

		var value := int(sample * envelope * 32767)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


func _generate_chime(duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate := 44100
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)

	var frequencies: Array[float] = [523.25, 659.25, 783.99]

	for i in num_samples:
		var t := float(i) / sample_rate
		var sample := 0.0

		for n in frequencies.size():
			var note_delay: float = n * 0.03
			if t > note_delay:
				var note_t: float = t - note_delay
				var note_env := exp(-note_t * 8)
				sample += sin(2 * PI * frequencies[n] * note_t) * note_env / frequencies.size()

		var value := int(sample * volume * 32767)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


func _generate_fanfare(duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate := 44100
	var num_samples := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(num_samples * 2)

	var frequencies: Array[float] = [392.0, 523.25, 659.25, 783.99]
	var delays: Array[float] = [0.0, 0.08, 0.16, 0.24]

	for i in num_samples:
		var t := float(i) / sample_rate
		var sample := 0.0

		for n in frequencies.size():
			if t > delays[n]:
				var note_t: float = t - delays[n]
				var note_env := exp(-note_t * 4)
				var note := sin(2 * PI * frequencies[n] * note_t) * 0.7
				note += sin(4 * PI * frequencies[n] * note_t) * 0.2
				note += sin(6 * PI * frequencies[n] * note_t) * 0.1
				sample += note * note_env / frequencies.size()

		var value := int(sample * volume * 32767)
		data[i * 2] = value & 0xFF
		data[i * 2 + 1] = (value >> 8) & 0xFF

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


func preload_audio(names: Array, path: String) -> void:
	for sfx_name in names:
		_get_or_load_audio(path + sfx_name)


func preload_common_sfx() -> void:
	preload_audio(["click", "purchase", "achievement", "prestige", "error", "hover"], SFX_PATH)


# Save/Load

func get_save_data() -> Dictionary:
	return {
		"music_volume": _music_volume,
		"sfx_volume": _sfx_volume,
		"music_enabled": music_enabled,
		"sfx_enabled": sfx_enabled
	}


func load_save_data(data: Dictionary) -> void:
	_music_volume = data.get("music_volume", 0.7)
	_sfx_volume = data.get("sfx_volume", 1.0)
	music_enabled = data.get("music_enabled", true)
	sfx_enabled = data.get("sfx_enabled", true)

	_update_music_volume()
	_update_sfx_volume()
