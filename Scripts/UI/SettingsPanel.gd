# SettingsPanel.gd - Ana menü ve duraklatma menüsünde ortak ayarlar ekranı
extends Control

signal closed

@onready var fullscreen_check: CheckButton = $Center/Card/VBox/FullscreenCheck
@onready var vsync_check: CheckButton = $Center/Card/VBox/VsyncCheck
@onready var hints_check: CheckButton = $Center/Card/VBox/HintsCheck
@onready var volume_slider: HSlider = $Center/Card/VBox/VolumeRow/VolumeSlider
@onready var volume_value: Label = $Center/Card/VBox/VolumeRow/VolumeValue
@onready var close_btn: Button = $Center/Card/VBox/Footer/CloseBtn

func _ready() -> void:
	hide()
	fullscreen_check.toggled.connect(func(on): GameSettings.fullscreen = on; _apply())
	vsync_check.toggled.connect(func(on): GameSettings.vsync = on; _apply())
	hints_check.toggled.connect(func(on): GameSettings.show_hints = on; _apply())
	volume_slider.value_changed.connect(_on_volume_changed)
	close_btn.pressed.connect(close)

func open() -> void:
	fullscreen_check.set_pressed_no_signal(GameSettings.fullscreen)
	vsync_check.set_pressed_no_signal(GameSettings.vsync)
	hints_check.set_pressed_no_signal(GameSettings.show_hints)
	volume_slider.set_value_no_signal(GameSettings.master_volume)
	volume_value.text = "%d%%" % roundi(GameSettings.master_volume * 100)
	show()
	close_btn.grab_focus()

func close() -> void:
	GameSettings.save_settings()
	hide()
	closed.emit()

func _on_volume_changed(value: float) -> void:
	GameSettings.master_volume = value
	volume_value.text = "%d%%" % roundi(value * 100)
	_apply()

func _apply() -> void:
	GameSettings.apply()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		close()
