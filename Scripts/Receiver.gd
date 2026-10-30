# Receiver.gd - Telsiz: parça takılır, onarılınca yardım çağrılır
extends Interactable

func get_hint() -> String:
	if SurvivalManager.radio_called:
		return "[E] Telsizi dinle"
	if SurvivalManager.radio_parts_installed >= SurvivalManager.RADIO_PARTS_REQUIRED:
		return "[E] Yardım çağır"
	if GameState.get_item_count("radio_part") > 0:
		return "[E] Radyo parçası tak"
	return "[E] Telsiz"

func interact() -> void:
	show_message(SurvivalManager.use_radio(), 4.0)
	refresh_hint()
