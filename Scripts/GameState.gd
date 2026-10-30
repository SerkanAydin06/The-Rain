# GameState.gd - YENİ SİSTEM
extends Node

# ==================================================
# SİNYALLER
# ==================================================
signal inventory_changed
signal day_passed(day: int)

# ==================================================
# OYUN DEĞİŞKENLERİ
# ==================================================
var game_paused := false
var is_outside := false
var current_day := 1
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
	"radio_part": 1,
}

# ==================================================
# KAYDET/YÜKLE (GÜNCELLENMİŞ)
# ==================================================
func save_game() -> void:
	var save_data = {
		"current_day": current_day,
		"total_loot": total_loot,
		"suit_durability": suit_durability,
		"inventory": inventory
	}
	
	var file = FileAccess.open("user://savegame.save", FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))
		file.close()
		print("✅ Oyun kaydedildi!")
	else:
		push_error("❌ Kayıt dosyası açılamadı")

func load_game() -> bool:
	if not FileAccess.file_exists("user://savegame.save"):
		print("ℹ️ Kayıt dosyası yok")
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
	current_day = save_data.get("current_day", 1)
	total_loot = save_data.get("total_loot", 0)
	suit_durability = save_data.get("suit_durability", 100)
	
	# Envanteri yükle (eski kayıtlarla uyumlu)
	if save_data.has("inventory"):
		var old_inventory = save_data["inventory"]
		# Yeni item'ları ekle, eski item'ları koru
		for key in inventory.keys():
			if old_inventory.has(key):
				inventory[key] = old_inventory[key]
	
	print("✅ Oyun yüklendi!")
	return true

# ==================================================
# YENİ FONKSİYONLAR
# ==================================================
func reset_game() -> void:
	game_paused = false
	is_outside = false
	current_day = 1
	total_loot = 0
	suit_durability = 100
	
	# Envanteri sıfırla
	inventory = {
		"food": 5,
		"medkit": 1,
		"battery": 3,
		"energy_drink": 2,
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
	
	print("🔄 Oyun durumu sıfırlandı!")

func add_to_inventory(item: String, amount: int = 1) -> void:
	if not inventory.has(item):
		push_warning("⚠️ Bilinmeyen item: ", item)
		return
	
	var current = inventory.get(item, 0)
	var limit = stack_limits.get(item, 99)
	var new_amount = min(current + amount, limit)
	
	inventory[item] = new_amount
	inventory_changed.emit()
	
	print("📦 Envantere eklendi: ", item, " ×", amount, " (Toplam: ", new_amount, ")")

func remove_from_inventory(item: String, amount: int = 1) -> bool:
	if not inventory.has(item):
		return false
	
	var current = inventory.get(item, 0)
	if current < amount:
		return false
	
	inventory[item] = current - amount
	inventory_changed.emit()
	
	print("📦 Envanterden çıkarıldı: ", item, " ×", amount)
	return true

func get_item_count(item: String) -> int:
	return inventory.get(item, 0)

func has_item(item: String, amount: int = 1) -> bool:
	return inventory.get(item, 0) >= amount

# ==================================================
# DEBUG FONKSİYONLARI
# ==================================================
func debug_print_inventory() -> void:
	print("\n=== ENVANTER DURUMU ===")
	print("🥫 TÜKETİLEBİLİRLER:")
	print("  food:", inventory["food"])
	print("  medkit:", inventory["medkit"])
	print("  battery:", inventory["battery"])
	print("  energy_drink:", inventory["energy_drink"])
	
	print("🛠️ MALZEMELER:")
	print("  Basit:", inventory["wood"], "wood,", inventory["stone"], "stone,", 
		  inventory["scrap"], "scrap,", inventory["cloth"], "cloth")
	print("  Orta:", inventory["wire"], "wire,", inventory["plastic"], "plastic,",
		  inventory["metal"], "metal,", inventory["chemical"], "chemical")
	print("  Nadir:", inventory["electronic"], "electronic,", inventory["fuel"], "fuel,",
		  inventory["medicine"], "medicine,", inventory["component"], "component")
	
	print("⚒️ CRAFT EDİLMİŞ:")
	print("  medkit_crafted:", inventory["medkit_crafted"])
	print("  battery_crafted:", inventory["battery_crafted"])
	print("  toolkit:", inventory["toolkit"])
	print("  radio_part:", inventory["radio_part"])
	print("========================\n")

func debug_add_all_items() -> void:
	print("🔧 DEBUG: Tüm item'lar ekleniyor...")
	
	for item in inventory.keys():
		var limit = stack_limits.get(item, 10)
		inventory[item] = limit
	
	inventory_changed.emit()
	debug_print_inventory()
