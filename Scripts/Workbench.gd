extends Node2D

# ==================================================
# CONFIGURATION
# ==================================================
@export_category("Workbench Settings")
@export var workbench_name: String = "Basit Tezgah"
@export var workbench_tier: int = 1  # 1: Basic, 2: Improved, 3: Advanced
@export var craft_speed_multiplier: float = 1.0

# ==================================================
# UI REFERENCES
# ==================================================
@onready var interaction_area: Area2D = $Area2D
@onready var sprite: Sprite2D = $Sprite2D

# ==================================================
# STATE VARIABLES
# ==================================================
var player_inside: bool = false
var player_ref: CharacterBody2D = null
var is_interaction_cooldown: bool = false
var pulse_tween: Tween = null

# ==================================================
# CONSTANTS
# ==================================================
const INTERACTION_COOLDOWN: float = 0.5

# ==================================================
# LIFECYCLE
# ==================================================
func _ready() -> void:
	print("✅ Workbench hazır: ", workbench_name, " (Tier ", workbench_tier, ")")
	
	# Eğer Area2D yoksa uyar
	if not interaction_area:
		print("⚠️ Workbench: Area2D bulunamadı!")
		return
	
	# Signal bağlantılarını yap
	_setup_signal_connections()
	
	# ⭐⭐ YENİ: Crafting panel sinyallerini bağla
	_connect_crafting_panel_signals()
	
	# Görseli tier'a göre ayarla
	_update_visuals()

func _setup_signal_connections() -> void:
	"""Signal'ları kod ile bağla"""
	if interaction_area:
		if not interaction_area.body_entered.is_connected(_on_area_2d_body_entered):
			interaction_area.body_entered.connect(_on_area_2d_body_entered)
		
		if not interaction_area.body_exited.is_connected(_on_area_2d_body_exited):
			interaction_area.body_exited.connect(_on_area_2d_body_exited)
	else:
		print("⚠️ Workbench: Area2D bulunamadı, signal'lar bağlanamıyor!")

func _process(_delta: float) -> void:
	_handle_interaction_input()

# ==================================================
# INPUT HANDLING
# ==================================================
func _handle_interaction_input() -> void:
	"""Workbench ile etkileşim"""
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
	
	_open_crafting_panel()

func _is_player_unable_to_interact() -> bool:
	"""Oyuncu etkileşemez durumda mı?"""
	if not player_ref:
		return true
	
	# Player property kontrolleri
	if "is_dead" in player_ref and player_ref.is_dead:
		return true
	
	if "is_unconscious" in player_ref and player_ref.is_unconscious:
		return true
	
	if "ui_blocked" in player_ref and player_ref.ui_blocked:
		return true
	
	return false

# ==================================================
# CRAFTING PANEL
# ==================================================
func _open_crafting_panel() -> void:
	"""Crafting panelini aç"""
	print("🛠️ Workbench: Crafting paneli açılıyor...")
	
	# Cooldown başlat
	is_interaction_cooldown = true
	
	# InteractionHUD'u gizle
	var hud = get_node_or_null("/root/InteractionHUD")
	if hud:
		hud.hide_hint()
	
	# ⭐⭐ ÖNEMLİ: Player'ı kilitle
	if player_ref and "ui_blocked" in player_ref:
		player_ref.ui_blocked = true
	
	# Crafting panelini aç
	_show_crafting_interface()
	
	# Cooldown sıfırla
	await get_tree().create_timer(INTERACTION_COOLDOWN).timeout
	is_interaction_cooldown = false

func _show_crafting_interface() -> void:
	print("🛠️ Crafting paneli açılıyor (Tier: ", workbench_tier, ")")
	
	# 1. Önce /root altında ara
	var crafting_panel = get_node("/root").find_child("CraftingPanel", true, false)
	
	# 2. Yoksa yükle
	if not crafting_panel:
		print("ℹ️ CraftingPanel yükleniyor...")
		var panel_scene = load("res://Scenes/CraftingPanel.tscn")
		if panel_scene:
			crafting_panel = panel_scene.instantiate()
			crafting_panel.name = "CraftingPanel"
			get_tree().root.add_child(crafting_panel)
			print("✅ CraftingPanel yüklendi")
		else:
			print("❌ CraftingPanel scene bulunamadı!")
			_show_fallback_message()
			return
	
	# 3. CraftingManager'a workbench tier'ını bildir (yükseltmeler kalıcı)
	workbench_tier = max(workbench_tier, CraftingManager.workbench_level)
	if CraftingManager:
		CraftingManager.set_workbench_tier(workbench_tier)
	
	# 4. Panel'i göster
	if crafting_panel.has_method("show_panel"):
		crafting_panel.show_panel(workbench_tier)
		print("✅ CraftingPanel açıldı (Tier: ", workbench_tier, ")")
	else:
		print("❌ show_panel methodu yok!")
		_show_fallback_message()

func _show_fallback_message() -> void:
	"""Crafting paneli yoksa fallback mesaj"""
	var dialogue_ui = get_tree().get_first_node_in_group("dialogue_ui")
	if dialogue_ui and dialogue_ui.has_method("show_dialogue_for_time"):
		dialogue_ui.show_dialogue_for_time(
			"🛠️ " + workbench_name + "\n(Crafting sistemi hazırlanıyor...)",
			3.0
		)
	else:
		print("💬 Crafting sistemi yakında eklenecek!")

# ==================================================
# AREA HANDLERS
# ==================================================
func _on_area_2d_body_entered(body: Node) -> void:
	"""Oyuncu workbench'e yaklaştığında"""
	if not body.is_in_group("player"):
		return
	
	player_inside = true
	player_ref = body
	
	# InteractionHUD'da göster
	var hud = get_node_or_null("/root/InteractionHUD")
	if hud:
		hud.show_hint("[E] Üretim tezgahı")
	else:
		print("⚠️ Workbench: InteractionHUD bulunamadı!")
	
	print("✅ Workbench: Oyuncu yaklaştı")

func _on_area_2d_body_exited(body: Node) -> void:
	"""Oyuncu workbench'ten uzaklaştığında"""
	if not body.is_in_group("player"):
		return
	
	player_inside = false
	
	# ⭐⭐ DÜZELTME: Player'ın kilidini kontrol et
	if player_ref:
		_unlock_player_if_needed(player_ref)
		player_ref = null
	
	# InteractionHUD'u gizle
	var hud = get_node_or_null("/root/InteractionHUD")
	if hud:
		hud.hide_hint()
	
	print("✅ Workbench: Oyuncu uzaklaştı")

# ==================================================
# HELPER FUNCTIONS
# ==================================================
func _connect_crafting_panel_signals() -> void:
	"""Crafting panel sinyallerini dinle"""
	# Crafting panelini bul
	var crafting_panel = get_node("/root").find_child("CraftingPanel", true, false)
	
	if crafting_panel:
		# Panel kapandığında player'ı unlock et
		if crafting_panel.has_signal("panel_closed"):
			if not crafting_panel.panel_closed.is_connected(_on_crafting_panel_closed):
				crafting_panel.panel_closed.connect(_on_crafting_panel_closed)
			print("🔗 Workbench: CraftingPanel sinyallerine bağlandı")

func _on_crafting_panel_closed() -> void:
	"""Crafting paneli kapandığında"""
	print("🔓 Workbench: Crafting paneli kapandı, player kontrolü...")
	
	# Player'ı unlock et
	if player_ref and "ui_blocked" in player_ref:
		player_ref.ui_blocked = false
		print("✅ Workbench: Player unlock edildi")

func _unlock_player_if_needed(player: CharacterBody2D) -> void:
	"""Player'ın kilidini kaldır (eğer crafting paneli kapalıysa)"""
	if not player:
		return
	
	# Crafting panelini kontrol et
	var crafting_panel = get_node("/root").find_child("CraftingPanel", true, false)
	var is_crafting_panel_open = false
	
	if crafting_panel and crafting_panel.has_method("is_visible"):
		is_crafting_panel_open = crafting_panel.is_visible
	
	# Eğer crafting paneli kapalıysa, player'ı unlock et
	if not is_crafting_panel_open:
		if "ui_blocked" in player:
			player.ui_blocked = false
			print("🔓 Workbench: Player unlock edildi (crafting paneli kapalı)")
	
	# Ayrıca, eğer crafting devam etmiyorsa da unlock et
	if CraftingManager and not CraftingManager.is_crafting:
		if "ui_blocked" in player:
			player.ui_blocked = false
			print("🔓 Workbench: Player unlock edildi (crafting devam etmiyor)")

func upgrade_workbench(new_tier: int) -> void:
	"""Workbench'i yükselt"""
	if new_tier > workbench_tier:
		workbench_tier = new_tier
		print("⬆️ Workbench yükseltildi: Tier ", workbench_tier)
		
		# Görseli güncelle
		_update_visuals()
		
		# Craft hızını artır
		craft_speed_multiplier = 1.0 - (workbench_tier - 1) * 0.2
		
		# Event gönder (isteğe bağlı)
		# GameEvents.emit_signal("workbench_upgraded", workbench_tier)

func _update_visuals() -> void:
	"""Workbench görselini tier'a göre güncelle"""
	if not sprite:
		print("⚠️ Workbench: Sprite2D bulunamadı!")
		return
	
	# Önceki pulse efektini durdur
	_stop_pulse_effect()
	
	match workbench_tier:
		1:  # TIER 1 - Basit
			sprite.modulate = Color(1, 1, 1)  # Normal renk
			sprite.material = null  # Material yok
			
		2:  # TIER 2 - Gelişmiş
			sprite.modulate = Color(0.9, 0.95, 1.1)  # Hafif mavi, parlak
			sprite.material = null  # Material yok
			
		3:  # TIER 3 - İleri
			# Mavi ton + parlaklık
			sprite.modulate = Color(0.8, 0.9, 1.2)
			
			# Pulsating efekti başlat
			_start_pulse_effect()

func _start_pulse_effect() -> void:
	"""Tier 3 için yanıp sönen efekt"""
	if not sprite:
		return
	
	# Eski tween'i temizle
	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()
	
	pulse_tween = create_tween()
	pulse_tween.set_loops()
	
	# Normal → Parlak → Normal döngüsü
	pulse_tween.tween_property(sprite, "modulate", 
		Color(0.9, 1.0, 1.4),  # Çok parlak mavi (1.4 = %40 daha parlak)
		1.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	pulse_tween.tween_property(sprite, "modulate", 
		Color(0.8, 0.9, 1.2),  # Normal parlaklık
		1.5
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	
	print("✨ Tier 3 pulse efekti başlatıldı")

func _stop_pulse_effect() -> void:
	"""Pulse efektini durdur"""
	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()
		pulse_tween = null

# ==================================================
# DEBUG FUNCTIONS
# ==================================================
func _debug_print_state() -> void:
	"""Debug için durumu yazdır"""
	print("=== WORKBENCH DEBUG ===")
	print("Name:", workbench_name)
	print("Tier:", workbench_tier)
	print("Player inside:", player_inside)
	print("Player ref:", "✅" if player_ref else "❌")
	print("Cooldown:", is_interaction_cooldown)
	print("Speed multiplier:", craft_speed_multiplier)
	print("=======================")
