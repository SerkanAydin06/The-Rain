# RightSideInventory.gd - DÜZELTİLMİŞ VERSİYON
extends CanvasLayer

# UI References
@onready var container: Control = $Control
@onready var items_container: VBoxContainer = $Control/ScrollContainer/VBoxContainer
@onready var scroll_container: ScrollContainer = $Control/ScrollContainer

# Configuration
@export var panel_width: int = 280
@export var item_height: int = 32
@export var animation_speed: float = 0.2  # ⭐ EKLENDİ

var inventory_visible: bool = true
var is_animating: bool = false
var original_offset: float = -280  # ⭐ EKLENDİ - panel_width ile aynı

func _ready() -> void:
	print("📋 Sağ Envanter Panel hazırlanıyor...")
	
	# DEBUG: Node kontrolü
	print("   - Container:", "✅" if container else "❌")
	print("   - Items Container:", "✅" if items_container else "❌")
	print("   - Scroll Container:", "✅" if scroll_container else "❌")
	
	original_offset = -10
	
	# Panel konumunu ayarla
	_setup_panel_position()
	
	# Stil uygula
	_apply_panel_style()
	
	# Signal bağlantıları
	_connect_signals()
	
	hide_inventory_immediately()
	
	update_display()
	
	print("✅ Sağ Envanter Panel hazır (TAB ile aç/kapa)")

func hide_inventory_immediately() -> void:
	if not container:
		return
	
	print("📦 Envanter başlangıçta gizleniyor...")
	
	inventory_visible = false
	
	container.offset_left = -panel_width
	container.visible = false
	
	print("   - offset_left: ", container.offset_left)
	print("   - visible: ", container.visible)

func _setup_panel_position() -> void:
	if not container:
		return
	
	print("📐 Panel konumu ayarlanıyor...")
	
	# Anchor'ları sağ üst köşeye ayarla
	container.anchor_left = 1.0
	container.anchor_right = 1.0
	container.anchor_top = 0.0
	container.anchor_bottom = 1.0
	
	container.offset_left = -panel_width  # Başlangıçta EKRAN DIŞINDA
	container.offset_right = 0           # Sağ kenar
	container.offset_top = 80            # Üstten boşluk
	container.offset_bottom = -50        # Alttan boşluk
	
	# Panel boyutu
	container.custom_minimum_size = Vector2(panel_width, 0)
	
	container.visible = false
	
	print("   - Panel width: ", panel_width)
	print("   - Offset left: ", container.offset_left)
	print("   - Visible: ", container.visible)

func _apply_panel_style() -> void:
	"""Panel stili uygula"""
	if not container:
		return
	
	# Arkaplan stili
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.1, 0.12, 0.95)  # Yarı saydam koyu
	style.border_width_left = 3
	style.border_color = Color(0.9, 0.6, 0.2, 0.8)
	style.corner_radius_top_left = 10
	style.corner_radius_bottom_left = 10
	style.shadow_color = Color(0, 0, 0, 0.6)
	style.shadow_size = 10
	style.shadow_offset = Vector2(-4, 0)  # Sola gölge
	
	container.add_theme_stylebox_override("panel", style)

func _connect_signals() -> void:
	"""Gerekli sinyal bağlantılarını yap"""
	# GameState
	if GameState and not GameState.inventory_changed.is_connected(update_display):
		GameState.inventory_changed.connect(update_display)
	
	print("📡 Signal bağlantıları kuruldu")

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		toggle_inventory()
		get_viewport().set_input_as_handled()

func toggle_inventory() -> void:
	if is_animating:
		return
	
	var currently_visible = container.visible if container else false
	
	print("🔄 Envanter toggle: %s -> %s" % [
		"AÇIK" if is_visible else "KAPALI",
		"KAPANACAK" if is_visible else "AÇILACAK"
	])
	print("   Mevcut offset: %d, Panel genişliği: %d" % [container.offset_left, panel_width])
	
	if currently_visible:
		hide_inventory()
	else:
		show_inventory()

func show_inventory() -> void:
	if is_animating or not container:
		return
	
	if container.visible:
		print("⚠️ Panel zaten açık, iptal")
		return
	
	print("📂 Envanter açılıyor...")
	inventory_visible = true
	is_animating = true
	
	container.visible = true
	container.modulate.a = 1.0
	
	# Animasyon başlangıç pozisyonu (sağda gizli)
	container.offset_left = -panel_width  # Ekran dışında başla
	
	# Tween animasyonu (slide in)
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	# Hedef offset (ekran kenarında)
	tween.tween_property(container, "offset_left", original_offset, animation_speed)
	tween.tween_callback(_on_show_animation_finished)
	
	print("   Animasyon başladı: %d -> %d" % [-panel_width, original_offset])

func _on_show_animation_finished() -> void:
	is_animating = false
	print("✅ Envanter açıldı (offset: %d, visible: %s)" % [container.offset_left, container.visible])

func hide_inventory() -> void:
	if is_animating or not container:
		return
	
	if not container.visible:
		print("⚠️ Panel zaten kapalı, iptal")
		return
	
	print("📂 Envanter kapanıyor...")
	inventory_visible = false
	is_animating = true
	
	var tween = create_tween()
	tween.set_ease(Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_CUBIC)
	
	tween.tween_property(container, "offset_left", -panel_width, animation_speed)
	tween.tween_callback(_on_hide_animation_finished)
	
	print("   Animasyon başladı: %d -> %d" % [container.offset_left, -panel_width])

func _on_hide_animation_finished() -> void:
	is_animating = false
	
	if container:
		container.visible = false
		print("✅ Envanter kapandı ve GİZLENDİ")
		print("   - offset_left: %d" % container.offset_left)
		print("   - visible: %s" % container.visible)
	else:
		print("✅ Envanter kapandı (container null)")

func update_display() -> void:
	if not items_container:
		return
	
	# Önceki öğeleri temizle
	for child in items_container.get_children():
		child.queue_free()
	
	# Başlık ekle
	var title = Label.new()
	title.text = "📦 MATERYALLER"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))
	items_container.add_child(title)
	
	# Ayırıcı
	_add_separator()
	
	# 0. SU
	_add_category_title("💧 SU")
	var water_grid = GridContainer.new()
	water_grid.columns = 4
	water_grid.custom_minimum_size = Vector2(0, 60)
	for item_id in ["water", "dirty_water"]:
		water_grid.add_child(_create_material_box(item_id, GameState.inventory.get(item_id, 0), "consumable"))
	items_container.add_child(water_grid)
	
	_add_separator()
	
	# 1. MALZEMELER KATEGORİSİ
	_add_category_title("🛠️ MALZEMELER")
	
	# TEMEL MALZEMELER
	_add_subcategory_title("Basit:")
	var basic_grid = GridContainer.new()
	basic_grid.columns = 4
	basic_grid.custom_minimum_size = Vector2(0, 60)
	
	var basic_materials = ["wood", "stone", "scrap", "cloth"]
	for item_id in basic_materials:
		var amount = GameState.inventory.get(item_id, 0)
		basic_grid.add_child(_create_material_box(item_id, amount, "basic"))
	
	items_container.add_child(basic_grid)
	
	# ORTA MALZEMELER
	_add_subcategory_title("Orta:")
	var medium_grid = GridContainer.new()
	medium_grid.columns = 4
	medium_grid.custom_minimum_size = Vector2(0, 60)
	
	var medium_materials = ["wire", "plastic", "metal", "chemical"]
	for item_id in medium_materials:
		var amount = GameState.inventory.get(item_id, 0)
		medium_grid.add_child(_create_material_box(item_id, amount, "medium"))
	
	items_container.add_child(medium_grid)
	
	# NADİR MALZEMELER
	_add_subcategory_title("Nadir:")
	var rare_grid = GridContainer.new()
	rare_grid.columns = 4
	rare_grid.custom_minimum_size = Vector2(0, 60)
	
	var rare_materials = ["electronic", "fuel", "medicine", "component"]
	for item_id in rare_materials:
		var amount = GameState.inventory.get(item_id, 0)
		rare_grid.add_child(_create_material_box(item_id, amount, "rare"))
	
	items_container.add_child(rare_grid)
	
	_add_separator()
	
	# 2. CRAFT EDİLMİŞ ÜRÜNLER
	_add_category_title("⚒️ CRAFT EDİLMİŞ")
	
	var crafted_grid = GridContainer.new()
	crafted_grid.columns = 4
	crafted_grid.custom_minimum_size = Vector2(0, 60)
	
	var crafted_items = ["medkit_crafted", "battery_crafted", "toolkit", "radio_part"]
	for item_id in crafted_items:
		var amount = GameState.inventory.get(item_id, 0)
		crafted_grid.add_child(_create_material_box(item_id, amount, "crafted"))
	
	items_container.add_child(crafted_grid)

func _create_material_box(item_id: String, amount: int, category: String) -> Control:
	var box = Control.new()
	box.custom_minimum_size = Vector2(60, 60)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	
	# Icon/Emoji
	var icon = Label.new()
	icon.text = _get_item_emoji(item_id)
	icon.add_theme_font_size_override("font_size", 24)
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Miktar
	var amount_label = Label.new()
	amount_label.text = "×%d" % amount
	amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Renk
	var color = _get_category_color(category)
	if amount == 0:
		color = color * Color(0.3, 0.3, 0.3, 1.0)  # Soluk
	
	icon.add_theme_color_override("font_color", color)
	amount_label.add_theme_color_override("font_color", color)
	
	vbox.add_child(icon)
	vbox.add_child(amount_label)
	box.add_child(vbox)
	
	return box

func _get_item_emoji(item_id: String) -> String:
	match item_id:
		"water": return "💧"
		"dirty_water": return "🟤"
		"wood": return "🪵"
		"stone": return "🪨"
		"scrap": return "🔩"
		"cloth": return "🧵"
		"wire": return "🔌"
		"plastic": return "🥤"
		"metal": return "⚙️"
		"chemical": return "🧪"
		"electronic": return "💻"
		"fuel": return "⛽"
		"medicine": return "💊"
		"component": return "⚡"
		"medkit_crafted": return "🩹"
		"battery_crafted": return "🔋"
		"toolkit": return "🧰"
		"radio_part": return "📡"
		_: return "📦"

# YARDIMCI FONKSİYONLAR
func _get_item_category(item_id: String) -> String:
	"""Item'ın kategorisini döndür"""
	match item_id:
		"food", "medkit", "battery", "energy_drink":
			return "consumable"
		"medkit_crafted", "battery_crafted", "toolkit", "radio_part":
			return "crafted"
		_:
			return "material"

func _add_category_title(text: String) -> void:
	"""Kategori başlığı ekle"""
	var title = Label.new()
	title.text = text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.add_theme_font_size_override("font_size", 16)
	title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	title.add_theme_constant_override("outline_size", 1)
	title.add_theme_color_override("font_outline_color", Color.BLACK)
	title.custom_minimum_size = Vector2(0, 30)
	items_container.add_child(title)

func _add_subcategory_title(text: String) -> void:
	"""Alt kategori başlığı ekle"""
	var title = Label.new()
	title.text = text
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	title.custom_minimum_size = Vector2(0, 25)
	items_container.add_child(title)

func _add_item_row(item_id: String, amount: int, category: String = "") -> void:
	"""Item satırı ekle (0 miktarda bile göster)"""
	var hbox = HBoxContainer.new()
	hbox.custom_minimum_size = Vector2(0, 28)
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Item ismi (sol)
	var name_label = Label.new()
	name_label.text = _get_item_display_name(item_id)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_constant_override("outline_size", 1)
	name_label.add_theme_color_override("font_outline_color", Color.BLACK)
	
	# Kategoriye göre renk (0 miktarda bile)
	var name_color = _get_category_color(category)
	name_label.add_theme_color_override("font_color", name_color)
	
	# Miktar (sağ) - HER ZAMAN GÖSTER
	var amount_label = Label.new()
	amount_label.text = "×%d" % amount
	amount_label.custom_minimum_size = Vector2(45, 0)
	amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	amount_label.add_theme_font_size_override("font_size", 14)
	amount_label.add_theme_constant_override("outline_size", 1)
	amount_label.add_theme_color_override("font_outline_color", Color.BLACK)
	
	# Miktara ve kategoriye göre renk (0 için özel renk)
	var amount_color = _get_amount_color_with_zero(amount, category)
	amount_label.add_theme_color_override("font_color", amount_color)
	
	# Eğer miktar 0 ise, item ismini soluk göster
	if amount == 0:
		name_label.add_theme_color_override("font_color", name_color * Color(0.5, 0.5, 0.5, 1.0))
	
	hbox.add_child(name_label)
	hbox.add_child(amount_label)
	items_container.add_child(hbox)

func _get_amount_color_with_zero(amount: int, category: String) -> Color:
	"""Miktara göre renk döndür (0 için özel renk)"""
	if amount == 0:
		# 0 miktar için kategoriye özel soluk renk
		match category:
			"consumable": return Color(0.9, 0.5, 0.5) * Color(0.5, 0.5, 0.5, 1.0)  # Soluk kırmızı
			"material_basic": return Color(0.8, 0.8, 0.8) * Color(0.5, 0.5, 0.5, 1.0)  # Soluk gri
			"material_medium": return Color(0.6, 0.8, 1.0) * Color(0.5, 0.5, 0.5, 1.0)  # Soluk mavi
			"material_rare": return Color(0.8, 0.6, 1.0) * Color(0.5, 0.5, 0.5, 1.0)  # Soluk mor
			"crafted": return Color(0.8, 1.0, 0.6) * Color(0.5, 0.5, 0.5, 1.0)  # Soluk yeşil
			_: return Color(0.7, 0.7, 0.7)  # Varsayılan gri
	
	# Normal miktar renkleri (yukarıdaki _get_amount_color fonksiyonundan)
	return _get_amount_color(amount, category)

func _get_amount_color(amount: int, category: String) -> Color:
	"""Miktara ve kategoriye göre renk döndür (0 hariç)"""
	# Kritik seviyeler kategoriye göre değişir
	var critical = 1
	var low = 3
	var medium = 10
	
	match category:
		"consumable":
			critical = 1
			low = 2
			medium = 5
		"material_basic":
			critical = 3
			low = 10
			medium = 25
		"material_medium", "material_rare":
			critical = 1
			low = 3
			medium = 8
		"crafted":
			critical = 0  # Craft edilmiş her zaman değerli
			low = 1
			medium = 2
	
	if amount <= critical:
		return Color(1, 0.3, 0.3)      # Kırmızı - kritik
	elif amount <= low:
		return Color(1, 0.8, 0.3)      # Turuncu - az
	elif amount <= medium:
		return Color(0.8, 1.0, 0.3)    # Sarı-yeşil - orta
	else:
		return Color(0.4, 1.0, 0.4)    # Yeşil - çok

func _get_item_display_name(item_id: String) -> String:
	"""Item ID'den görüntülenecek isim"""
	var display_names = {
		# Tüketilebilirler
		"food": "🥫 Konserve",
		"medkit": "🩹 Medkit",
		"battery": "🔋 Pil",
		"energy_drink": "🥤 Enerji İçeceği",
		
		# Temel malzemeler
		"wood": "🪵 Ahşap",
		"stone": "🪨 Taş",
		"scrap": "🔩 Hurda",
		"cloth": "🧵 Kumaş",
		
		# Orta malzemeler
		"wire": "🔌 Tel",
		"plastic": "🥤 Plastik",
		"metal": "⚙️ Metal",
		"chemical": "🧪 Kimyasal",
		
		# Nadir malzemeler
		"electronic": "💻 Elektronik",
		"fuel": "⛽ Yakıt",
		"medicine": "💊 İlaç",
		"component": "⚡ Parça",
		
		"water": "💧 Temiz Su",
		"dirty_water": "🟤 Kirli Su",
		
		# Craft edilmiş
		"medkit_crafted": "🩹 Yapay Medkit",
		"battery_crafted": "🔋 Şarj Edilebilir Pil",
		"toolkit": "🧰 Alet Çantası",
		"radio_part": "📡 Radyo Parçası",
	}
	
	return display_names.get(item_id, "❓ " + item_id.capitalize())

func _get_category_color(category: String) -> Color:
	"""Kategoriye göre renk döndür"""
	match category:
		"consumable": return Color(0.9, 0.5, 0.5)      # Açık kırmızı
		"material_basic": return Color(0.8, 0.8, 0.8)  # Açık gri
		"material_medium": return Color(0.6, 0.8, 1.0) # Açık mavi
		"material_rare": return Color(0.8, 0.6, 1.0)   # Açık mor
		"crafted": return Color(0.8, 1.0, 0.6)         # Açık yeşil
		_: return Color.WHITE

func _count_total_items_with_amount() -> int:
	"""Miktarı 0'dan büyük olan item sayısını hesapla"""
	var count = 0
	for item_id in GameState.inventory:
		if GameState.inventory[item_id] > 0:
			count += 1
	return count

func _add_separator() -> void:
	"""Ayırıcı çizgi ekle"""
	var separator = HSeparator.new()
	separator.add_theme_color_override("color", Color(0.5, 0.5, 0.5, 0.3))
	separator.custom_minimum_size = Vector2(0, 1)
	items_container.add_child(separator)

func _count_total_items() -> int:
	"""Toplam item sayısını hesapla (0'dan büyük olanlar)"""
	var count = 0
	for item_id in GameState.inventory:
		if GameState.inventory[item_id] > 0:
			count += 1
	return count

func _on_sort_button_pressed() -> void:
	update_display()

# Opsiyonel: Filtreleme için
func show_only_essential() -> void:
	# Bu fonksiyonu bir butona bağlayabilirsiniz
	pass

func show_all_items() -> void:
	update_display()
