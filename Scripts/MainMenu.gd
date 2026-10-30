# MainMenu.gd - Ana menü
extends CanvasLayer

const SAVE_PATH := "user://savegame.save"
const GAME_SCENE := "res://Scenes/Main.tscn"

@onready var root_control: Control = $Control
@onready var background: TextureRect = $Control/Background
@onready var content: VBoxContainer = $Control/Content
@onready var title_label: Label = $Control/Content/TitleLabel
@onready var buttons_vbox: VBoxContainer = $Control/Content/ButtonsVBox
@onready var continue_btn: Button = $Control/Content/ButtonsVBox/ContinueBtn
@onready var new_game_btn: Button = $Control/Content/ButtonsVBox/NewGameBtn
@onready var settings_btn: Button = $Control/Content/ButtonsVBox/SettingsBtn
@onready var quit_btn: Button = $Control/Content/ButtonsVBox/QuitBtn
@onready var save_info: Label = $Control/Content/SaveInfo
@onready var version_label: Label = $Control/VersionLabel
@onready var confirm: Control = $Control/Confirm
@onready var confirm_yes: Button = $Control/Confirm/Center/Card/VBox/Footer/YesBtn
@onready var confirm_no: Button = $Control/Confirm/Center/Card/VBox/Footer/NoBtn
@onready var settings_panel: Control = $Control/SettingsPanel
@onready var fade: ColorRect = $Control/Fade

var _busy := false

func _ready() -> void:
	get_tree().paused = false
	version_label.text = "v%s" % ProjectSettings.get_setting("application/config/version", "1.1")

	continue_btn.pressed.connect(_on_continue_pressed)
	new_game_btn.pressed.connect(_on_new_game_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	confirm_yes.pressed.connect(_start_new_game)
	confirm_no.pressed.connect(func(): confirm.hide(); new_game_btn.grab_focus())
	settings_panel.closed.connect(func(): settings_btn.grab_focus())

	_refresh_save_state()
	_play_intro()
	_lightning_loop()

func _refresh_save_state() -> void:
	var has_save := FileAccess.file_exists(SAVE_PATH)
	continue_btn.visible = has_save
	save_info.text = ""
	if has_save:
		var info := _read_save_summary()
		if not info.is_empty():
			save_info.text = info
	(continue_btn if has_save else new_game_btn).grab_focus()

func _read_save_summary() -> String:
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return ""
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return ""
	var day := int(data.get("current_day", 1))
	var hour := int(data.get("current_hour", 0))
	return "Kayıt: Gün %d · %02d:00" % [day, hour]

# ==================================================
# ANİMASYONLAR
# ==================================================
func _play_intro() -> void:
	fade.color.a = 1.0
	content.modulate.a = 0.0
	content.position.x -= 30
	var tw := create_tween().set_parallel(true)
	tw.tween_property(fade, "color:a", 0.0, 1.2)
	tw.tween_property(content, "modulate:a", 1.0, 0.9).set_delay(0.3)
	tw.tween_property(content, "position:x", content.position.x + 30, 0.9).set_delay(0.3)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func _lightning_loop() -> void:
	# Arada bir şimşek çakması
	while is_inside_tree():
		await get_tree().create_timer(randf_range(6.0, 14.0)).timeout
		if not is_inside_tree():
			return
		var mat := background.material as ShaderMaterial
		var tw := create_tween()
		tw.tween_method(func(v): mat.set_shader_parameter("flash", v), 0.0, 0.35, 0.05)
		tw.tween_method(func(v): mat.set_shader_parameter("flash", v), 0.35, 0.0, 0.12)
		tw.tween_method(func(v): mat.set_shader_parameter("flash", v), 0.0, 0.2, 0.05)
		tw.tween_method(func(v): mat.set_shader_parameter("flash", v), 0.2, 0.0, 0.5)

# ==================================================
# BUTONLAR
# ==================================================
func _on_continue_pressed() -> void:
	if _busy:
		return
	if GameState.load_game():
		GameState.game_paused = false
		_transition_to_game()
	else:
		save_info.text = "Kayıt okunamadı."
		continue_btn.hide()
		new_game_btn.grab_focus()

func _on_new_game_pressed() -> void:
	if _busy:
		return
	if FileAccess.file_exists(SAVE_PATH):
		confirm.show()
		confirm_no.grab_focus()
	else:
		_start_new_game()

func _start_new_game() -> void:
	confirm.hide()
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
	GameState.reset_game()
	_transition_to_game()

func _on_settings_pressed() -> void:
	settings_panel.open()

func _on_quit_pressed() -> void:
	if _busy:
		return
	_busy = true
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.5)
	await tw.finished
	get_tree().quit()

func _transition_to_game() -> void:
	_busy = true
	var tw := create_tween()
	tw.tween_property(fade, "color:a", 1.0, 0.7)
	await tw.finished
	get_tree().change_scene_to_file(GAME_SCENE)

func _unhandled_input(event: InputEvent) -> void:
	if confirm.visible and event.is_action_pressed("ui_cancel"):
		confirm.hide()
		new_game_btn.grab_focus()
		get_viewport().set_input_as_handled()
