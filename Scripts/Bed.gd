extends Node2D

# ==================================================
# CONFIGURATION
# ==================================================
@export_category("Sleep Settings")
@export_range(1, 12, 1) var sleep_hours: int = 8
@export_range(0, 100, 1) var min_energy_to_sleep: int = 80

@export_category("UI References")
@export var dialogue_ui_path: NodePath

# ==================================================
# UI REFERENCES
# ==================================================
@onready var dialogue_ui = get_node_or_null(dialogue_ui_path)

# ==================================================
# STATE VARIABLES
# ==================================================
var player_inside: bool = false
var player_ref: CharacterBody2D = null
var is_interaction_cooldown: bool = false

# ==================================================
# CONSTANTS
# ==================================================
const INTERACTION_COOLDOWN: float = 1.0

# ==================================================
# LIFECYCLE
# ==================================================

func _ready() -> void:
	_validate_dialogue_ui()
	
	if not dialogue_ui:
		print("⚠️ Bed: DialogueUI otomatik bulunamadı, manuel aranıyor...")
		_find_dialogue_ui_manually()
	
	print("🛏️ Bed hazır (" + str(sleep_hours) + " saat)")
	print("  - DialogueUI: ", "✅" if dialogue_ui else "❌")

# ==================================================
# VALIDATION & SETUP
# ==================================================
func _validate_dialogue_ui() -> void:
	"""DialogueUI referansını kontrol et ve bul - DEBUG EKLİ"""
	print("🔍 Bed: DialogueUI aranıyor...")
	
	if dialogue_ui:
		print("  ✅ DialogueUI zaten var (path'den)")
		return
	
	print("  ⚠️ dialogue_ui null, aranıyor...")
	print("  - dialogue_ui_path: ", dialogue_ui_path)
	print("  - Path'den node var mı: ", get_node_or_null(dialogue_ui_path) != null)
	
	# 1. Path'den dene
	dialogue_ui = get_node_or_null(dialogue_ui_path)
	if dialogue_ui:
		print("  ✅ Path'den bulundu: ", dialogue_ui.name)
		return
	
	# 2. Grup'tan dene
	print("  🔍 Grup'tan aranıyor...")
	dialogue_ui = get_tree().get_first_node_in_group("dialogue_ui")
	if dialogue_ui:
		print("  ✅ Grup'tan bulundu: ", dialogue_ui.name)
		return
	
	# 3. FoodShelf'ten öğren
	print("  🔍 FoodShelf aranıyor...")
	var foodshelf = get_tree().get_first_node_in_group("foodshelf")
	if foodshelf:
		print("  ✅ FoodShelf bulundu: ", foodshelf.name)
		if "dialogue_ui" in foodshelf and foodshelf.dialogue_ui:
			dialogue_ui = foodshelf.dialogue_ui
			print("  ✅ FoodShelf'ten kopyalandı: ", dialogue_ui.name)
		else:
			print("  ❌ FoodShelf'te dialogue_ui yok veya null")
	else:
		print("  ❌ FoodShelf bulunamadı")
	
	if not dialogue_ui:
		print("  ❌ DialogueUI HİÇBİR YERDE BULUNAMADI!")

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
		return
	
	_on_interact()

func _is_player_unable_to_interact() -> bool:
	if not player_ref:
		return true
	
	# 1. Temel kontroller
	if player_ref.is_dead:
		_show_message("💀 Ölüler uyuyamaz...", 2.0)
		return true
	
	if player_ref.is_unconscious:
		_show_message("😵 Zaten baygınsın...", 2.0)
		return true
	
	if player_ref.ui_blocked:
		return true
	
	if player_ref.is_sleeping:
		_show_message("😴 Zaten uyuyorsun...", 2.0)
		return true
	
	# 2. Enerji kontrolü - YORGUN MU?
	if not _is_player_tired():
		_show_not_tired_message()
		return true
	
	return false

func _is_player_tired() -> bool:
	if not player_ref:
		return false
	
	# Method varsa onu kullan
	if player_ref.has_method("needs_sleep"):
		return player_ref.needs_sleep()
	
	# Yoksa basit enerji kontrolü
	if "energy" in player_ref:
		return player_ref.energy < min_energy_to_sleep
	
	return true  # Varsayılan: uyuyabilir

# ==================================================
# INTERACTION LOGIC
# ==================================================
func _on_interact() -> void:
	# Cooldown başlat
	is_interaction_cooldown = true
	
	# InteractionHUD hint'ini kapat
	var hud = get_node_or_null("/root/InteractionHUD")
	if hud:
		hud.hide_hint()
	
	# Uyku başlat
	_start_sleep()
	
	# Cooldown sıfırla
	await get_tree().create_timer(INTERACTION_COOLDOWN).timeout
	is_interaction_cooldown = false

func _start_sleep() -> void:
	print("😴 Bed: Uyku başlatılıyor (" + str(sleep_hours) + " saat)")
	
	# Mesaj göster
	_show_message("😴 " + str(sleep_hours) + " saat uyuyorsun...", 2.5)
	
	# Player'da start_sleep metodu var mı kontrol et
	if player_ref and player_ref.has_method("start_sleep"):
		player_ref.start_sleep(sleep_hours)
	else:
		print("⚠️ Bed: Player'da start_sleep metodu yok!")
		
		# Fallback: basit bekleme
		await get_tree().create_timer(2.0).timeout
		print("💤 Fallback uyku: " + str(sleep_hours) + " saat geçti")

# ==================================================
# UI FEEDBACK
# ==================================================
func _show_not_tired_message() -> void:
	var energy_percent = player_ref.energy if "energy" in player_ref else 100
	var message = "Yorgun değilsin...\nEnerjin: " + str(energy_percent) + "%\n" + str(min_energy_to_sleep) + "%'den az olunca uyuyabilirsin."
	_show_message(message, 3.0)

func _show_message(text: String, duration: float = 2.0) -> void:
	print("💬 Bed: Mesaj gösteriliyor: '", text, "'")
	print("  - dialogue_ui: ", "✅" if dialogue_ui else "❌")
	
	if not dialogue_ui:
		print("  ⚠️ dialogue_ui null, konsola yazıldı")
		print("💬 ", text)
		return
	
	# DialogueUI'nin method'larını kontrol et
	print("  - has_method('show_dialogue_for_time'): ", dialogue_ui.has_method("show_dialogue_for_time"))
	print("  - has_method('show_dialogue'): ", dialogue_ui.has_method("show_dialogue"))
	print("  - has_method('hide_dialogue'): ", dialogue_ui.has_method("hide_dialogue"))
	
	# show_dialogue_for_time metodu varsa
	if dialogue_ui.has_method("show_dialogue_for_time"):
		print("  🎯 show_dialogue_for_time çağrılıyor...")
		dialogue_ui.show_dialogue_for_time(text, duration)
		print("  ✅ show_dialogue_for_time çağrıldı")
		return
	
	# show_dialogue metodu varsa
	if dialogue_ui.has_method("show_dialogue"):
		print("  🎯 show_dialogue çağrılıyor...")
		dialogue_ui.show_dialogue(text)
		await get_tree().create_timer(duration).timeout
		
		if dialogue_ui.has_method("hide_dialogue"):
			dialogue_ui.hide_dialogue()
			print("  ✅ hide_dialogue çağrıldı")
		return
	
	# Fallback
	print("  ⚠️ Hiçbir method bulunamadı, konsola yazılıyor")
	print("💬 ", text)

# Bed.gd'ye yeni fonksiyon ekle:
func _find_dialogue_ui_manually() -> void:
	"""DialogueUI'yi manuel olarak bul"""
	print("🔍 Bed: Manuel DialogueUI araması...")
	
	# Tüm olası yolları dene
	var possible_paths = [
		"/root/World/UI/DialogueUI",
		"/root/UI/DialogueUI", 
		"../UI/DialogueUI",
		"../../UI/DialogueUI"
	]
	
	for path in possible_paths:
		var node = get_node_or_null(path)
		if node:
			print("  ✅ Bulundu: ", path, " -> ", node.name)
			dialogue_ui = node
			return
	
	print("  ❌ Hiçbir path'te bulunamadı")
	
	# Scene tree'de ara
	print("  🔍 Tüm scene'de aranıyor...")
	for node in get_tree().get_nodes_in_group("ui"):
		if "DialogueUI" in node.name or node.has_method("show_dialogue"):
			print("  ✅ Grup'tan bulundu: ", node.name)
			dialogue_ui = node
			return
	
	print("  ❌ Manuel arama başarısız")

# ==================================================
# AREA HANDLERS
# ==================================================
func _on_area_2d_body_entered(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	
	player_inside = true
	player_ref = body
	
	# InteractionHUD'da duruma göre göster
	_update_interaction_hint()
	
	print("✅ Bed: Oyuncu yatağa yaklaştı")

func _on_area_2d_body_exited(body: Node2D) -> void:
	if not body.is_in_group("player"):
		return
	
	player_inside = false
	player_ref = null
	
	# InteractionHUD'u gizle
	var hud = get_node_or_null("/root/InteractionHUD")
	if hud:
		hud.hide_hint()
	
	print("✅ Bed: Oyuncu yataktan uzaklaştı")

# ==================================================
# INTERACTION HINT MANAGEMENT
# ==================================================
func _update_interaction_hint() -> void:
	var hud = get_node_or_null("/root/InteractionHUD")
	if not hud:
		return
	
	if not player_inside:
		return
	
	# Yorgunluk durumuna göre hint göster
	if _is_player_tired():
		hud.show_hint("[E] Uyu (" + str(sleep_hours) + " saat)")
	else:
		hud.show_hint("[E] Yorgun değilsin")

# ==================================================
# HELPER FUNCTIONS
# ==================================================
func get_sleep_hours() -> int:
	return sleep_hours

func set_sleep_hours(hours: int) -> void:
	sleep_hours = clamp(hours, 1, 24)
	print("🛏️ Uyku saati değiştirildi: " + str(sleep_hours) + " saat")
	
	# Eğer oyuncu içerdeyse, hint'i güncelle
	if player_inside:
		_update_interaction_hint()

func set_min_energy_to_sleep(percent: int) -> void:
	min_energy_to_sleep = clamp(percent, 0, 100)
	print("🛏️ Min uyuma enerjisi: " + str(min_energy_to_sleep) + "%")

# ==================================================
# DEBUG FUNCTIONS
# ==================================================
func _debug_print_state() -> void:
	print("=== BED DEBUG ===")
	print("Player inside:", player_inside)
	var player_status = "✅" if player_ref else "❌"
	print("Player ref:", player_status)
	print("Sleep hours:", sleep_hours)
	print("Min energy to sleep: " + str(min_energy_to_sleep) + "%")
	print("Cooldown:", is_interaction_cooldown)
	var dialogue_status = "✅" if dialogue_ui else "❌"
	print("DialogueUI:", dialogue_status)
	print("Player tired:", _is_player_tired())
	if player_ref and "energy" in player_ref:
		print("Player energy: " + str(player_ref.energy) + "%")
	print("=================")
