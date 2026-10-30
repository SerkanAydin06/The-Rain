extends CanvasLayer

signal fade_in_completed
signal fade_out_completed

@onready var rect: ColorRect = $ColorRect

func _ready():
	rect.modulate.a = 0.0
	hide()

func fade_in(duration := 1.5):
	show()
	var tween := create_tween()
	tween.tween_property(rect, "modulate:a", 1.0, duration)
	tween.finished.connect(_on_fade_in_finished.bind())

func fade_out(duration := 1.5):
	var tween := create_tween()
	tween.tween_property(rect, "modulate:a", 0.0, duration)
	tween.finished.connect(_on_fade_out_finished.bind())

func _on_fade_in_finished():
	fade_in_completed.emit()

func _on_fade_out_finished():
	fade_out_completed.emit()
	hide()
