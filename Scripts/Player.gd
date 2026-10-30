extends CharacterBody2D

# ==================================================
# SİNYALLER
# ==================================================
signal stats_changed(health: float, hunger: float, energy: float, suit: float, thirst: float)
signal player_died(reason: String, stats: Dictionary)

# ==================================================
# PARAMETRELER
# ==================================================
@export var speed := 120.0
@export var gravity := 900.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player_light: PointLight2D = null

# ==================================================
# DURUM DEĞİŞKENLERİ
# ==================================================
var health := 100.0
var hunger := 100.0
var energy := 100.0
var thirst := 100.0

var hunger_rate := 2.0
var energy_rate := 1.0
var thirst_rate := 3.0
const DIRTY_WATER_SICK_CHANCE := 0.4

var is_dead := false
var is_unconscious := false
var is_sleeping := false
var ui_blocked := false
var can_move: bool = true
var _is_time_manager_connected := false  # ⭐ TimeManager bağlantı kontrolü

# ==================================================
# LIFECYCLE
# ==================================================
func _ready():
	_apply_saved_stats()
	update_ui()
	_setup_player_light()
	print("✅ Player hazır")
	
	await get_tree().process_frame
	_connect_to_time_manager()

func _physics_process(delta: float) -> void:
	
	if not can_move or ui_blocked or is_dead or is_unconscious or is_sleeping:
		if not is_on_floor():
			velocity.y += gravity * delta
		else:
			velocity.y = 0
		
		velocity.x = 0
		
		# Idle animasyonu
		if sprite:
			sprite.play("idle")
		
		move_and_slide()
		return  # ⭐
	
	if not is_on_floor():
		velocity.y += gravity * delta
	else:
		velocity.y = 0

	var dir := Input.get_axis("ui_left", "ui_right")
	velocity.x = dir * speed
	
	_handle_animations(dir)
	move_and_slide()

func _apply_saved_stats() -> void:
	var s: Dictionary = GameState.player_stats
	if s.is_empty():
		return
	health = float(s.get("health", health))
	hunger = float(s.get("hunger", hunger))
	energy = float(s.get("energy", energy))
	thirst = float(s.get("thirst", thirst))

# ==================================================
# TIME MANAGER BAĞLANTISI
# ==================================================
func _connect_to_time_manager() -> void:
	print("🕐 Player: TimeManager bağlantısı deneniyor...")
	
	# 1. Frame bekle
	await get_tree().process_frame
	
	# 2. TimeManager'ı ara
	var time_manager = null
	
	# Grup'tan dene
	time_manager = get_tree().get_first_node_in_group("time_manager")
	
	# Yoksa path'ten dene
	if not time_manager:
		time_manager = get_node_or_null("/root/World/TimeManager")
	
	# Hala yoksa tüm ağaçta ara
	if not time_manager:
		for node in get_tree().root.get_children():
			if node.name == "TimeManager" or node.is_in_group("time_manager"):
				time_manager = node
				break
	
	# Bağlantıyı yap
	if time_manager:
		# Eski bağlantıyı kontrol et ve kes
		if time_manager.hour_changed.is_connected(_on_hour_passed):
			time_manager.hour_changed.disconnect(_on_hour_passed)
		
		# Yeni bağlantıyı yap
		time_manager.hour_changed.connect(_on_hour_passed)
		_is_time_manager_connected = true
		print("✅ Player: TimeManager'a bağlandı")

# ==================================================
# HAREKET KONTROL FONKSİYONLARI
# ==================================================
func enable_movement() -> void:
	"""Hareketi etkinleştir"""
	can_move = true
	ui_blocked = false
	print("🚶 Player: Hareket etkinleştirildi")

func disable_movement() -> void:
	"""Hareketi devre dışı bırak"""
	can_move = false
	ui_blocked = true
	velocity = Vector2.ZERO  # ⭐ Hızı sıfırla
	print("🚫 Player: Hareket devre dışı bırakıldı")

# ==================================================
# ANIMASYONLAR
# ==================================================
func _handle_animations(dir: float) -> void:
	if not sprite: 
		return
	
	if dir != 0:
		sprite.play("walk")
		sprite.flip_h = dir < 0
	else:
		sprite.play("idle")

# ==================================================
# IŞIK SİSTEMİ
# ==================================================
func _setup_player_light():
	# Işık node'unu oluştur
	var light = PointLight2D.new()
	light.name = "PlayerLight"
	
	# Işık ayarları
	light.energy = 1.0
	light.color = Color(1.0, 0.85, 0.6)
	light.texture_scale = 1.5
	light.height = 1.0
	light.shadow_enabled = true
	light.shadow_color = Color(0, 0, 0, 0.6)
	
	# Gradient texture oluştur
	var image = Image.create(128, 128, false, Image.FORMAT_RGBA8)
	for x in range(128):
		for y in range(128):
			var dx = (x - 64) / 64.0
			var dy = (y - 64) / 64.0
			var distance = sqrt(dx*dx + dy*dy)
			if distance <= 1.0:
				var alpha = 1.0 - (distance * distance)
				image.set_pixel(x, y, Color(1, 1, 1, alpha))
			else:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
	
	var texture = ImageTexture.create_from_image(image)
	light.texture = texture
	
	add_child(light)
	player_light = light
	light.z_index = 100
	print("✅ Player ışığı oluşturuldu")

# ==================================================
# OYUN MEKANİKLERİ
# ==================================================
func needs_food() -> bool:
	return hunger < 90  # %90'dan azsa yemek ye

func needs_sleep() -> bool:
	return energy < 80

func _on_hour_passed(_hour: int, _day: int) -> void:
	if is_dead: 
		return
	
	# Dışarıdayken değerleri OutsidePanel simülasyonu yönetir
	if GameState.is_outside:
		return
	
	print_debug("Saat geçiyor - Saat: ", _hour, ", Gün: ", _day)
	
	# Eğer uyuyorsa bonus, değilse normal kayıp
	if is_sleeping:
		hunger -= hunger_rate * 0.25
		thirst -= thirst_rate * 0.3
		energy += 15.0
		# Aç/susuz uyuyan iyileşmez
		if hunger > 20 and thirst > 20:
			health += 5.0
	else:
		hunger -= hunger_rate
		thirst -= thirst_rate
		# Karanlıkta (pil yoksa) stres: enerji daha hızlı düşer
		var drain := energy_rate * (2.0 if SurvivalManager.is_dark() else 1.0)
		energy -= drain
	
	# Açlık / susuzluk hasarı
	if hunger <= 0:
		health -= 5.0
	if thirst <= 0:
		health -= 8.0
	
	# Değerleri sınırla
	hunger = clamp(hunger, 0, 100)
	thirst = clamp(thirst, 0, 100)
	energy = clamp(energy, 0, 100)
	health = clamp(health, 0, 100)
	
	_update_light()
	
	print_debug("Yeni değerler - HP: ", health, " Açlık: ", hunger, " Enerji: ", energy)
	
	# Bayılma kontrolü
	if energy <= 0 and not is_unconscious:
		print_debug("Enerji bitti, bayılıyor...")
		faint()
	
	# Ölüm kontrolü
	if health <= 0:
		print_debug("Ölüm!")
		die()
	
	# UI güncelle
	update_ui()

func update_ui() -> void:
	print_debug("UI güncelleniyor - HP: ", health, " Açlık: ", hunger, " Enerji: ", energy, " Suit: ", GameState.suit_durability)
	stats_changed.emit(health, hunger, energy, GameState.suit_durability, thirst)

func _update_light() -> void:
	if player_light:
		player_light.energy = 0.35 if SurvivalManager.is_dark() else 1.0

func faint() -> void:
	if is_unconscious or is_dead: return
	is_unconscious = true
	if sprite: sprite.play("idle")
	
	await get_tree().create_timer(3.0).timeout
	
	energy = 30.0
	is_unconscious = false
	update_ui()

func start_sleep(hours: int, fade_node: CanvasLayer = null) -> void:
	if is_sleeping or is_dead: 
		return
	
	print_debug("Uyku başlıyor: ", hours, " saat")
	
	# EĞER dışarıdan fade_node gelmediyse, gruptan bul:
	var final_fade = fade_node
	if final_fade == null:
		final_fade = get_tree().get_first_node_in_group("sleep_fade")
	
	is_sleeping = true
	is_unconscious = true
	if sprite: 
		sprite.play("idle")
	
	# Fade in efekti
	if final_fade:
		print_debug("Fade in başlıyor...")
		final_fade.fade_in(1.5)
		await final_fade.fade_in_completed
	
	# Zaman ilerletme mantığı - DEĞİŞTİR
	var tm = get_tree().get_first_node_in_group("time_manager")
	if tm:
		print_debug("TimeManager bulundu, saat ilerletiliyor...")
		for i in range(hours):
			# SADECE bir kere hour değişimi yap
			tm.force_pass_hour()
			# Kısa bekleme (animasyon için)
			await get_tree().create_timer(0.5).timeout
			print_debug("Uyku saati: ", i+1, "/", hours)
	else:
		print_debug("TimeManager bulunamadı!")
	
	# Fade out efekti
	if final_fade:
		print_debug("Fade out başlıyor...")
		final_fade.fade_out(1.5)
		await final_fade.fade_out_completed
	
	print_debug("Uyku bitti")
	is_unconscious = false
	is_sleeping = false
	if not is_dead:
		GameState.save_game()

func use_consumable(item: String) -> bool:
	if is_dead or is_sleeping:
		return false
	match item:
		"food":
			if hunger >= 100.0 or not GameState.remove_from_inventory("food"):
				return false
			hunger = clampf(hunger + 35.0, 0.0, 100.0)
		"medkit":
			if health >= 100.0 or not GameState.remove_from_inventory("medkit"):
				return false
			health = clampf(health + 40.0, 0.0, 100.0)
		"energy_drink":
			if energy >= 100.0 or not GameState.remove_from_inventory("energy_drink"):
				return false
			energy = clampf(energy + 25.0, 0.0, 100.0)
			thirst = clampf(thirst + 10.0, 0.0, 100.0)
		"water":
			if thirst >= 100.0:
				return false
			if GameState.remove_from_inventory("water"):
				thirst = clampf(thirst + 40.0, 0.0, 100.0)
			elif GameState.remove_from_inventory("dirty_water"):
				thirst = clampf(thirst + 30.0, 0.0, 100.0)
				if randf() < DIRTY_WATER_SICK_CHANCE:
					health = clampf(health - 12.0, 0.0, 100.0)
					_notify("Kirli su midene dokundu! -12 Can")
					if health <= 0:
						die()
			else:
				return false
		_:
			return false
	update_ui()
	return true

func _notify(text: String) -> void:
	var dialogue = get_tree().get_first_node_in_group("dialogue_ui")
	if dialogue and dialogue.has_method("show_dialogue_for_time"):
		dialogue.show_dialogue_for_time(text, 2.5)

func die(reason_override: String = "") -> void:
	if is_dead: return
	is_dead = true
	
	var reason := "injury"
	if not reason_override.is_empty(): reason = reason_override
	elif thirst <= 0: reason = "dehydration"
	elif hunger <= 0: reason = "starvation"
	elif energy <= 0: reason = "exhaustion"
	
	# Ölünce eski kayıttan devam edilemesin
	if FileAccess.file_exists("user://savegame.save"):
		DirAccess.remove_absolute("user://savegame.save")
	
	var stats = SurvivalManager.get_stats()
	
	player_died.emit(reason, stats)

# ==================================================
# DEBUG FONKSİYONU - Hız kontrolü için
# ==================================================
func _unhandled_input(event: InputEvent) -> void:
	if ui_blocked or is_dead or is_sleeping:
		return
	if event.is_action_pressed("use_food"):
		use_consumable("food")
	elif event.is_action_pressed("use_water"):
		use_consumable("water")
	elif event.is_action_pressed("use_medkit"):
		use_consumable("medkit")
	elif event.is_action_pressed("use_energy_drink"):
		use_consumable("energy_drink")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("debug"):
		print("🔧 DEBUG - Player:")
		print("  - Velocity: ", velocity)
		print("  - Speed: ", speed)
		print("  - can_move: ", can_move)
		print("  - ui_blocked: ", ui_blocked)
		print("  - Position: ", position)
