# World.gd
extends Node2D

# Referanslar
@onready var global_darkness: CanvasModulate

func _ready():
	print("🌍 World hazırlanıyor...")
	
	# 1. Global karanlık efekti
	_setup_global_darkness()
	
	# 2. Bağlantıları kur (1 frame sonra)
	await get_tree().process_frame
	_setup_connections()
	
	# 3. TimeManager bağlantısı
	_connect_to_time_system()
	
	# 4. Yeni oyunda hedef ve kontroller
	if GameState.current_day == 1 and GameState.current_hour == 0:
		SurvivalManager.notify("Zehirli yağmur dinmiyor. Hayatta kal ve telsizi onar.\n3 radyo parçası + 1 pil ile yardım çağır.")
		SurvivalManager.notify("E: Etkileşim  |  1: Ye  2: İç  3: Medkit  4: Enerji İçeceği")
	
	print("✅ World hazır!")

func _setup_global_darkness():
	# CanvasModulate oluştur - tüm ekranı etkiler
	global_darkness = CanvasModulate.new()
	global_darkness.name = "GlobalDarkness"
	
	# Orta karanlık bir renk (gece efekti)
	global_darkness.color = Color(0.10, 0.10, 0.12)
	
	add_child(global_darkness)
	
	print("✅ Global karanlık efekti eklendi")
	print("   - Renk: ", global_darkness.color)

func _setup_connections():
	print("   🔗 Bağlantılar kuruluyor...")
	
	# 1 frame bekle (tüm node'lar hazır olsun)
	await get_tree().process_frame
	
	# Düğümleri bul
	var player = get_tree().get_first_node_in_group("player")
	var hud = get_tree().get_first_node_in_group("hud")
	var death_screen = get_tree().get_first_node_in_group("death_screen")
	var time_manager = get_tree().get_first_node_in_group("time_manager")
	
	# Debug
	print("     - Player: ", "✅" if player else "❌")
	print("     - HUD: ", "✅" if hud else "❌")
	print("     - DeathScreen: ", "✅" if death_screen else "❌")
	print("     - TimeManager: ", "✅" if time_manager else "❌")
	
	# 1. Player -> HUD bağlantısı
	if player and hud:
		if not player.stats_changed.is_connected(hud._on_player_stats_changed):
			player.stats_changed.connect(hud._on_player_stats_changed)
			print("     ✅ HUD bağlandı")
	
	# 2. Player -> DeathScreen bağlantısı
	if death_screen and player:
		# Önce eski bağlantıyı kes (güvenli)
		if player.player_died.is_connected(death_screen.show_death_screen):
			player.player_died.disconnect(death_screen.show_death_screen)
		
		# Yeni bağlantıyı yap
		player.player_died.connect(death_screen.show_death_screen)
	
	# Kurtarılma -> zafer ekranı
	if death_screen and not SurvivalManager.rescue_arrived.is_connected(_on_rescue_arrived):
		SurvivalManager.rescue_arrived.connect(_on_rescue_arrived)
		print("     ✅ DeathScreen bağlandı (show_death_screen)")
	
	print("   🔗 Bağlantılar tamamlandı")

func _on_rescue_arrived() -> void:
	var death_screen = get_tree().get_first_node_in_group("death_screen")
	if death_screen:
		death_screen.show_victory_screen(SurvivalManager.get_stats())

func _connect_to_time_system():
	var time_manager = get_tree().get_first_node_in_group("time_manager")
	if time_manager and time_manager.has_signal("hour_changed"):
		if not time_manager.hour_changed.is_connected(_on_time_changed):
			time_manager.hour_changed.connect(_on_time_changed)  # ⭐ 2 parametre bağlanıyor
			print("   ⏰ TimeManager ışık sistemine bağlandı")
		_on_time_changed(time_manager.current_hour, time_manager.current_day)
	else:
		print("   ⏰ TimeManager bulunamadı veya sinyal yok")

func _on_time_changed(hour: int, day: int):
	if not global_darkness:
		return
	
	# ⭐ DAHA KARANLIK VERSİYON
	# Gece (18:00-06:00) ÇOK karanlık
	if hour >= 18 or hour <= 6:
		# Gece: ÇOK koyu
		global_darkness.color = Color(0.10, 0.10, 0.12)  # ⭐ Neredeyse siyah
		print("   🌙🌑 Gece modu - Çok Karanlık (", hour, ":00)")
	else:
		# Gündüz: yine karanlık ama biraz açık
		global_darkness.color = Color(0.15, 0.15, 0.18)  # ⭐ Karanlık
		print("   ☀️🌆 Gündüz modu - Karanlık (", hour, ":00)")

# Opsiyonel: Dışarı/İçeri geçişler için
func set_environment_mode(is_inside: bool):
	"""İçeride veya dışarıda olma durumuna göre ışık"""
	if not global_darkness:
		return
	
	if is_inside:
		# İçeride: daha karanlık
		global_darkness.color = Color(0.15, 0.15, 0.2)
		print("   🏠 İç mekan - Karanlık")
	else:
		# Dışarıda: normal
		global_darkness.color = Color(0.22, 0.22, 0.28)
		print("   🌳 Dış mekan - Normal")

# Debug için: Işık ayarlarını değiştir
func debug_change_light(brightness: float = 1.0):
	"""Debug: Işık parlaklığını değiştir"""
	if global_darkness:
		global_darkness.color = global_darkness.color * brightness
		print("   🔦 Işık parlaklığı: x", brightness)

func _debug_lighting():
	print("\n=== LIGHTING DEBUG ===")
	
	print("Total lights in scene: ", get_tree().get_nodes_in_group("lights").size())
	
	# CanvasModulate kontrolü
	var canvas_nodes = []
	for node in get_children():
		if node is CanvasModulate:
			canvas_nodes.append(node)
	print("CanvasModulate nodes: ", canvas_nodes.size())
	
	# Player light kontrolü
	var player = get_tree().get_first_node_in_group("player")
	if player:
		for child in player.get_children():
			if child is PointLight2D:
				print("Player light found:")
				print("  - Energy: ", child.energy)
				print("  - Visible: ", child.visible)
				print("  - Color: ", child.color)
	
	print("=== END DEBUG ===\n")
	
