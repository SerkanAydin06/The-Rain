extends CanvasLayer

# ==================================================
# UI REFERENCES
# ==================================================
@onready var container: Control = $Container
@onready var food_container: Control = $Container/Items/FoodContainer
@onready var medkit_container: Control = $Container/Items/MedkitContainer
@onready var battery_container: Control = $Container/Items/BatteryContainer
@onready var energy_container: Control = $Container/Items/EnergyContainer

@onready var food_icon: Label = $Container/Items/FoodContainer/Icon
@onready var food_amount: Label = $Container/Items/FoodContainer/Amount
@onready var medkit_icon: Label = $Container/Items/MedkitContainer/Icon
@onready var medkit_amount: Label = $Container/Items/MedkitContainer/Amount
@onready var battery_icon: Label = $Container/Items/BatteryContainer/Icon
@onready var battery_amount: Label = $Container/Items/BatteryContainer/Amount
@onready var energy_icon: Label = $Container/Items/EnergyContainer/Icon
@onready var energy_amount: Label = $Container/Items/EnergyContainer/Amount

# ==================================================
# CONFIGURATION
# ==================================================
@export_category("Display Settings")
@export var panel_width: int = 180
@export var panel_height: int = 70
@export var item_spacing: int = 15
@export var update_interval: float = 0.3

@export_category("Visual Settings")
@export var bg_color: Color = Color(0.08, 0.1, 0.15, 0.92)
@export var border_color: Color = Color(0.3, 0.7, 1.0, 0.8)
@export var glow_color: Color = Color(0.5, 0.8, 1.0, 0.3)
@export var icon_size: int = 24
@export var amount_size: int = 18

@export_category("Color Thresholds")
@export var critical_color: Color = Color(1.0, 0.3, 0.3)      # Kırmızı
@export var low_color: Color = Color(1.0, 0.8, 0.3)          # Turuncu
@export var normal_color: Color = Color(0.4, 1.0, 0.4)       # Yeşil
@export var empty_color: Color = Color(0.6, 0.6, 0.6, 0.7)   # Gri

# ==================================================
# RUNTIME VARIABLES
# ==================================================
var update_timer: float = 0.0
var current_values: Dictionary = {}
var previous_values: Dictionary = {}
var pulse_tweens: Array = []

# Item kritik limitleri
var critical_limits = {
	"food": 2,
	"medkit": 1,
	"battery": 1,
	"energy_drink": 1
}

var low_limits = {
	"food": 5,
	"medkit": 2,
	"battery": 3,
	"energy_drink": 3
}

# ==================================================
# READY
# ==================================================
func _ready() -> void:
	print("🎯 PROFESYONEL Tüketilebilirler HUD hazırlanıyor...")
	
	# DEBUG: Node kontrolü
	_debug_check_nodes()
	
	# Konum ve stil ayarla
	_setup_display()
	
	# Signal bağlantıları
	_connect_signals()
	
	# İlk değerleri kaydet
	_save_current_values()
	
	# İlk güncelleme
	update_display(true)
	
	print("✅ Tüketilebilirler HUD hazır (Profesyonel)")

# ==================================================
# SETUP FUNCTIONS
# ==================================================
func _debug_check_nodes() -> void:
	var nodes = {
		"Container": container,
		"Food Container": food_container,
		"Medkit Container": medkit_container,
		"Battery Container": battery_container,
		"Energy Container": energy_container
	}
	
	print("🔍 Node Kontrolü:")
	for node_name in nodes:
		var node = nodes[node_name]
		print("   - %s: %s" % [name, "✅" if node else "❌"])

func _setup_display() -> void:
	if not container:
		push_error("❌ Container bulunamadı!")
		return
	
	# Sağ üst köşeye anchor'la
	container.anchor_left = 1.0
	container.anchor_right = 1.0
	container.anchor_top = 0.0
	container.anchor_bottom = 0.0
	
	# Pozisyon ve boyut
	container.offset_left = -panel_width
	container.offset_top = 20
	container.custom_minimum_size = Vector2(panel_width, panel_height)
	
	print("📐 Display ayarlandı: %dx%d" % [panel_width, panel_height])

# ==================================================
# SIGNAL CONNECTIONS
# ==================================================
func _connect_signals() -> void:
	# GameState
	if GameState:
		if GameState.inventory_changed.is_connected(_on_inventory_changed):
			GameState.inventory_changed.disconnect(_on_inventory_changed)
		GameState.inventory_changed.connect(_on_inventory_changed)
		print("📡 GameState signal bağlandı")
	
	# Viewport size değişikliği
	get_viewport().size_changed.connect(_on_viewport_resized)
	
	# Mouse events (opsiyonel - tıklanabilir yapmak için)
	_setup_mouse_events()

func _setup_mouse_events() -> void:
	var items = [
		{"node": food_container, "type": "food", "name": "🥫 Yiyecek"},
		{"node": medkit_container, "type": "medkit", "name": "🩹 Medkit"},
		{"node": battery_container, "type": "battery", "name": "🔋 Pil"},
		{"node": energy_container, "type": "energy_drink", "name": "🥤 Enerji İçeceği"}
	]
	
	for item in items:
		if item["node"]:
			item["node"].mouse_filter = Control.MOUSE_FILTER_STOP
			# ⭐ DÜZELTME: Godot 4'te Callable kullan
			item["node"].gui_input.connect(Callable(self, "_on_item_gui_input").bind(item["type"], item["name"]))

# ==================================================
# UPDATE FUNCTIONS
# ==================================================
func _process(delta: float) -> void:
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		update_display(false)

func update_display(force_update: bool = false) -> void:
	if not _validate_nodes():
		return
	
	# Değerleri al
	var new_values = {
		"food": GameState.inventory.get("food", 0),
		"medkit": GameState.inventory.get("medkit", 0),
		"battery": GameState.inventory.get("battery", 0),
		"energy_drink": GameState.inventory.get("energy_drink", 0)
	}
	
	# Değişiklik var mı kontrol et
	var has_changes = force_update
	for key in new_values:
		if new_values[key] != current_values.get(key, -1):
			has_changes = true
			break
	
	if not has_changes:
		return  # Değişiklik yok, güncelleme yapma
	
	# Değerleri kaydet
	previous_values = current_values.duplicate()
	current_values = new_values.duplicate()
	
	# Her item'i güncelle
	_update_item_display("food", food_icon, food_amount, current_values["food"])
	_update_item_display("medkit", medkit_icon, medkit_amount, current_values["medkit"])
	_update_item_display("battery", battery_icon, battery_amount, current_values["battery"])
	_update_item_display("energy_drink", energy_icon, energy_amount, current_values["energy_drink"])
	
	# Debug log
	_log_changes()

func _update_item_display(item_type: String, icon_label: Label, amount_label: Label, amount: int) -> void:
	if not icon_label or not amount_label:
		return
	
	# Icon'u ayarla
	icon_label.text = _get_item_icon(item_type)
	icon_label.add_theme_font_size_override("font_size", icon_size)
	
	# Miktarı ayarla
	amount_label.text = "×%d" % amount
	amount_label.add_theme_font_size_override("font_size", amount_size)
	
	# Renk ve efektleri uygula
	var color = _get_amount_color(item_type, amount)
	var is_critical = amount <= critical_limits[item_type]
	var is_low = amount <= low_limits[item_type]
	var previous_amount = previous_values.get(item_type, amount)
	
	# Icon rengi
	icon_label.add_theme_color_override("font_color", color)
	if is_critical:
		icon_label.add_theme_constant_override("outline_size", 2)
	else:
		icon_label.add_theme_constant_override("outline_size", 1)
	icon_label.add_theme_color_override("font_outline_color", Color.BLACK)
	
	# Miktar rengi
	amount_label.add_theme_color_override("font_color", color)
	amount_label.add_theme_constant_override("outline_size", 1)
	amount_label.add_theme_color_override("font_outline_color", Color.BLACK)
	
	# Efektler
	if amount < previous_amount:
		_play_decrease_effect(icon_label)  # Azaldıysa efekt
	elif is_critical:
		_play_critical_effect(icon_label)  # Kritikse pulsating
	elif is_low:
		_play_low_effect(icon_label)       # Azsa titreşim

func _get_amount_color(item_type: String, amount: int) -> Color:
	if amount <= 0:
		return empty_color
	elif amount <= critical_limits[item_type]:
		return critical_color
	elif amount <= low_limits[item_type]:
		return low_color
	else:
		return normal_color

func _get_item_icon(item_type: String) -> String:
	match item_type:
		"food": return "🥫"
		"medkit": return "🩹"
		"battery": return "🔋"
		"energy_drink": return "🥤"
		_: return "❓"

# ==================================================
# VISUAL EFFECTS
# ==================================================
func _play_critical_effect(node: Control) -> void:
	if not node:
		return
	
	# Eski tween'leri temizle
	for tween in pulse_tweens:
		if tween and tween.is_valid():
			tween.kill()
	pulse_tweens.clear()
	
	# Pulsating efekti
	var tween = create_tween()
	tween.set_loops()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(node, "scale", Vector2(1.15, 1.15), 0.6)
	tween.tween_property(node, "scale", Vector2(1.0, 1.0), 0.6)
	
	pulse_tweens.append(tween)

func _play_low_effect(node: Control) -> void:
	if not node:
		return
	
	var tween = create_tween()
	tween.set_loops(2)
	tween.tween_property(node, "position:y", node.position.y - 2, 0.1)
	tween.tween_property(node, "position:y", node.position.y, 0.1)

func _play_decrease_effect(node: Control) -> void:
	if not node:
		return
	
	var original_color: Color
	if node is Label:
		original_color = node.get_theme_color("font_color")
	else:
		original_color = Color.WHITE
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	if node is Label:
		tween.tween_property(node, "theme_override_colors/font_color", Color.RED, 0.1)
		tween.tween_property(node, "scale", Vector2(1.2, 1.2), 0.1)
	
	tween.tween_property(node, "theme_override_colors/font_color", original_color, 0.3).set_delay(0.1)
	tween.tween_property(node, "scale", Vector2(1.0, 1.0), 0.3).set_delay(0.1)

func _play_increase_effect(node: Control) -> void:
	if not node:
		return
	
	var original_color: Color
	if node is Label:
		original_color = node.get_theme_color("font_color")
	else:
		original_color = Color.WHITE
	
	var tween = create_tween()
	tween.set_parallel(true)
	
	if node is Label:
		tween.tween_property(node, "theme_override_colors/font_color", Color.GREEN, 0.1)
		tween.tween_property(node, "scale", Vector2(1.2, 1.2), 0.1)
	
	tween.tween_property(node, "theme_override_colors/font_color", original_color, 0.3).set_delay(0.1)
	tween.tween_property(node, "scale", Vector2(1.0, 1.0), 0.3).set_delay(0.1)

# ==================================================
# HELPER FUNCTIONS
# ==================================================
func _validate_nodes() -> bool:
	if not GameState or not GameState.inventory:
		return false
	
	var required_nodes = [container, food_icon, food_amount, medkit_icon, medkit_amount,
						 battery_icon, battery_amount, energy_icon, energy_amount]
	
	for node in required_nodes:
		if not node:
			return false
	
	return true

func _save_current_values() -> void:
	current_values = {
		"food": GameState.inventory.get("food", 0),
		"medkit": GameState.inventory.get("medkit", 0),
		"battery": GameState.inventory.get("battery", 0),
		"energy_drink": GameState.inventory.get("energy_drink", 0)
	}
	previous_values = current_values.duplicate()

func _log_changes() -> void:
	var log_text = "📊 Tüketilebilirler: "
	var items = ["food", "medkit", "battery", "energy_drink"]
	
	for item in items:
		var current = current_values.get(item, 0)
		var previous = previous_values.get(item, current)
		
		if current != previous:
			log_text += "%s: %d→%d " % [item, previous, current]
		else:
			log_text += "%s: %d " % [item, current]
	
	print(log_text)

# ==================================================
# SIGNAL HANDLERS
# ==================================================
func _on_inventory_changed() -> void:
	update_display(true)

func _on_viewport_resized() -> void:
	print("🔄 Viewport boyutu değişti: %s" % str(get_viewport().size))
	_setup_display()

func _on_item_gui_input(event: InputEvent, item_type: String, item_name: String) -> void:
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			print("🖱️ %s kullanılıyor..." % item_name)
			_play_click_effect(item_type)
			
			var player = get_tree().get_first_node_in_group("player")
			if player and player.has_method("use_consumable"):
				player.use_consumable(item_type)

func _play_click_effect(item_type: String) -> void:
	var container_node = null
	match item_type:
		"food": container_node = food_container
		"medkit": container_node = medkit_container
		"battery": container_node = battery_container
		"energy_drink": container_node = energy_container
	
	if container_node:
		var tween = create_tween()
		tween.tween_property(container_node, "scale", Vector2(0.9, 0.9), 0.05)
		tween.tween_property(container_node, "scale", Vector2(1.0, 1.0), 0.1)

# ==================================================
# PUBLIC API
# ==================================================
func show_hud() -> void:
	if container:
		container.visible = true
		print("👁️ Tüketilebilirler HUD gösterildi")

func hide_hud() -> void:
	if container:
		container.visible = false
		print("👁️ Tüketilebilirler HUD gizlendi")

func toggle_hud() -> void:
	if container:
		container.visible = !container.visible
		print("👁️ Tüketilebilirler HUD: %s" % ("Gösterildi" if container.visible else "Gizlendi"))

func set_opacity(opacity: float) -> void:
	if container:
		container.modulate.a = clamp(opacity, 0.0, 1.0)

# ==================================================
# DEBUG FUNCTIONS
# ==================================================
func debug_simulate_change() -> void:
	print("🔧 DEBUG: Değişiklik simüle ediliyor...")
	
	# Rastgele değerler
	current_values["food"] = randi_range(0, 10)
	current_values["medkit"] = randi_range(0, 5)
	current_values["battery"] = randi_range(0, 8)
	current_values["energy_drink"] = randi_range(0, 6)
	
	update_display(true)

func debug_print_status() -> void:
	print("\n=== TÜKETİLEBİLİRLER HUD DEBUG ===")
	print("Panel Boyutu: %dx%d" % [panel_width, panel_height])
	print("Güncelleme Aralığı: %.1fs" % update_interval)
	print("Mevcut Değerler:")
	print("  🥫 Yiyecek: %d" % current_values.get("food", 0))
	print("  🩹 Medkit: %d" % current_values.get("medkit", 0))
	print("  🔋 Pil: %d" % current_values.get("battery", 0))
	print("  🥤 Enerji: %d" % current_values.get("energy_drink", 0))
	print("Container Görünür: %s" % ("✅" if container and container.visible else "❌"))
	print("===============================\n")
