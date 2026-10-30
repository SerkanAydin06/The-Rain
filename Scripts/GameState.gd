# GameState.gd - YENİ SİSTEM
extends Node

# ==================================================
# SİNYALLER
# ==================================================
signal inventory_changed
signal day_passed(day: int)
signal hour_passed(hour: int, day: int)

# ==================================================
# OYUN DEĞİŞKENLERİ
# ==================================================
var game_paused := false
var is_outside := false
var current_day := 1
var current_hour := 0
# Kayıttan yüklenen oyuncu değerleri (boşsa varsayılanlar kullanılır)
var player_stats := {}
var total_loot := 0
var suit_durability := 100

# ==================================================
# YENİ ENVANTER SİSTEMİ
# ==================================================
var inventory = {
	# ========== TÜKETİLEBİLİRLER (4) ==========
	"food": 5,              # 🥫 Konserve
	"medkit": 1,            # 🩹 Medkit
	"battery": 3,           # 🔋 Pil
	"energy_drink": 2,      # 🥤 Enerji İçeceği
	"water": 4,             # 💧 Temiz Su
	"dirty_water": 0,       # 🟤 Kirli Su
	
	# ========== TEMEL MALZEMELER (4) ==========
	"wood": 10,             # 🪵 Ahşap
	"stone": 8,             # 🪨 Taş
	"scrap": 15,            # 🔩 Hurda
	"cloth": 6,             # 🧵 Kumaş
	
	# ========== ORTA MALZEMELER (4) ==========
	"wire": 4,              # 🔌 Tel
	"plastic": 3,           # 🥤 Plastik
	"metal": 2,             # ⚙️ Metal
	"chemical": 1,          # 🧪 Kimyasal
	
	# ========== NADİR MALZEMELER (4) ==========
	"electronic": 0,        # 💻 Elektronik
	"fuel": 0,              # ⛽ Yakıt
	"medicine": 0,          # 💊 İlaç
	"component": 0,         # ⚡ Parça
	
	# ========== CRAFT EDİLMİŞ ÜRÜNLER (4) ==========
	"medkit_crafted": 0,    # 🩹 Yapay Medkit
	"battery_crafted": 0,   # 🔋 Şarj Edilebilir Pil
	"toolkit": 0,           # 🧰 Alet Çantası
	"radio_part": 0,        # 📡 Radyo Parçası
}

# ==================================================
# STACK LİMİTLERİ
# ==================================================
var stack_limits = {
	# Tüketilebilirler
	"food": 20,
	"medkit": 5,
	"battery": 15,
	"energy_drink": 10,
	"water": 20,
	"dirty_water": 20,
	
	# Temel malzemeler
	"wood": 50,
	"stone": 50,
	"scrap": 100,
	"cloth": 40,
	
	# Orta malzemeler
	"wire": 40,
	"plastic": 30,
	"metal": 25,
	"chemical": 20,
	
	# Nadir malzemeler
	"electronic": 15,
	"fuel": 10,
	"medicine": 10,
	"component": 5,
	
	# Craft edilmiş
	"medkit_crafted": 3,
	"battery_crafted": 5,
	"toolkit": 2,
	"radio_part": 3,
}

# ==================================================
# KAYDET/YÜKLE (GÜNCELLENMİŞ)
# ==================================================
func save_game() -> void:
	var save_data = {
		"current_day": current_day,
		"current_hour": current_hour,
		"total_loot": total_loot,
		"suit_durability": suit_durability,
		"inventory": inventory,
		"player_stats": _collect_player_stats(),
		"survival": SurvivalManager.get_save_data(),
		"crafting": CraftingManager.get_save_data()
	}
	
	var file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
	else:
		push_error("❌ Kayıt dosyası açılamadı")

func load_game() -> bool:
	if not FileAccess.file_exists("user://savegame.save"):
		return false
	
	var file = FileAccess.open("user://savegame.save", FileAccess.READ)
	if not file:
		push_error("❌ Kayıt dosyası açılamadı")
		return false
	
	var json = JSON.new()
	var error = json.parse(file.get_as_text())
	file.close()
	
	if error != OK:
		push_error("❌ JSON parse hatası: ", json.get_error_message())
		return false
	
	var save_data = json.get_data()
	current_day = int(save_data.get("current_day", 1))
	current_hour = int(save_data.get("current_hour", 0))
	player_stats = save_data.get("player_stats", {})
	SurvivalManager.load_save_data(save_data.get("survival", {}))
	CraftingManager.load_save_data(save_data.get("crafting", {}))
	total_loot = save_data.get("total_loot", 0)
	suit_durability = save_data.get("suit_durability", 100)
	
	# Envanteri yükle (eski kayıtlarla uyumlu)
	if save_data.has("inventory"):
		var old_inventory = save_data["inventory"]
		# Yeni item'ları ekle, eski item'ları koru
		for key in inventory.keys():
			if old_inventory.has(key):
				inventory[key] = int(old_inventory[key])
	
	return true

# ==================================================
# YENİ FONKSİYONLAR
# ==================================================
func _collect_player_stats() -> Dictionary:
	var player = get_tree().get_first_node_in_group("player")
	if player == null or not "health" in player:
		return player_stats
	return {"health": player.health, "hunger": player.hunger,
		"energy": player.energy, "thirst": player.thirst}

func reset_game() -> void:
	game_paused = false
	is_outside = false
	current_day = 1
	current_hour = 0
	player_stats = {}
	total_loot = 0
	suit_durability = 100
	
	# Envanteri sıfırla
	inventory = {
		"food": 5,
		"medkit": 1,
		"battery": 3,
		"energy_drink": 2,
		"water": 4,
		"dirty_water": 0,
		"wood": 10,
		"stone": 8,
		"scrap": 15,
		"cloth": 6,
		"wire": 4,
		"plastic": 3,
		"metal": 2,
		"chemical": 1,
		"electronic": 0,
		"fuel": 0,
		"medicine": 0,
		"component": 0,
		"medkit_crafted": 0,
		"battery_crafted": 0,
		"toolkit": 0,
		"radio_part": 0,
	}
	
	SurvivalManager.reset()
	CraftingManager.reset()

func add_to_inventory(item: String, amount: int = 1) -> int:
	if not inventory.has(item):
		push_warning("⚠️ Bilinmeyen item: ", item)
		return 0
	
	var current = inventory.get(item, 0)
	var limit = stack_limits.get(item, 99)
	var new_amount = min(current + amount, limit)
	
	inventory[item] = new_amount
	inventory_changed.emit()
	
	return new_amount - current

func remove_from_inventory(item: String, amount: int = 1) -> bool:
	if not inventory.has(item):
		return false
	
	var current = inventory.get(item, 0)
	if current < amount:
		return false
	
	inventory[item] = current - amount
	inventory_changed.emit()
	
	return true

func get_item_count(item: String) -> int:
	return inventory.get(item, 0)

func has_item(item: String, amount: int = 1) -> bool:
	return inventory.get(item, 0) >= amount
