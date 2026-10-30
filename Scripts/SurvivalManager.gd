# SurvivalManager.gd - Hayatta kalma döngüsü (gece/pil, günlük olaylar, telsiz ve kurtarılma)
extends Node
# Autoload: "SurvivalManager"

signal radio_state_changed
signal rescue_arrived

# ==================================================
# AYARLAR
# ==================================================
const RADIO_PARTS_REQUIRED := 3
const RESCUE_DELAY_DAYS := 3
const NIGHT_START := 20
const NIGHT_END := 6
const RAIN_COLLECTOR_YIELD := 2

# ==================================================
# DURUM
# ==================================================
var radio_parts_installed := 0
var radio_called := false
var rescue_day := -1
var rain_collector_built := false
var lamp_lit := true          # Bu gece pil yakıldı mı?
var storm_active := false     # Fırtına: dışarısı daha tehlikeli
var hours_outside_total := 0
var longest_outside := 0
var game_won := false

var _pending_messages: Array[String] = []

func _ready() -> void:
	GameState.hour_passed.connect(_on_hour_passed)
	GameState.day_passed.connect(_on_day_passed)

func _process(_delta: float) -> void:
	if _pending_messages.is_empty():
		return
	var player = get_tree().get_first_node_in_group("player")
	if player == null or player.is_sleeping or GameState.is_outside or player.ui_blocked:
		return
	var dialogue = get_tree().get_first_node_in_group("dialogue_ui")
	if dialogue and dialogue.has_method("show_dialogue_for_time"):
		dialogue.show_dialogue_for_time(_pending_messages.pop_front(), 4.0)

# ==================================================
# PUBLIC API
# ==================================================
func notify(text: String) -> void:
	_pending_messages.append(text)

func is_night(hour: int) -> bool:
	return hour >= NIGHT_START or hour < NIGHT_END

func is_dark() -> bool:
	return is_night(GameState.current_hour) and not lamp_lit

func get_outside_risk(hours: int) -> int:
	"""Dışarı çıkış tehlikesi (%). Günler geçtikçe yağmur sertleşir."""
	var risk := 15 + (hours - 1) * 8 + (GameState.current_day - 1) * 2
	if storm_active:
		risk += 15
	return clampi(risk, 5, 95)

func record_trip(hours: int) -> void:
	hours_outside_total += hours
	longest_outside = max(longest_outside, hours)

func get_stats() -> Dictionary:
	return {
		"days_survived": GameState.current_day,
		"total_loot": GameState.total_loot,
		"longest_outside": longest_outside,
		"total_hours_outside": hours_outside_total,
	}

# ==================================================
# TELSİZ
# ==================================================
func radio_status_text() -> String:
	if game_won:
		return "Kurtarma ekibi geldi."
	if radio_called:
		var left: int = max(rescue_day - GameState.current_day, 0)
		return "Telsiz: 'Sinyalini aldık. Dayan, %d gün içinde oradayız.'" % left
	if radio_parts_installed >= RADIO_PARTS_REQUIRED:
		return "Telsiz onarıldı ama çağrı için 1 pil gerekiyor."
	return "Telsiz bozuk. Onarım: %d/%d radyo parçası.\nRadyo parçası planı dışarıda bulunabilir." % [
		radio_parts_installed, RADIO_PARTS_REQUIRED]

func objective_text() -> String:
	"""HUD hedef satırı"""
	if game_won:
		return "Kurtarıldın!"
	if radio_called:
		return "Kurtarma ekibini bekle: %d gün" % max(rescue_day - GameState.current_day, 0)
	if radio_parts_installed >= RADIO_PARTS_REQUIRED:
		return "Telsizden yardım çağır (1 pil gerekir)"
	var have := GameState.get_item_count("radio_part")
	var text := "Telsizi onar: %d/%d parça takıldı" % [radio_parts_installed, RADIO_PARTS_REQUIRED]
	if have > 0:
		text += "\nÇantanda %d parça var, telsize götür" % have
	elif not "blueprint_radio" in CraftingManager.player_stats["found_blueprints"]:
		text += "\nDışarıda radyo parçası planını ara"
	else:
		text += "\nTezgahta radyo parçası üret (Tier 3)"
	return text

func use_radio() -> String:
	"""Telsizle etkileşim: parça tak, onarıldıysa yardım çağır."""
	if game_won or radio_called:
		return radio_status_text()

	if radio_parts_installed < RADIO_PARTS_REQUIRED:
		var have := GameState.get_item_count("radio_part")
		var need := RADIO_PARTS_REQUIRED - radio_parts_installed
		var install: int = min(have, need)
		if install > 0:
			GameState.remove_from_inventory("radio_part", install)
			radio_parts_installed += install
			radio_state_changed.emit()
		if radio_parts_installed < RADIO_PARTS_REQUIRED:
			return radio_status_text()

	if not GameState.remove_from_inventory("battery"):
		return radio_status_text()

	radio_called = true
	rescue_day = GameState.current_day + RESCUE_DELAY_DAYS
	radio_state_changed.emit()
	GameState.save_game()
	return "Telsiz cızırdıyor...\n'Seni duyuyoruz! %d gün dayan, geliyoruz.'" % RESCUE_DELAY_DAYS

# ==================================================
# SAAT / GÜN OLAYLARI
# ==================================================
func _on_hour_passed(hour: int, _day: int) -> void:
	if hour == NIGHT_START:
		# Gece lambası için pil harca
		lamp_lit = GameState.remove_from_inventory("battery")
		if not lamp_lit and not GameState.is_outside:
			notify("Pil kalmadı, sığınak karanlıkta.\nKaranlıkta enerjin daha hızlı düşer.")
	elif hour == NIGHT_END:
		lamp_lit = true

func _on_day_passed(day: int) -> void:
	if rain_collector_built:
		var added := GameState.add_to_inventory("dirty_water", RAIN_COLLECTOR_YIELD)
		if added > 0:
			notify("Yağmur toplayıcı doldu: +%d kirli su" % added)

	if radio_called and day >= rescue_day and not game_won:
		game_won = true
		_delete_save()
		rescue_arrived.emit()
		return

	storm_active = false
	_roll_daily_event()

func _roll_daily_event() -> void:
	var roll := randf()
	if roll < 0.15:
		storm_active = true
		notify("Fırtına yaklaşıyor! Bugün dışarısı çok daha tehlikeli.")
	elif roll < 0.27:
		if GameState.has_item("toolkit"):
			notify("Çatı sızdırdı ama alet çantanla hemen tamir ettin.")
		else:
			var player = get_tree().get_first_node_in_group("player")
			if player:
				player.health = clampf(player.health - 10.0, 0.0, 100.0)
				player.update_ui()
			notify("Çatıdan zehirli yağmur sızdı! -10 Can\n(Alet çantası bunu önler.)")
	elif roll < 0.39:
		var lost: int = min(GameState.get_item_count("food"), randi_range(1, 2))
		if lost > 0:
			GameState.remove_from_inventory("food", lost)
			notify("Fareler erzağa girmiş! -%d yiyecek" % lost)
	elif roll < 0.49:
		var finds := ["scrap", "cloth", "wire", "plastic", "chemical"]
		var item: String = finds[randi() % finds.size()]
		if GameState.add_to_inventory(item, 2) > 0:
			notify("Sığınağın köşesinde unutulmuş malzeme buldun: +2 %s" % InventoryManager.get_item_display_name(item))

func _delete_save() -> void:
	if FileAccess.file_exists("user://savegame.save"):
		DirAccess.remove_absolute("user://savegame.save")

# ==================================================
# KAYIT
# ==================================================
func get_save_data() -> Dictionary:
	return {
		"radio_parts_installed": radio_parts_installed,
		"radio_called": radio_called,
		"rescue_day": rescue_day,
		"rain_collector_built": rain_collector_built,
		"lamp_lit": lamp_lit,
		"storm_active": storm_active,
		"hours_outside_total": hours_outside_total,
		"longest_outside": longest_outside,
	}

func load_save_data(data: Dictionary) -> void:
	radio_parts_installed = int(data.get("radio_parts_installed", 0))
	radio_called = bool(data.get("radio_called", false))
	rescue_day = int(data.get("rescue_day", -1))
	rain_collector_built = bool(data.get("rain_collector_built", false))
	lamp_lit = bool(data.get("lamp_lit", true))
	storm_active = bool(data.get("storm_active", false))
	hours_outside_total = int(data.get("hours_outside_total", 0))
	longest_outside = int(data.get("longest_outside", 0))
	game_won = false

func reset() -> void:
	load_save_data({})
	_pending_messages.clear()
