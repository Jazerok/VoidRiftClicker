extends Node

## SaveManager - Handles saving and loading game progress

signal game_saved()
signal game_loaded()
signal save_error(error_message: String)

const SAVE_PATH := "user://savegame.json"
const BACKUP_PATH := "user://savegame_backup.json"
const AUTOSAVE_INTERVAL := 30.0
const SAVE_VERSION := 1

var _autosave_timer: float = 0.0
var _is_saving: bool = false
var has_unsaved_changes: bool = false


func _ready() -> void:
	load_game()
	get_tree().auto_accept_quit = false
	pass


func _process(delta: float) -> void:
	_autosave_timer += delta
	if _autosave_timer >= AUTOSAVE_INTERVAL:
		_autosave_timer = 0
		save_game(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		pass
		save_game(false)
		get_tree().quit()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("save_game"):
		save_game(false)
		pass


func save_game(is_autosave: bool = false) -> bool:
	if _is_saving:
		pass
		return false

	_is_saving = true

	var game_data := GameManager.get_save_data()
	if game_data.is_empty():
		push_error("SaveManager: GameManager not ready, cannot save")
		_is_saving = false
		return false

	var save_data := {
		"version": SAVE_VERSION,
		"timestamp": int(Time.get_unix_time_from_system()),
		"game_data": game_data
	}

	if UpgradeManager:
		save_data["upgrade_data"] = UpgradeManager.get_save_data()

	if AchievementManager:
		save_data["achievement_data"] = AchievementManager.get_save_data()

	var json_string := JSON.stringify(save_data, "\t")

	# Create backup
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.copy_absolute(ProjectSettings.globalize_path(SAVE_PATH), ProjectSettings.globalize_path(BACKUP_PATH))

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		var error := FileAccess.get_open_error()
		push_error("SaveManager: Could not open save file: %s" % error)
		save_error.emit("Could not open save file: %s" % error)
		_is_saving = false
		return false

	file.store_string(json_string)
	file.close()

	has_unsaved_changes = false

	if not is_autosave:
		pass

	game_saved.emit()
	_is_saving = false
	return true


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		pass
		return true

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		var error := FileAccess.get_open_error()
		push_error("SaveManager: Could not open save file: %s" % error)
		return _try_load_backup()

	var json_string := file.get_as_text()
	file.close()

	var json := JSON.new()
	var parse_result := json.parse(json_string)
	if parse_result != OK:
		push_error("SaveManager: JSON parse error: %s" % json.get_error_message())
		return _try_load_backup()

	var save_data: Dictionary = json.data

	var save_version := int(save_data.get("version", 1))
	if save_version != SAVE_VERSION:
		pass
		save_data = _migrate_save_data(save_data, save_version)

	var game_data: Dictionary = save_data.get("game_data", {})
	GameManager.load_save_data(game_data)

	if save_data.has("upgrade_data") and UpgradeManager:
		var upgrade_data: Dictionary = save_data["upgrade_data"]
		UpgradeManager.load_save_data(upgrade_data)

	if save_data.has("achievement_data") and AchievementManager:
		var achievement_data: Dictionary = save_data["achievement_data"]
		AchievementManager.load_save_data(achievement_data)

	GameManager.calculate_offline_progress()

	call_deferred("_sync_ability_hotbar")

	pass
	game_loaded.emit()

	has_unsaved_changes = false
	return true


func _try_load_backup() -> bool:
	if not FileAccess.file_exists(BACKUP_PATH):
		push_error("SaveManager: No backup available, starting fresh")
		save_error.emit("Save file corrupted and no backup available")
		return false

	pass
	DirAccess.copy_absolute(ProjectSettings.globalize_path(BACKUP_PATH), ProjectSettings.globalize_path(SAVE_PATH))
	return load_game()


func _migrate_save_data(save_data: Dictionary, from_version: int) -> Dictionary:
	save_data["version"] = SAVE_VERSION
	return save_data


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
		pass

	if FileAccess.file_exists(BACKUP_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(BACKUP_PATH))
		pass


func save_exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func get_save_directory() -> String:
	return ProjectSettings.globalize_path("user://")


func mark_unsaved_changes() -> void:
	has_unsaved_changes = true


func _sync_ability_hotbar() -> void:
	var hotbar := get_tree().root.find_child("AbilityHotbar", true, false)
	if hotbar and hotbar.has_method("sync_with_upgrades"):
		hotbar.sync_with_upgrades()
		pass
