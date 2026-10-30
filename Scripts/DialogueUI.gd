# DialogueUI.gd - Alt kısımda görünen bildirim/diyalog kutusu
extends Control

@onready var panel: Control = $Panel
@onready var label: Label = $Panel/HBox/Label

var current_timer: SceneTreeTimer = null
var tween: Tween = null

func _ready() -> void:
	panel.visible = false
	panel.modulate.a = 0.0

func show_dialogue(text: String) -> void:
	current_timer = null
	_kill_tween()
	label.text = text
	panel.visible = true
	panel.position.y = panel.position.y  # mevcut konumdan başla
	tween = create_tween().set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)

func hide_dialogue() -> void:
	current_timer = null
	_kill_tween()
	if not panel.visible:
		return
	tween = create_tween()
	tween.tween_property(panel, "modulate:a", 0.0, 0.25)
	tween.tween_callback(func(): panel.visible = false; label.text = "")

func show_dialogue_for_time(text: String, duration: float = 2.0) -> void:
	show_dialogue(text)
	var timer := get_tree().create_timer(max(duration - 0.25, 0.1))
	current_timer = timer
	timer.timeout.connect(func(): if current_timer == timer: hide_dialogue())

func _kill_tween() -> void:
	if tween:
		tween.kill()
		tween = null
