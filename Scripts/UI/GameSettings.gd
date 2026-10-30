# GameSettings.gd - Kalıcı oyun ayarları (tam ekran, vsync, ses)
extends Node
# Autoload: "GameSettings"

signal changed

const PATH := "user://settings.cfg"

var fullscreen := false
var vsync := true
var master_volume := 0.8   # 0..1
var show_hints := true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_settings()
	apply()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F11:
		fullscreen = not fullscreen
		apply()
		save_settings()

func apply() -> void:
	if not DisplayServer.get_name() == "headless":
		DisplayServer.window_set_mode(
			DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)
		DisplayServer.window_set_vsync_mode(
			DisplayServer.VSYNC_ENABLED if vsync else DisplayServer.VSYNC_DISABLED)
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_volume_db(bus, linear_to_db(max(master_volume, 0.0001)))
	AudioServer.set_bus_mute(bus, master_volume <= 0.001)
	changed.emit()

func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("video", "fullscreen", fullscreen)
	cfg.set_value("video", "vsync", vsync)
	cfg.set_value("audio", "master", master_volume)
	cfg.set_value("game", "show_hints", show_hints)
	cfg.save(PATH)

func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	fullscreen = cfg.get_value("video", "fullscreen", fullscreen)
	vsync = cfg.get_value("video", "vsync", vsync)
	master_volume = cfg.get_value("audio", "master", master_volume)
	show_hints = cfg.get_value("game", "show_hints", show_hints)
