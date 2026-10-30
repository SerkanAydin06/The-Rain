# InventoryManager.gd - Sadeleştirilmiş versiyon
extends Node
# Autoload: "InventoryManager"

# SIGNALS
signal inventory_updated
signal item_used(item_id: String)

# CONFIG
const MAX_ITEMS_DISPLAY = 8  # Sağda gösterilecek max item sayısı

# DATA
var displayed_items = []  # Gösterilecek item'ların listesi

func _ready() -> void:
	GameState.inventory_changed.connect(_on_inventory_changed)
	_initialize_displayed_items()

func _initialize_displayed_items() -> void:
	displayed_items.clear()
	
	# GameState'ten sadece miktarı > 0 olan item'ları al
	for item_id in GameState.inventory:
		var amount = GameState.inventory[item_id]
		if amount > 0:
			displayed_items.append({"id": item_id, "amount": amount})
	
	# Alfabetik sırala
	displayed_items.sort_custom(func(a, b): return a.id < b.id)
	

func _on_inventory_changed() -> void:
	_initialize_displayed_items()
	inventory_updated.emit()

# PUBLIC API
func get_displayed_items() -> Array:
	return displayed_items

func get_item_amount(item_id: String) -> int:
	return GameState.inventory.get(item_id, 0)

func use_item(item_id: String) -> bool:
	if GameState.remove_from_inventory(item_id):
		item_used.emit(item_id)
		return true
	return false

# Eşya bilgileri: id -> [isim, emoji, ikon yolu]
const ITEMS := {
	"food": ["Konserve", "🥫", "res://Assets/Icons/foodicon.png"],
	"water": ["Temiz Su", "💧", ""],
	"dirty_water": ["Kirli Su", "🟤", ""],
	"medkit": ["Medkit", "🩹", "res://Assets/Icons/medkiticon.png"],
	"battery": ["Pil", "🔋", "res://Assets/Icons/batteryicon.png"],
	"energy_drink": ["Enerji İçeceği", "🥤", ""],
	"wood": ["Tahta", "🪵", "res://Assets/Icons/woodicon.png"],
	"stone": ["Taş", "🪨", ""],
	"scrap": ["Hurda", "🔩", "res://Assets/Icons/scrapicon.png"],
	"cloth": ["Kumaş", "🧵", "res://Assets/Icons/clothicon.png"],
	"wire": ["Tel", "🔌", ""],
	"plastic": ["Plastik", "♻️", ""],
	"metal": ["Metal", "⚙️", ""],
	"chemical": ["Kimyasal", "🧪", ""],
	"electronic": ["Elektronik", "💻", ""],
	"fuel": ["Yakıt", "⛽", ""],
	"medicine": ["İlaç", "💊", ""],
	"component": ["Bileşen", "⚡", ""],
	"medkit_crafted": ["Yapay Medkit", "🩹", ""],
	"battery_crafted": ["Şarjlı Pil", "🔋", ""],
	"toolkit": ["Alet Çantası", "🧰", ""],
	"radio_part": ["Radyo Parçası", "📡", ""],
}

func get_item_name(item_id: String) -> String:
	return ITEMS[item_id][0] if ITEMS.has(item_id) else item_id.capitalize()

func get_item_emoji(item_id: String) -> String:
	return ITEMS[item_id][1] if ITEMS.has(item_id) else "📦"

func get_item_icon(item_id: String) -> Texture2D:
	if ITEMS.has(item_id) and not ITEMS[item_id][2].is_empty():
		return load(ITEMS[item_id][2])
	return null

func get_item_display_name(item_id: String) -> String:
	return get_item_emoji(item_id) + " " + get_item_name(item_id)
