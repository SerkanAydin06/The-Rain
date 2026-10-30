extends Node2D

# ==================================================
# CONFIGURATION
# ==================================================
@export_category("Food Settings")
@export_range(10, 100, 1) var hunger_restore: int = 35
@export_range(5, 50, 1) var energy_restore: int = 10

@export_category("UI References")
@export var dialogue_ui_path: NodePath

# ==================================================
# UI REFERENCES
# ==================================================
@onready var dialogue_ui = get_node_or_null(dialogue_ui_path)

# ==================================================
# STATE VARIABLES
# ==================================================
var player_ref: CharacterBody2D = null
var player_inside: bool = false
var is_interaction_cooldown: bool = false

# ==================================================
# CONSTANTS
# ==================================================
const INTERACTION_COOLDOWN: float = 0.5  # seconds

# ==================================================
# LIFECYCLE
# ==================================================
func _ready() -> void:
	_validate_dialogue_ui()
	_connect_game_state_signals()

func _process(_delta: float) -> void:
	_handle_interaction_input()

# ==================================================
# VALIDATION & SETUP
# ==================================================
func _validate_dialogue_ui() -> void:
	"""DialogueUI referansını kontrol et"""
	if not dialogue_ui:
		dialogue_ui = get_tree().get_first_node_in_group("dialogue_ui")
		if dialogue_ui:
			print("✅ FoodShelf: DialogueUI grup üzerinden bulundu")

func _connect_game_state_signals() -> void:
	"""GameState sinyallerini bağla"""
	if GameState and not GameState.inventory_changed.is_connected(_on_inventory_changed):
		GameState.inventory_changed.connect(_on_inventory_changed)

# ==================================================
# INPUT HANDLING
# ==================================================
func _handle_interaction_input() -> void:
	if not player_inside:
		return
	
	if not Input.is_action_just_pressed("interact"):
		return
	
	if is_interaction_cooldown:
		return
	
	if not player_ref:
		return
	
	if _is_player_unable_to_interact():
		print("⚠️ FoodShelf: Player etkileşemez durumda")
		return
	
	_on_interact()

func _is_player_unable_to_interact() -> bool:
	"""Oyuncunun etkileşim yapamayacağı durumları kontrol et"""
	if not player_ref:
		return true
	
	# Player property kontrolleri - DÜZELTİLMİŞ
	if "is_dead" in player_ref and player_ref.is_dead:
		return true
	
	if "is_unconscious" in player_ref and player_ref.is_unconscious:
		return true
	
	if "ui_blocked" in player_ref and player_ref.ui_blocked:
		return true
	
	return false

# ==================================================
# INTERACTION LOGIC
# ==================================================
func _on_interact() -> void:
	print("🍽️ FoodShelf: _on_interact() BAŞLADI")
	
	# Cooldown başlat
	is_interaction_cooldown = true
	
	# Yemek kontrolü
	var food_count = GameState.inventory.get("food", 0)
	print("   - Envanterdeki yemek: ", food_count)
	
	if food_count <= 0:
		print("   ❌ Yemek yok!")
		_show_empty_shelf_message()
		_reset_cooldown()
		return
	
	# ⭐⭐ DÜZELTME: Player'ın aç olup olmadığını KONTROL ET
	var player_can_eat = true
	
	if player_ref and player_ref.has_method("needs_food"):
		player_can_eat = player_ref.needs_food()
		print("   - Player.needs_food(): ", player_can_eat)
	elif "hunger" in player_ref:
		# Fallback: Eğer needs_food() yoksa, direkt hunger kontrol et
		player_can_eat = player_ref.hunger < 90
		print("   - Player hunger: ", player_ref.hunger, " can_eat: ", player_can_eat)
	
	if not player_can_eat:
		print("   ❌ Player aç değil veya yiyemez")
		_show_not_hungry_message()
		_reset_cooldown()
		return
	
	print("   ✅ Yemek yeme koşulları sağlandı")
	_consume_food()
	
	# Cooldown sıfırla
	await get_tree().create_timer(INTERACTION_COOLDOWN).timeout
	is_interaction_cooldown = false
	print("🍽️ FoodShelf: _on_interact() TAMAMLANDI")

func _show_not_hungry_message() -> void:
	var message = "Aç değilsin...\nŞu an yemek yemene gerek yok."
	
	# Player'ın açlık durumunu da ekle
	if player_ref and "hunger" in player_ref:
		message += "\nAçlık: " + str(player_ref.hunger) + "%"
	
	_show_dialogue_message(message, 2.0)
	_update_interaction_hud()

func _consume_food() -> void:
	print("🍔 FoodShelf: _consume_food() BAŞLADI")
	
	# 1. Envanterden azalt
	var old_food = GameState.inventory.get("food", 0)
	if old_food > 0:
		GameState.inventory["food"] = old_food - 1
		print("   - Yemek azaltıldı: ", old_food, " → ", GameState.inventory["food"])
	else:
		print("   ❌ Yemek azaltılamadı!")
		return
	
	# 2. Player stats güncelle - DÜZELTİLMİŞ
	_update_player_stats()
	
	# 3. UI'leri güncelle
	if player_ref and player_ref.has_method("update_ui"):
		player_ref.update_ui()
		print("   - Player.update_ui() çağrıldı")
	
	# 4. Sinyal gönder
	GameState.inventory_changed.emit()
	print("   - inventory_changed sinyali gönderildi")
	
	# 5. HUD'u güncelle
	_update_interaction_hud()
	
	# 6. Mesaj göster
	_show_consumption_message()
	
	print("🍔 FoodShelf: _consume_food() TAMAMLANDI")

func _update_player_stats() -> void:
	"""Oyuncu istatistiklerini güncelle - DÜZELTİLMİŞ"""
	print("📊 FoodShelf: _update_player_stats() BAŞLADI")
	
	if not player_ref:
		print("   ❌ player_ref yok")
		return
	
	# ⭐⭐ DÜZELTME: Eğer property yoksa, set et
	if not "hunger" in player_ref:
		print("   ⚠️ Player'da hunger property yok, ekleniyor...")
		player_ref.set("hunger", 100.0)
	
	if not "energy" in player_ref:
		print("   ⚠️ Player'da energy property yok, ekleniyor...")
		player_ref.set("energy", 100.0)
	
	# Açlık güncelle
	var old_hunger = player_ref.hunger
	player_ref.hunger = clampf(
		player_ref.hunger + hunger_restore,
		0.0,
		100.0
	)
	print("   - Açlık güncellendi: ", old_hunger, " → ", player_ref.hunger)
	
	# Enerji güncelle
	var old_energy = player_ref.energy
	player_ref.energy = clampf(
		player_ref.energy + energy_restore,
		0.0,
		100.0
	)
	print("   - Enerji güncellendi: ", old_energy, " → ", player_ref.energy)
	
	print("📊 FoodShelf: _update_player_stats() TAMAMLANDI")

# ==================================================
# UI FEEDBACK
# ==================================================
func _show_empty_shelf_message() -> void:
	"""Boş raf mesajı göster"""
	var message = "Raflar boş..."
	_show_dialogue_message(message, 2.0)

func _show_consumption_message() -> void:
	"""Yemek yeme mesajı göster"""
	var remaining_food = GameState.inventory.get("food", 0)
	var message = "🍽️ Yemek yedin!\n"
	message += "Açlık: +" + str(hunger_restore) + "%\n"
	message += "Enerji: +" + str(energy_restore) + "%\n"
	message += "Kalan yemek: " + str(remaining_food)
	
	# Player'ın yeni değerlerini de göster
	if player_ref and "hunger" in player_ref and "energy" in player_ref:
		message += "\n\nYeni durum:\n"
		message += "Açlık: " + str(player_ref.hunger) + "%\n"
		message += "Enerji: " + str(player_ref.energy) + "%"
	
	_show_dialogue_message(message, 3.0)

func _show_dialogue_message(text: String, duration: float = 2.0) -> void:
	"""Diyalog mesajı göster"""
	if not dialogue_ui:
		print("💬 FoodShelf: ", text)
		return
	
	if dialogue_ui.has_method("show_dialogue_for_time"):
		dialogue_ui.show_dialogue_for_time(text, duration)
	elif dialogue_ui.has_method("show_dialogue"):
		dialogue_ui.show_dialogue(text)
		await get_tree().create_timer(duration).timeout
		if dialogue_ui.has_method("hide_dialogue"):
			dialogue_ui.hide_dialogue()
	else:
		print("💬 FoodShelf: ", text)

func _update_interaction_hud() -> void:
	"""InteractionHUD'u güncelle"""
	var hud = get_node_or_null("/root/InteractionHUD")
	if not hud or not player_inside:
		return
	
	var food_count = GameState.inventory.get("food", 0)
	
	# Açlık durumuna göre hint göster
	var hint_text = ""
	
	if food_count <= 0:
		hint_text = "[E] Boş"
	else:
		# Player'ın aç olup olmadığını kontrol et
		var is_hungry = false
		
		if player_ref:
			if player_ref.has_method("needs_food"):
				is_hungry = player_ref.needs_food()
			elif "hunger" in player_ref:
				is_hungry = player_ref.hunger < 90
		
		if is_hungry:
			hint_text = "[E] Ye (" + str(food_count) + " kaldı)"
		else:
			hint_text = "[E] Aç değilsin"
	
	hud.show_hint(hint_text)

# ==================================================
# SIGNAL HANDLERS
# ==================================================
func _on_inventory_changed() -> void:
	"""Envanter değiştiğinde UI'yi güncelle"""
	if player_inside:
		_update_interaction_hud()

# ==================================================
# AREA HANDLERS
# ==================================================
func _on_area_2d_body_entered(body: Node2D) -> void:
	print("🚶 FoodShelf: Body entered: ", body.name if body else "null")
	
	if not body or not body.is_in_group("player"):
		print("   ❌ Body player değil veya null")
		return
	
	player_inside = true
	player_ref = body
	
	print("   ✅ Player içerde")
	var player_status = "✅" if player_ref else "❌"
	print("   - Player ref: ", player_status)
	print("   - Player has energy: ", "✅" if "energy" in player_ref else "❌")
	
	_update_interaction_hud()

func _on_area_2d_body_exited(body: Node2D) -> void:
	"""Oyuncu alandan çıktığında"""
	if not body or not body.is_in_group("player"):
		return
	
	print("🚶 FoodShelf: Body exited: ", body.name)
	
	player_inside = false
	player_ref = null
	
	# InteractionHUD'u gizle
	var hud = get_node_or_null("/root/InteractionHUD")
	if hud:
		hud.hide_hint()

# ==================================================
# HELPER FUNCTIONS
# ==================================================
func _reset_cooldown() -> void:
	"""Etkileşim cooldown'ını sıfırla"""
	await get_tree().create_timer(INTERACTION_COOLDOWN).timeout
	is_interaction_cooldown = false

func get_remaining_food() -> int:
	"""Kalan yemek miktarını döndür"""
	return GameState.inventory.get("food", 0)
