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
	print("📦 InventoryManager hazır")
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
	
	print("📦 Gösterilecek item'lar: ", displayed_items.size())

func _on_inventory_changed() -> void:
	_initialize_displayed_items()
	inventory_updated.emit()

# PUBLIC API
func get_displayed_items() -> Array:
	return displayed_items

func get_item_amount(item_id: String) -> int:
	return GameState.inventory.get(item_id, 0)

func use_item(item_id: String) -> bool:
	if GameState.inventory.get(item_id, 0) > 0:
		GameState.inventory[item_id] -= 1
		item_used.emit(item_id)
		return true
	return false

func get_item_display_name(item_id: String) -> String:
	match item_id:
		"food": return "🍖 Yiyecek"
		"battery": return "🔋 Pil"
		"medkit": return "🩹 Medkit"
		"scrap": return "🔩 Parça"
		"wood": return "🪵 Tahta"
		"cloth": return "🧵 Kumaş"
		"water": return "💧 Su"
		"plastic": return "🥤 Plastik"
		"metal": return "⚙️ Metal"
		"chemical": return "🧪 Kimyasal"
		"circuit": return "💻 Devre"
		_: return "📦 " + item_id.capitalize()
