extends CanvasLayer

# ==================================================
# UI REFERENCES
# ==================================================
@onready var background: ColorRect = $Control/Background  # ⭐ ColorRect olarak değiştir
@onready var title_label: Label = $Control/CenterContainer/VBoxContainer/TitleLabel
@onready var buttons_vbox: VBoxContainer = $Control/CenterContainer/VBoxContainer/ButtonsVBox
@onready var new_game_btn: Button = $Control/CenterContainer/VBoxContainer/ButtonsVBox/NewGameBtn
@onready var load_game_btn: Button = $Control/CenterContainer/VBoxContainer/ButtonsVBox/LoadGameBtn
@onready var settings_btn: Button = $Control/CenterContainer/VBoxContainer/ButtonsVBox/SettingsBtn
@onready var quit_btn: Button = $Control/CenterContainer/VBoxContainer/ButtonsVBox/QuitBtn
@onready var version_label: Label = $Control/VersionLabel

# ==================================================
# CONSTANTS
# ==================================================
const BUTTON_COLORS := {
	"normal": "#3498db",
	"hover": "#2980b9",
	"pressed": "#1c5a7d"
}

# ==================================================
# READY
# ==================================================
func _ready() -> void:
	print("MAIN MENU - _ready() BAŞLADI")
	
	# Kontroller
	print("🔍 Node Kontrolleri:")
	print("  - background:", "✅" if background else "❌")
	print("  - title_label:", "✅" if title_label else "❌")
	print("  - buttons_vbox:", "✅" if buttons_vbox else "❌")
	print("  - Buton sayısı:", buttons_vbox.get_child_count() if buttons_vbox else 0)
	
	# Buton isimlerini yazdır
	if buttons_vbox:
		for i in range(buttons_vbox.get_child_count()):
			var btn = buttons_vbox.get_child(i)
			print("    - Buton", i, ":", btn.name, "(", btn.text, ")")
	
	# Setup fonksiyonları
	_setup_background()
	_setup_buttons()
	
	# Buton bağlantıları
	new_game_btn.pressed.connect(_on_new_game_pressed)
	load_game_btn.pressed.connect(_on_load_game_pressed)
	settings_btn.pressed.connect(_on_settings_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	
	version_label.text = "v1.0 - Survival Shelter"
	
	print("🔄 Animasyon başlatılıyor...")
	_start_entrance_animation()
	print("_ready() tamamlandı")

# ==================================================
# BACKGROUND SETUP
# ==================================================
func _setup_background() -> void:
	"""Arkaplanı ayarla"""
	# Gradient efekti için shader kullanalım
	background.color = Color("#1a2530")  # Koyu mavi-gri
	
	# İsteğe bağlı: Gradient shader ekle
	var material = ShaderMaterial.new()
	var shader = Shader.new()
	shader.code = """
	shader_type canvas_item;
	
	void fragment() {
		// Basit gradient: üstten alta koyulaşan
		float gradient = 1.0 - UV.y * 0.3;
		COLOR = vec4(0.1725, 0.2431, 0.3137, 1.0) * gradient;
	}
	"""
	material.shader = shader
	background.material = material

# ==================================================
# BUTON AYARLARI
# ==================================================
func _setup_buttons() -> void:
	# Tüm butonlara ortak stil uygula
	var buttons := [new_game_btn, load_game_btn, settings_btn, quit_btn]
	
	for button in buttons:
		# Custom minimum size
		button.custom_minimum_size = Vector2(300, 60)
		
		# Font ayarları
		button.add_theme_font_size_override("font_size", 24)
		
		# StyleBox ayarları
		var style_normal = StyleBoxFlat.new()
		style_normal.bg_color = Color(BUTTON_COLORS.normal)
		style_normal.corner_radius_top_left = 10
		style_normal.corner_radius_top_right = 10
		style_normal.corner_radius_bottom_left = 10
		style_normal.corner_radius_bottom_right = 10
		style_normal.border_width_bottom = 3
		style_normal.border_color = Color("#2c3e50")
		
		var style_hover = style_normal.duplicate()
		style_hover.bg_color = Color(BUTTON_COLORS.hover)
		
		var style_pressed = style_normal.duplicate()
		style_pressed.bg_color = Color(BUTTON_COLORS.pressed)
		
		button.add_theme_stylebox_override("normal", style_normal)
		button.add_theme_stylebox_override("hover", style_hover)
		button.add_theme_stylebox_override("pressed", style_pressed)
		
		# Font color
		button.add_theme_color_override("font_color", Color("#ecf0f1"))
		button.add_theme_color_override("font_hover_color", Color("#ffffff"))
		button.add_theme_color_override("font_pressed_color", Color("#bdc3c7"))

# ==================================================
# ANİMASYONLAR
# ==================================================
func _start_entrance_animation() -> void:
	print("🔵 Animasyon başlıyor...")
	if not buttons_vbox or buttons_vbox.get_child_count() == 0:
		_show_all_immediately()
		return
	
	# ⭐ ÖNCE null kontrolü
	if not title_label or not buttons_vbox or not version_label:
		print("❌ UI elementleri bulunamadı!")
		return
	
	# Tüm elementleri görünür yap
	title_label.visible = true
	buttons_vbox.visible = true
	version_label.visible = true
	
	# Başlangıç durumu
	title_label.modulate.a = 0.0
	title_label.position.y += 80
	
	# Butonlar
	for i in range(buttons_vbox.get_child_count()):
		var button = buttons_vbox.get_child(i)
		if button:
			button.modulate.a = 0.0
			button.position.x -= 50
	
	version_label.modulate.a = 0.0
	
	# Kısa bekleme
	await get_tree().process_frame
	
	# ⭐ Tween oluştur ve TWEEPROPERTY EKLE
	var tween = create_tween()
	if not tween:
		print("❌ Tween oluşturulamadı!")
		_show_all_immediately()
		return
	
	# ⭐ MUTLAKA tween_property EKLE
	# 1. Başlık
	tween.tween_property(title_label, "modulate:a", 1.0, 1.5)
	tween.parallel().tween_property(title_label, "position:y", title_label.position.y - 80, 1.5)
	
	# 2. Butonlar (sırayla)
	for i in range(buttons_vbox.get_child_count()):
		var button = buttons_vbox.get_child(i)
		if button:
			var delay = 0.8 + (i * 0.2)
			tween.parallel().tween_property(button, "modulate:a", 1.0, 0.8).set_delay(delay)
			tween.parallel().tween_property(button, "position:x", button.position.x + 50, 0.8).set_delay(delay)
	
	# 3. Version
	tween.parallel().tween_property(version_label, "modulate:a", 0.7, 0.6).set_delay(2.0)
	
	# 7. VERSION LABEL animasyonu
	tween.tween_property(version_label, "modulate:a", 0.7, 0.6) \
		.set_delay(2.0) \
		.set_trans(Tween.TRANS_LINEAR)
	
	# 8. Animasyon bitince
	tween.finished.connect(_on_animation_finished)

func _show_all_immediately() -> void:
	
	title_label.modulate.a = 1.0
	title_label.position.y = title_label.position.y - 80  # Normal pozisyona getir
	
	for i in range(buttons_vbox.get_child_count()):
		var button = buttons_vbox.get_child(i)
		button.modulate.a = 1.0
		button.position.x = button.position.x + 50  # Normal pozisyona getir
	
	version_label.modulate.a = 0.7

func _on_animation_finished() -> void:
	print("🎉 Animasyon tamamlandı!")
	# İsteğe bağlı: animasyon bitince bir şey yap

# ==================================================
# BUTON FONKSİYONLARI
# ==================================================
func _on_new_game_pressed() -> void:
	"""Yeni oyun başlat"""
	print("Yeni oyun başlatılıyor...")
	
	# Save dosyasını temizle
	_delete_save_file()
	
	# GameState'i resetle
	GameState.reset_game()
	
	# Ana sahneyi yükle
	_transition_to_game()

func _on_load_game_pressed() -> void:
	"""Kayıtlı oyunu yükle"""
	print("Oyun yükleniyor...")
	
	# GameState'i bul
	var game_state = get_node("/root/GameState")
	if game_state and game_state.load_game():
		game_state.game_paused = false
		_transition_to_game()
	else:
		# Kayıt yoksa uyarı göster
		print("Kayıtlı oyun bulunamadı!")
		title_label.text = "KAYIT BULUNAMADI!"
		await get_tree().create_timer(1.5).timeout
		title_label.text = "THE RAIN"

func _on_settings_pressed() -> void:
	"""Ayarlar menüsünü aç"""
	print("Ayarlar açılıyor...")
	
	# Basit bir mesaj efekti
	var original_text = settings_btn.text
	settings_btn.text = "YAKINDA!"
	
	await get_tree().create_timer(1.0).timeout
	settings_btn.text = original_text

func _on_quit_pressed() -> void:
	"""Oyundan çık"""
	print("Oyundan çıkılıyor...")
	
	# Butonları devre dışı bırak
	_set_buttons_disabled(true)
	
	var control_node = $Control
	if control_node:
		var tween = create_tween()
		tween.tween_property(control_node, "modulate:a", 0.0, 0.8)
		await tween.finished
	else:
		await get_tree().create_timer(0.8).timeout
	
	# Çıkış
	get_tree().quit()

# ==================================================
# HELPER FUNCTIONS
# ==================================================
func _transition_to_game() -> void:
	"""Ana oyun sahnesine geçiş"""
	print("Oyun sahnesine geçiliyor...")
	
	# Butonları devre dışı bırak
	_set_buttons_disabled(true)
	
	# ⭐ DÜZELTME: CanvasLayer'ın değil, CONTROL'in modulate'ını kullan
	# MainMenu bir CanvasLayer, Control değil
	# Control node'unu bul:
	var control_node = $Control
	if control_node:
		# Fade out animasyonu (Control üzerinde)
		var tween = create_tween()
		tween.tween_property(control_node, "modulate:a", 0.0, 0.8)
		await tween.finished
	else:
		# Fallback: bekle
		await get_tree().create_timer(0.8).timeout
	
	# Ana oyun sahnesini yükle
	get_tree().change_scene_to_file("res://Scenes/Main.tscn")

func _delete_save_file() -> void:
	"""Save dosyasını sil (yeni oyun için)"""
	var save_path = "user://savegame.save"
	if FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
		print("Save dosyası silindi")

func _set_buttons_disabled(disabled: bool) -> void:
	"""Tüm butonları devre dışı bırak/aktif et"""
	new_game_btn.disabled = disabled
	load_game_btn.disabled = disabled
	settings_btn.disabled = disabled
	quit_btn.disabled = disabled
