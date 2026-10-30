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
		_update_text()
	else:
		text = "TimeManager yok"

func _on_time_changed(hour: int, day: int) -> void:
	current_hour = hour
	current_day = day
	_update_text()

func _update_text() -> void:
	var hour_str := str(current_hour).pad_zeros(2)
	text = "Day %d  |  %s:00" % [current_day, hour_str]
