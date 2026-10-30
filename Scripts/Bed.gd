# Bed.gd - Yatak: yorgunken uyuyarak enerji ve can toplar
extends Interactable

@export_range(1, 12, 1) var sleep_hours: int = 8
@export_range(0, 100, 1) var min_energy_to_sleep: int = 80

func get_hint() -> String:
	if _is_tired():
		return "[E] Uyu (%d saat)" % sleep_hours
	return "[E] Yorgun değilsin"

func interact() -> void:
	if not _is_tired():
		show_message("Henüz yorgun değilsin. (Enerji %d%%)\nEnerjin %%%d altına düşünce uyuyabilirsin." % [
			roundi(player_ref.energy), min_energy_to_sleep])
		return
	var player := player_ref
	await player.start_sleep(sleep_hours)
	refresh_hint()

func _is_tired() -> bool:
	return player_ref != null and player_ref.energy < min_energy_to_sleep
