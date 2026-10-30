# GlobalHintManager.gd
extends Node

# Singleton/autoload olacak

# Font değişkeni
var hint_font: Font

func _ready():
	print("=== GLOBAL HINT MANAGER BAŞLATILDI ===")
	print("Path: /root/GlobalHintManager")
	
	# Font yükle (opsiyonel - kendi font'unu kullanmak istersen)
	# _load_custom_font()
 # GlobalHintManager.gd'de setup_hint_label() fonksiyonunu DÜZELT:

func setup_hint_label(label: Label) -> void:
	if not label or not is_instance_valid(label):
		print("⚠️ GlobalHintManager: Geçersiz label")
		return
	
	# ⭐ NULL KONTROLÜ EKLE
	if not label.get_parent():
		print("⚠️ GlobalHintManager: Label'ın parent'ı yok - ", label.name if label.name else "isimsiz")
		return
	
	print("GlobalHintManager: ", label.name, " (", label.get_parent().name, ") stil uygulanıyor")
	
	# ⭐ ÖNCE TÜM AYARLARI SIFIRLA
	label.scale = Vector2(1, 1)
	label.custom_minimum_size = Vector2.ZERO
	
	# Font ayarları (HEPSİ AYNI)
	label.add_theme_font_size_override("font_size", 18)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_constant_override("outline_size", 2)
	label.add_theme_color_override("font_outline_color", Color.BLACK)
	
	# ⭐ YENİ: Tüm label'lara SABIT BÜYÜKLÜK
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	# ⭐ DEBUG: Label bilgilerini yazdır
	print("  - Text: '", label.text, "'")
	print("  - Size: ", label.size)
	print("  - Scale: ", label.scale)
	print("  - Position: ", label.position)

func _load_custom_font():
	"""Özel font yükle (isteğe bağlı)"""
	var font_path = "res://Fonts/Roboto-Bold.ttf"
	if FileAccess.file_exists(font_path):
		hint_font = load(font_path)
		if hint_font:
			print("GlobalHintManager: Özel font yüklendi")
	else:
		print("GlobalHintManager: Özel font bulunamadı, varsayılan kullanılacak")

# Oyun içinde font size değiştirmek için yardımcı fonksiyon
func set_global_font_size(size: int) -> void:
	"""Tüm hint'lerin font size'ını değiştir"""
	print("GlobalHintManager: Font size değiştiriliyor: ", size)
	# Bu fonksiyonu kullanmak için her label'ı takip etmen gerekir
	# Daha gelişmiş bir sistem kurulabilir
