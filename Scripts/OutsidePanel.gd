extends Control

@onready var black_bg = $BlackBG
@onready var fade = $Fade
@onready var lbl_time = $Panel/MarginContainer/VBoxContainer/TimeLabel
@onready var lbl_stats = $Panel/MarginContainer/VBoxContainer/StatsLabel
@onready var lbl_suit = $Panel/MarginContainer/VBoxContainer/SuitLabel
@onready var loot_log = $Panel/MarginContainer/VBoxContainer/LootLog

var player: CharacterBody2D
var hours_left := 0
# last_collected: Sadece bu gezide toplananları tutar
var last_collected := {}
# Dışarıda bulunabilecek eşyalar (craft edilen ürünler hariç)
const LOOT_POOL := [
	"food", "medkit", "battery", "energy_drink",
	"wood", "stone", "scrap", "cloth",
	"wire", "plastic", "metal", "chemical",
	"electronic", "fuel", "medicine", "component",
]

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
	loot_log.clear()

	show()
	self.z_index = 10
	
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
	print_debug("Dışarı çıkış simülasyonu başlıyor: ", hours_left, " saat")
	
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
		
		print_debug("Simülasyon - Kalan: ", hours_left, " saat")
		print_debug("  - Player HP: ", player.health)
		print_debug("  - Açlık: ", player.hunger)
		print_debug("  - Enerji: ", player.energy)
		
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
		player.die()
	else:
		GameState.save_game()
	print_debug("Dışarı çıkış simülasyonu tamamlandı")

func _simulate_hour():
	# İstatistik düşüşleri
	player.hunger = clamp(player.hunger - 5, 0, 100)
	player.energy = clamp(player.energy - 8, 0, 100)
	if player.hunger <= 0:
		player.health = clamp(player.health - 5, 0, 100)
	
	var old_suit = GameState.suit_durability
	GameState.suit_durability = max(GameState.suit_durability - 1, 0)
	print_debug("Suit azaldı: ", old_suit, " -> ", GameState.suit_durability)
	
	# HUD'u hemen güncelle
	player.update_ui()
	
	# Risk kontrolü
	var risk_roll = randi_range(0, 100)
	print_debug("Risk kontrolü - Zar: ", risk_roll, " vs Suit: ", GameState.suit_durability)
	
	if risk_roll > GameState.suit_durability:
		player.health = clamp(player.health - 5, 0, 100)
		loot_log.append_text("[color=red]Yaralandın![/color]\n")
		print_debug("Yaralandı! HP: ", player.health)

	# Loot Mekaniği
	var loot_chance = randi_range(0, 100)
	if loot_chance > 70: # %30 ihtimal
		var found_item: String = LOOT_POOL[randi() % LOOT_POOL.size()]
		
		# Kalıcı envantere ekle (stack limitine uyar, sinyali gönderir)
		var added: int = GameState.add_to_inventory(found_item, 1)
		if added > 0:
			GameState.total_loot += added
			last_collected[found_item] = last_collected.get(found_item, 0) + added
			loot_log.append_text("Bulunan: [color=yellow]%s (+1)[/color]\n" % found_item)
		else:
			loot_log.append_text("Bulunan: [color=gray]%s (çanta dolu)[/color]\n" % found_item)

func _update_ui():
	lbl_time.text = "Kalan Süre: %d saat" % hours_left
	lbl_stats.text = "HP: %d | Açlık: %d | Enerji: %d" % [
		player.health,
		player.hunger,
		player.energy
	]
	lbl_suit.text = "Suit Koruması: %% %d" % GameState.suit_durability
