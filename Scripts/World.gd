# World.gd
extends Node2D

# Referanslar
@onready var global_darkness: CanvasModulate

func _ready():
	
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
		if GameSettings.show_hints:
			SurvivalManager.notify("A/D yürü  ·  E etkileşim  ·  TAB envanter  ·  1-4 hızlı kullanım  ·  ESC menü")
	

func _setup_global_darkness():
	# CanvasModulate oluştur - tüm ekranı etkiler
	global_darkness = CanvasModulate.new()
	global_darkness.name = "GlobalDarkness"
	
	# Orta karanlık bir renk (gece efekti)
	global_darkness.color = Color(0.10, 0.10, 0.12)
	
	add_child(global_darkness)
	

func _setup_connections():
	
	# 1 frame bekle (tüm node'lar hazır olsun)
	await get_tree().process_frame
	
	# Düğümleri bul
	var player = get_tree().get_first_node_in_group("player")
	var hud = get_tree().get_first_node_in_group("hud")
	var death_screen = get_tree().get_first_node_in_group("death_screen")
	var time_manager = get_tree().get_first_node_in_group("time_manager")
	
	# Debug
	
	# 1. Player -> HUD bağlantısı
	if player and hud:
		if not player.stats_changed.is_connected(hud._on_player_stats_changed):
			player.stats_changed.connect(hud._on_player_stats_changed)
	
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
	

func _on_rescue_arrived() -> void:
	var death_screen = get_tree().get_first_node_in_group("death_screen")
	if death_screen:
		death_screen.show_victory_screen(SurvivalManager.get_stats())

func _connect_to_time_system():
	var time_manager = get_tree().get_first_node_in_group("time_manager")
	if time_manager and time_manager.has_signal("hour_changed"):
		if not time_manager.hour_changed.is_connected(_on_time_changed):
			time_manager.hour_changed.connect(_on_time_changed)  # ⭐ 2 parametre bağlanıyor
		_on_time_changed(time_manager.current_hour, time_manager.current_day)

func _on_time_changed(hour: int, day: int):
	if not global_darkness:
		return
	
	# ⭐ DAHA KARANLIK VERSİYON
	# Gece (18:00-06:00) ÇOK karanlık
	if hour >= 18 or hour <= 6:
		# Gece: ÇOK koyu
		global_darkness.color = Color(0.10, 0.10, 0.12)  # ⭐ Neredeyse siyah
	else:
		# Gündüz: yine karanlık ama biraz açık
		global_darkness.color = Color(0.15, 0.15, 0.18)  # ⭐ Karanlık

# Opsiyonel: Dışarı/İçeri geçişler için
func set_environment_mode(is_inside: bool):
	"""İçeride veya dışarıda olma durumuna göre ışık"""
	if not global_darkness:
		return
	
	if is_inside:
		# İçeride: daha karanlık
		global_darkness.color = Color(0.15, 0.15, 0.2)
	else:
		# Dışarıda: normal
		global_darkness.color = Color(0.22, 0.22, 0.28)
