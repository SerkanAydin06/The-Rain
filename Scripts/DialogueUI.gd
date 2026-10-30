extends Control

@onready var panel = $Panel
@onready var label = $Panel/Label

var current_timer: SceneTreeTimer = null  # ⭐ Timer yerine SceneTreeTimer
var tween: Tween = null

func _ready():
	hide_dialogue()

func show_dialogue(text: String):
	_clear_timer()
	_clear_tween()
	
	label.text = text
	panel.visible = true
	
	# Fade in efekti
	panel.modulate.a = 0
	tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.3)

func hide_dialogue():
	_clear_timer()
	
	if tween:
		tween.kill()
	
	# Fade out efekti
	if panel.visible:  # ⭐ Sadece görünürse fade yap
		tween = create_tween()
		tween.tween_property(panel, "modulate:a", 0.0, 0.3)
		tween.tween_callback(_final_hide)
	else:
		_final_hide()

func _final_hide():
	panel.visible = false
	label.text = ""

func show_dialogue_for_time(text: String, duration: float = 2.0):
	show_dialogue(text)
	
	current_timer = get_tree().create_timer(duration - 0.3)  # Fade out süresini çıkar
	current_timer.timeout.connect(_on_timer_timeout)

func _on_timer_timeout():
	hide_dialogue()

func _clear_timer():
	if current_timer:
		# SceneTreeTimer'ın disconnect methodu yok, null yap yeterli
		current_timer = null

func _clear_tween():
	if tween:
		tween.kill()
		tween = null
