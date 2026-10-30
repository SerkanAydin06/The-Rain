extends Label

@export var time_manager_path: NodePath
@onready var time_manager := get_node_or_null(time_manager_path)

var current_hour: int = 0
var current_day: int = 1

func _ready() -> void:
	if time_manager:
		time_manager.connect(
			"hour_changed",
			Callable(self, "_on_time_changed")
		)
		current_hour = time_manager.current_hour
		current_day = time_manager.current_day
		_update_text()
	else:
		text = "TimeManager yok"

func _on_time_changed(hour: int, day: int) -> void:
	current_hour = hour
	current_day = day
	_update_text()

func _update_text() -> void:
	var hour_str := str(current_hour).pad_zeros(2)
	var info := ""
	if SurvivalManager.storm_active:
		info += "  |  ⛈️ Fırtına"
	if SurvivalManager.radio_called:
		info += "  |  📡 Kurtarma: %d gün" % max(SurvivalManager.rescue_day - current_day, 0)
	text = "Gün %d  |  %s:00%s" % [current_day, hour_str, info]
