extends Node

signal hour_changed(hour: int, day: int)

@export var seconds_per_hour := 5.0
@export_range(0.1, 200.0, 0.1)
var time_speed := 1.0

var current_hour := 0
var current_day := 1
var _timer := 0.0

func _ready() -> void:
	current_day = GameState.current_day
	current_hour = GameState.current_hour
	hour_changed.emit(current_hour, current_day)

func _process(delta: float) -> void:
	if GameState.game_paused:
		return

	_timer += delta * time_speed

	if _timer >= seconds_per_hour:
		_timer -= seconds_per_hour
		_pass_hour()

func _pass_hour() -> void:
	current_hour += 1
	if current_hour >= 24:
		current_hour = 0
		current_day += 1
		GameState.current_day = current_day  # GameState'i güncelle
		GameState.day_passed.emit(current_day)

	GameState.current_hour = current_hour
	hour_changed.emit(current_hour, current_day)

func force_pass_hour() -> void:
	print_debug("Zorunlu saat geçişi yapılıyor...")
	_pass_hour()
	print_debug("Saat geçişi tamamlandı: Saat ", current_hour, ", Gün ", current_day)
	
func pause_time():
	GameState.game_paused = true  # GameState'i güncelle

func resume_time():
	GameState.game_paused = false  # GameState'i güncelle

# Geriye dönük uyumluluk
var day:
	get: return current_day

var hour:
	get: return current_hour
