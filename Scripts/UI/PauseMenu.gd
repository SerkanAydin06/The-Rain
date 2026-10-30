# PauseMenu.gd - ESC ile açılan duraklatma menüsü
extends CanvasLayer

@onready var root: Control = $Root
@onready var info: Label = $Root/Menu/Info
@onready var toast: Label = $Root/Menu/Toast
@onready var resume_btn: Button = $Root/Menu/ResumeBtn
@onready var save_btn: Button = $Root/Menu/SaveBtn
@onready var settings_btn: Button = $Root/Menu/SettingsBtn
@onready var menu_btn: Button = $Root/Menu/MenuBtn
@onready var quit_btn: Button = $Root/Menu/QuitBtn
@onready var settings_panel: Control = $Root/SettingsPanel
@onready var confirm: Control = $Root/Confirm
@onready var confirm_no: Button = $Root/Confirm/Center/Card/VBox/Footer/NoBtn
@onready var confirm_save_yes: Button = $Root/Confirm/Center/Card/VBox/Footer/SaveYesBtn
@onready var confirm_yes: Button = $Root/Confirm/Center/Card/VBox/Footer/YesBtn

var _pending_action := ""   # "menu" | "quit"
var _was_paused := false

func _ready() -> void:
	root.hide()
	resume_btn.pressed.connect(close)
	save_btn.pressed.connect(_on_save)
	settings_btn.pressed.connect(func(): settings_panel.open())
	settings_panel.closed.connect(func(): settings_btn.grab_focus())
	menu_btn.pressed.connect(_ask.bind("menu"))
	quit_btn.pressed.connect(_ask.bind("quit"))
	confirm_no.pressed.connect(func(): confirm.hide(); resume_btn.grab_focus())
	confirm_save_yes.pressed.connect(func(): GameState.save_game(); _do_pending())
	confirm_yes.pressed.connect(_do_pending)

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("ui_cancel"):
		return
	if root.visible:
		get_viewport().set_input_as_handled()
		if settings_panel.visible:
			settings_panel.close()
		elif confirm.visible:
			confirm.hide()
			resume_btn.grab_focus()
		else:
			close()
	elif _can_open():
		get_viewport().set_input_as_handled()
		open()

func _can_open() -> bool:
	var player = get_tree().get_first_node_in_group("player")
	if player == null:
		return false
	return not (player.is_dead or player.is_sleeping or player.ui_blocked or GameState.is_outside)

func open() -> void:
	_was_paused = GameState.game_paused
	GameState.game_paused = true
	get_tree().paused = true
	info.text = "Gün %d  ·  %02d:00" % [GameState.current_day, GameState.current_hour]
	toast.text = ""
	confirm.hide()
	root.show()
	root.modulate.a = 0.0
	create_tween().tween_property(root, "modulate:a", 1.0, 0.15)
	resume_btn.grab_focus()

func close() -> void:
	root.hide()
	get_tree().paused = false
	GameState.game_paused = _was_paused

func _on_save() -> void:
	GameState.save_game()
	toast.text = "Oyun kaydedildi."
	toast.add_theme_color_override("font_color", UIPalette.ACCENT)

func _ask(action: String) -> void:
	_pending_action = action
	confirm_save_yes.text = "KAYDET VE ÇIK"
	confirm.show()
	confirm_no.grab_focus()

func _do_pending() -> void:
	get_tree().paused = false
	GameState.game_paused = false
	if _pending_action == "quit":
		get_tree().quit()
	else:
		get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
