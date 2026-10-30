extends Node2D

# ==================================================
# CONFIGURATION
# ==================================================
@export_category("UI References")
@export var dialogue_ui_path: NodePath

# ==================================================
# UI REFERENCES
# ==================================================
@onready var dialogue = get_node_or_null(dialogue_ui_path)

# ==================================================
# STATE VARIABLES
# ==================================================
var player_inside: bool = false
var opened: bool = false
var player_ref: CharacterBody2D = null
var is_interaction_cooldown: bool = false

# ==================================================
# CONSTANTS
# ==================================================
const INTERACTION_COOLDOWN: float = 0.3  # seconds

# ==================================================
# LIFECYCLE
# ==================================================
func _ready() -> void:
	_validate_dialogue_ui()

func _process(delta: float) -> void:
	_handle_interaction_input()

# ==================================================
# VALIDATION & SETUP
# ==================================================
func _validate_dialogue_ui() -> void:
	"""DialogueUI referansını kontrol et"""
	if not dialogue:
		print("  - Path: ", dialogue_ui_path)
		
		# Alternatif arama
		dialogue = get_tree().get_first_node_in_group("dialogue_ui")
		if dialogue:
			print("  ✅ DialogueUI grup üzerinden bulundu")

# ==================================================
# INPUT HANDLING
# ==================================================
func _handle_interaction_input() -> void:
	"""Etkileşim girişini işle"""
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
	"""Oyuncunun etkileşim yapamayacağı durumları kontrol et"""
	if not player_ref:
		return true
	
	# Player.gd'deki property'leri kontrol et
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
	"""Telsiz etkileşimi"""
	# Cooldown başlat
	is_interaction_cooldown = true
	
	# Durumu değiştir
	opened = true
	
	# InteractionHUD hint'ini kapat
	var hud = get_node_or_null("/root/InteractionHUD")
	if hud:
		hud.hide_hint()
	
	# Diyalogu yönet
	_manage_dialogue()
	
	# Cooldown sıfırla
	await get_tree().create_timer(INTERACTION_COOLDOWN).timeout
	is_interaction_cooldown = false

func _manage_dialogue() -> void:
	"""Diyalog mesajını yönet"""
	if not dialogue:
		print("📻 Telsiz: ", "Açıldı" if opened else "Kapandı")
		return
	
	if opened:
		_show_radio_message()
	else:
		_hide_radio_message()

func _show_radio_message() -> void:
	"""Telsiz mesajını göster"""
	var message = SurvivalManager.use_radio()
	
	if dialogue.has_method("show_dialogue_for_time"):
		dialogue.show_dialogue_for_time(message, 3.0)
	elif dialogue.has_method("show_dialogue"):
		dialogue.show_dialogue(message)
		await get_tree().create_timer(3.0).timeout
		if dialogue.has_method("hide_dialogue"):
			dialogue.hide_dialogue()
	else:
		print("📻 ", message)

func _hide_radio_message() -> void:
	"""Telsiz mesajını gizle"""
	if dialogue and dialogue.has_method("hide_dialogue"):
		dialogue.hide_dialogue()

# ==================================================
# AREA HANDLERS
# ==================================================
func _on_area_2d_body_entered(body: Node) -> void:
	"""Oyuncu alana girdiğinde"""
	if not body.is_in_group("player"):
		return
	
	player_inside = true
	player_ref = body
	
	# InteractionHUD'da göster
	var hud = get_node_or_null("/root/InteractionHUD")
	if hud:
		hud.show_hint("[E] Telsiz")

func _on_area_2d_body_exited(body: Node) -> void:
	"""Oyuncu alandan çıktığında"""
	if not body.is_in_group("player"):
		return
	
	player_inside = false
	player_ref = null
	
	# InteractionHUD'u gizle
	var hud = get_node_or_null("/root/InteractionHUD")
	if hud:
		hud.hide_hint()
	
	# Diyaloğu kapat
	_hide_radio_message()
	opened = false

# ==================================================
# HELPER FUNCTIONS
# ==================================================
func is_radio_open() -> bool:
	"""Telsizin açık olup olmadığını döndür"""
	return opened

# ==================================================
# DEBUG FUNCTIONS
# ==================================================
func _debug_print_state() -> void:
	"""Debug için mevcut durumu yazdır"""
	print("=== RECEIVER DEBUG ===")
	print("Player inside:", player_inside)
	print("Radio opened:", opened)
	print("Player ref:", "✅" if player_ref else "❌")
	print("Cooldown:", is_interaction_cooldown)
	print("DialogueUI:", "✅" if dialogue else "❌")
	print("======================")
