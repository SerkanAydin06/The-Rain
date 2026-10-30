extends Control

@onready var black_bg = $BlackBG
@onready var fade = $Fade
@onready var lbl_time: Label = $Center/Panel/VBox/TimeLabel
@onready var lbl_stats: Label = $Center/Panel/VBox/StatsLabel
@onready var lbl_suit: Label = $Center/Panel/VBox/SuitLabel
@onready var progress: ProgressBar = $Center/Panel/VBox/Progress
@onready var loot_log: RichTextLabel = $Center/Panel/VBox/LootLog

var player: CharacterBody2D
var hours_left := 0
# last_collected: Sadece bu gezide toplananları tutar
var last_collected := {}
# Dışarıda bulunabilecek eşyalar ve ağırlıkları (craft edilen ürünler hariç)
const LOOT_TABLE := {
	"common": ["food", "dirty_water", "wood", "stone", "scrap", "cloth", "plastic"],
	"uncommon": ["water", "battery", "wire", "metal", "chemical", "energy_drink"],
	"rare": ["medkit", "electronic", "fuel", "medicine", "component"],
}
const BLUEPRINT_MIN_DAY := 2
const BLUEPRINT_CHANCE := 0.06

var trip_hours := 0
var hour_index := 0
var risk := 0

func _ready():
	hide()
	black_bg.visible = true
	fade.modulate.a = 1

func start_outside(hours: int) -> void:
	# Her yeni çıkışta gezi envanterini sıfırla
	last_collected.clear()
	
	GameState.game_paused = true # Simülasyon sırasında dünya dursun

	player = get_tree().get_first_node_in_group("player")
	if player == null:
		push_error("PLAYER BULUNAMADI!")
		return

	hours_left = hours
	trip_hours = hours
	hour_index = 0
	risk = SurvivalManager.get_outside_risk(hours)
	loot_log.clear()

	show()
	
	await _fade_out()
	await _run_hours()
	await _fade_in()

	# DİKKAT: Buradaki GameState.game_paused = false satırını sildik.
	# Oyunun devam etmesini ExitPanel'deki "Tamam" butonu yönetecek.
	hide()

func _fade_out():
	var tween = create_tween()
	tween.tween_property(fade, "modulate:a", 0.0, 1.0)
	await tween.finished

func _fade_in():
	var tween = create_tween()
	tween.tween_property(fade, "modulate:a", 1.0, 1.0)
	await tween.finished

func _run_hours():
	
	# GameState'i güncelle
	GameState.is_outside = true
	
	var time_manager = get_tree().get_first_node_in_group("time_manager")
	
	while hours_left > 0:
		_update_ui()
		_simulate_hour()
		hours_left -= 1
		
		# Oyun saatini ilerlet
		if time_manager and time_manager.has_method("force_pass_hour"):
			time_manager.force_pass_hour()
		
		if player.health <= 0:
			break
		
		
		# Godot 4 için doğru timer oluşturma
		# Pause modunda çalışacak şekilde
		var timer = get_tree().create_timer(0.6, true, true, true)
		await timer.timeout
	
	_update_ui()
	
	# Simülasyon bitti, GameState'i güncelle
	GameState.is_outside = false
	
	if player.health <= 0:
		hide()
		GameState.game_paused = false
		SurvivalManager.record_trip(hour_index)
		player.die("outside")
	else:
		SurvivalManager.record_trip(trip_hours)
		GameState.save_game()

func _simulate_hour():
	hour_index += 1
	
	# İstatistik düşüşleri (dışarısı yorucu)
	player.hunger = clamp(player.hunger - 5, 0, 100)
	player.thirst = clamp(player.thirst - 6, 0, 100)
	player.energy = clamp(player.energy - 8, 0, 100)
	if player.hunger <= 0:
		player.health = clamp(player.health - 5, 0, 100)
	if player.thirst <= 0:
		player.health = clamp(player.health - 8, 0, 100)
	
	# Zehirli yağmur giysiyi aşındırır
	var wear := 3 if SurvivalManager.storm_active else 2
	GameState.suit_durability = max(GameState.suit_durability - wear, 0)
	
	# Tehlike: risk yüksek, giysi zayıfsa daha sık yaralanırsın
	var injury_chance := clampf(risk / 100.0 * (1.3 - GameState.suit_durability / 100.0), 0.03, 0.9)
	if randf() < injury_chance:
		var dmg := randi_range(6, 12)
		player.health = clamp(player.health - dmg, 0, 100)
		loot_log.append_text("[color=#e0564d]Yaralandın! -%d Can[/color]\n" % dmg)
	if GameState.suit_durability <= 0:
		player.health = clamp(player.health - 6, 0, 100)
		loot_log.append_text("[color=#e0564d]Giysi delindi, yağmur yakıyor! -6 Can[/color]\n")
	
	player.update_ui()
	
	# Plan (blueprint) şansı
	if GameState.current_day >= BLUEPRINT_MIN_DAY \
			and not "blueprint_radio" in CraftingManager.player_stats["found_blueprints"] \
			and randf() < BLUEPRINT_CHANCE * hour_index:
		CraftingManager.discover_blueprint("blueprint_radio")
		loot_log.append_text("[color=#6fb7c9]📜 Radyo parçası planı buldun![/color]\n")
	
	# Loot: her saat %45 şans, uzun gezilerde nadir eşya ihtimali artar
	if randf() < 0.45:
		var rare_chance := 0.05 + 0.03 * hour_index
		var roll := randf()
		var pool: Array = LOOT_TABLE["common"]
		if roll < rare_chance:
			pool = LOOT_TABLE["rare"]
		elif roll < rare_chance + 0.35:
			pool = LOOT_TABLE["uncommon"]
		var found_item: String = pool[randi() % pool.size()]
		var amount := 1 if pool != LOOT_TABLE["common"] else randi_range(1, 2)
		var item_name := InventoryManager.get_item_display_name(found_item)
		
		# Kalıcı envantere ekle (stack limitine uyar, sinyali gönderir)
		var added: int = GameState.add_to_inventory(found_item, amount)
		if added > 0:
			GameState.total_loot += added
			last_collected[found_item] = last_collected.get(found_item, 0) + added
			loot_log.append_text("Bulundu  [color=#b5d65a]%s (+%d)[/color]\n" % [item_name, added])
		else:
			loot_log.append_text("Bulundu  [color=#5c655f]%s (çanta dolu)[/color]\n" % item_name)

func _update_ui():
	lbl_time.text = "Kalan süre: %d saat" % hours_left if hours_left > 0 else "Sığınağa dönüyorsun..."
	progress.max_value = max(trip_hours, 1)
	progress.value = trip_hours - hours_left
	lbl_stats.text = "Can %d  ·  Açlık %d  ·  Su %d  ·  Enerji %d" % [
		player.health,
		player.hunger,
		player.thirst,
		player.energy
	]
	lbl_suit.text = "Giysi koruması: %d%%  ·  Tehlike: %d%%" % [GameState.suit_durability, risk]
