extends CanvasLayer

# SIGNALS
signal panel_closed
signal crafting_started(item_name: String, time: float)
signal crafting_updated(progress: float)

# UI REFERENCES
@onready var background: ColorRect
@onready var main_panel: Panel
@onready var title_label: Label
@onready var recipe_template: Panel
# Tier Butonları
@onready var tier1_btn: Button
@onready var tier2_btn: Button
@onready var tier3_btn: Button

# Category Butonları
@onready var all_btn: Button
@onready var medical_btn: Button
@onready var electronic_btn: Button
@onready var mechanical_btn: Button

# Recipe Container
@onready var recipes_container: VBoxContainer
@onready var close_btn: Button

# Progress Elements
@onready var progress_container: VBoxContainer
@onready var progress_bar: ProgressBar
@onready var progress_label: Label
@onready var cancel_btn: Button

# STATE VARIABLES
var panel_visible: bool = false
var workbench_tier: int = 1
var selected_tier: int = 1
var selected_category: String = "all"
var current_crafting_item: String = ""
var is_crafting_in_progress: bool = false

# COLOR SETTINGS
@export_category("Color Settings")
@export var tier1_color: Color = Color(0.4, 0.7, 1.0)
@export var tier2_color: Color = Color(0.6, 0.4, 1.0)
@export var tier3_color: Color = Color(1.0, 0.6, 0.2)
@export var medical_color: Color = Color(0.9, 0.3, 0.3)
@export var electronic_color: Color = Color(0.3, 0.7, 0.9)
@export var mechanical_color: Color = Color(0.3, 0.9, 0.5)

func _ready() -> void:
	print("🛠️ CraftingPanel _ready() başladı")
	_get_all_references()
	
	# ⭐⭐ ÖNEMLİ: Template'i BUL ve GİZLE
	if recipes_container:
		recipe_template = recipes_container.get_node("RecipeTemplate") as Panel
		if recipe_template:
			print("✅ RecipeTemplate bulundu, gizleniyor...")
			recipe_template.visible = false  # Template'i gizli tut
			recipe_template.name = "RecipeTemplate"  # İsmini sabitle
		else:
			print("❌ RecipeTemplate bulunamadı! Scene'de olmalı.")
	
	if recipes_container:
		recipes_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		recipes_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
		recipes_container.add_theme_constant_override("separation", 15)
	
	hide_panel_immediately()
	_connect_signals()
	print("✅ CraftingPanel hazır")

func _get_all_references() -> void:
	print("🔍 CraftingPanel referansları alınıyor...")
	
	# Basit versiyon - her node'u tek tek al
	main_panel = $Control/MainPanel
	
	if main_panel:
		title_label = main_panel.get_node("TitleLabel") as Label
		close_btn = main_panel.get_node("CloseBtn") as Button
		
		# Tier butonları
		var tier_tabs = main_panel.get_node("TierTabs") as HBoxContainer
		if tier_tabs:
			tier1_btn = tier_tabs.get_node("Tier1Btn") as Button
			tier2_btn = tier_tabs.get_node("Tier2Btn") as Button
			tier3_btn = tier_tabs.get_node("Tier3Btn") as Button
		
		# Category butonları
		var category_tabs = main_panel.get_node("CategoryTabs") as VBoxContainer
		if category_tabs:
			all_btn = category_tabs.get_node("AllBtn") as Button
			medical_btn = category_tabs.get_node("MedicalBtn") as Button
			electronic_btn = category_tabs.get_node("ElectronicBtn") as Button
			mechanical_btn = category_tabs.get_node("MechanicalBtn") as Button
		
		# Recipe container
		var recipes_scroll = main_panel.get_node("RecipesScroll") as ScrollContainer
		if recipes_scroll:
			recipes_container = recipes_scroll.get_node("RecipesVBox") as VBoxContainer
		
		# Progress container
		progress_container = main_panel.get_node("ProgressContainer") as VBoxContainer
		if progress_container:
			progress_bar = progress_container.get_node("ProgressBar") as ProgressBar
			progress_label = progress_container.get_node("ProgressLabel") as Label
			cancel_btn = progress_container.get_node("CancelBtn") as Button
		
		print("✅ Referanslar alındı")
	else:
		push_error("❌ MainPanel bulunamadı!")

func _connect_signals() -> void:
	print("🔗 Sinyal bağlantıları kuruluyor...")
	
	if tier1_btn:
		tier1_btn.pressed.connect(_on_tier1_pressed)
		print("  - tier1_btn bağlandı")
	
	if tier2_btn:
		tier2_btn.pressed.connect(_on_tier2_pressed)
		print("  - tier2_btn bağlandı")
	
	if tier3_btn:
		tier3_btn.pressed.connect(_on_tier3_pressed)
		print("  - tier3_btn bağlandı")
	
	if all_btn:
		all_btn.pressed.connect(_on_all_pressed)
		print("  - all_btn bağlandı")
	
	if medical_btn:
		medical_btn.pressed.connect(_on_medical_pressed)
		print("  - medical_btn bağlandı")
	
	if electronic_btn:
		electronic_btn.pressed.connect(_on_electronic_pressed)
		print("  - electronic_btn bağlandı")
	
	if mechanical_btn:
		mechanical_btn.pressed.connect(_on_mechanical_pressed)
		print("  - mechanical_btn bağlandı")
	
	if close_btn:
		close_btn.pressed.connect(_on_close_pressed)
		print("  - close_btn bağlandı")
	
	if cancel_btn:
		cancel_btn.pressed.connect(_on_cancel_pressed)
		print("  - cancel_btn bağlandı")
	
	if CraftingManager:
		CraftingManager.materials_updated.connect(_on_materials_updated)
		CraftingManager.crafting_completed.connect(_on_crafting_completed)
		CraftingManager.crafting_failed.connect(_on_crafting_failed)
		CraftingManager.recipe_discovered.connect(_on_recipe_discovered)
		print("  - CraftingManager sinyalleri bağlandı")

func _on_tier1_pressed() -> void:
	print("=".repeat(30))
	print("🎯 TIER 1 BUTONUNA BASILDI")
	print("  - Önceki tier: " + str(selected_tier))
	print("  - Yeni tier: 1")
	print("  - CraftingManager var: " + ("✅" if CraftingManager else "❌"))
	print("=".repeat(30))
	selected_tier = 1
	_update_tab_states()
	_refresh_recipes()

func _on_tier2_pressed() -> void:
	print("=".repeat(30))
	print("🎯 TIER 2 BUTONUNA BASILDI")
	print("  - Önceki tier: " + str(selected_tier))
	print("  - Yeni tier: 2")
	print("=".repeat(30))
	selected_tier = 2
	_update_tab_states()
	_refresh_recipes()

func _on_tier3_pressed() -> void:
	print("=".repeat(30))
	print("🎯 TIER 3 BUTONUNA BASILDI")
	print("  - Önceki tier: " + str(selected_tier))
	print("  - Yeni tier: 3")
	print("=".repeat(30))
	selected_tier = 3
	_update_tab_states()
	_refresh_recipes()

func _on_all_pressed() -> void:
	print("🎯 All butonuna tıklandı")
	selected_category = "all"
	_update_tab_states()
	_refresh_recipes()

func _on_medical_pressed() -> void:
	print("🎯 Medical butonuna tıklandı")
	selected_category = "medical"
	_update_tab_states()
	_refresh_recipes()

func _on_electronic_pressed() -> void:
	print("🎯 Electronic butonuna tıklandı")
	selected_category = "electronic"
	_update_tab_states()
	_refresh_recipes()

func _on_mechanical_pressed() -> void:
	print("🎯 Mechanical butonuna tıklandı")
	selected_category = "mechanical"
	_update_tab_states()
	_refresh_recipes()

func _on_close_pressed() -> void:
	print("🚪 Kapat butonuna tıklandı")
	hide_panel()

func _on_cancel_pressed() -> void:
	print("⏹️ İptal butonuna tıklandı")
	if CraftingManager:
		CraftingManager.cancel_crafting()
	is_crafting_in_progress = false
	_show_recipes()

func _update_tab_states() -> void:
	print("🎨 Tab durumları güncelleniyor...")
	
	if tier1_btn:
		_update_button_appearance(tier1_btn, selected_tier == 1, tier1_color)
	
	if tier2_btn:
		_update_button_appearance(tier2_btn, selected_tier == 2, tier2_color)
	
	if tier3_btn:
		_update_button_appearance(tier3_btn, selected_tier == 3, tier3_color)
	
	# TÜMÜ butonu için özel renk (açık gri)
	if all_btn:
		var all_color = Color(0.8, 0.8, 0.8)  # Açık gri
		_update_button_appearance(all_btn, selected_category == "all", all_color)
	
	if medical_btn:
		_update_button_appearance(medical_btn, selected_category == "medical", medical_color)
	
	if electronic_btn:
		_update_button_appearance(electronic_btn, selected_category == "electronic", electronic_color)
	
	if mechanical_btn:
		_update_button_appearance(mechanical_btn, selected_category == "mechanical", mechanical_color)

func _update_button_appearance(button: Button, active: bool, base_color: Color) -> void:
	if not button:
		return
	
	var style = StyleBoxFlat.new()
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	
	if active:
		style.bg_color = base_color
		style.border_color = Color.WHITE
		style.border_width_top = 3
		style.border_width_bottom = 3
		style.border_width_left = 3
		style.border_width_right = 3
		style.shadow_color = base_color.lightened(0.3)
		style.shadow_size = 8
		style.shadow_offset = Vector2(0, 0)
		button.add_theme_color_override("font_color", Color.WHITE)
		button.add_theme_font_size_override("font_size", 18)
		button.modulate = Color(1, 1, 1, 1)
	else:
		style.bg_color = base_color.darkened(0.7)
		style.border_color = base_color.darkened(0.5)
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_width_left = 2
		style.border_width_right = 2
		style.shadow_size = 0
		button.add_theme_color_override("font_color", base_color.lightened(0.3))
		button.add_theme_font_size_override("font_size", 16)
		button.modulate = Color(1, 1, 1, 0.8)
	
	button.add_theme_stylebox_override("normal", style)
	var hover_style = style.duplicate()
	hover_style.bg_color = style.bg_color.lightened(0.1)
	button.add_theme_stylebox_override("hover", hover_style)

func show_panel(tier: int = 1) -> void:
	print("\n" + "=".repeat(50))
	print("🚀 CRAFTING PANEL AÇILIYOR...")
	print("=".repeat(50))
	
	if panel_visible:
		print("⚠️ Panel zaten görünür, iptal ediliyor")
		return
	
	workbench_tier = tier
	selected_tier = tier
	selected_category = "all"
	panel_visible = true
	
	print("📊 Ayarlar:")
	print("  - Tier:", tier)
	print("  - panel_visible:", panel_visible)
	
	self.visible = true
	print("  - CanvasLayer visible:", self.visible)
	
	if background:
		background.visible = true
		print("  - Background visible:", background.visible)
	
	if main_panel:
		main_panel.visible = true
		print("  - MainPanel visible:", main_panel.visible)
	
	if GameState:
		GameState.game_paused = true
		print("  - GameState paused")
	
	if CraftingManager:
		CraftingManager.set_workbench_tier(tier)
		print("  - CraftingManager tier ayarlandı")
	
	if recipes_container:
		print("📦 recipes_container:")
		print("  - visible: " + str(recipes_container.visible))
		print("  - size: " + str(recipes_container.size))
		print("  - child count: " + str(recipes_container.get_child_count()))
		recipes_container.visible = true  # Zorla görünür yap
		
		# RecipesScroll'u da kontrol et
		var recipes_scroll = main_panel.get_node("RecipesScroll") if main_panel else null
		if recipes_scroll:
			print("📜 recipes_scroll:")
			print("  - visible: " + str(recipes_scroll.visible))
			print("  - size: " + str(recipes_scroll.size))
			recipes_scroll.visible = true
	
	_update_tab_states()
	_refresh_recipes()
	set_process_input(true)
	print("✅ CraftingPanel başarıyla açıldı!")
	print("=".repeat(50) + "\n")

func hide_panel() -> void:
	print("\n" + "=".repeat(50))
	print("🚪 CRAFTING PANEL KAPATILIYOR...")
	print("=".repeat(50))
	
	if not panel_visible:
		print("⚠️ Panel zaten gizli, iptal ediliyor")
		return
	
	self.visible = false
	panel_visible = false
	
	print("  - CanvasLayer visible:", self.visible)
	print("  - panel_visible:", panel_visible)
	
	if GameState:
		GameState.game_paused = false
		print("  - GameState unpaused")
	
	set_process_input(false)
	panel_closed.emit()
	print("✅ CraftingPanel başarıyla kapandı!")
	print("=".repeat(50) + "\n")

func hide_panel_immediately() -> void:
	print("🔧 hide_panel_immediately() çağrıldı")
	self.visible = false
	panel_visible = false
	if background:
		background.visible = false
	if main_panel:
		main_panel.visible = false
	set_process_input(false)

func _refresh_recipes() -> void:
	print("=".repeat(50))
	print("📋 _refresh_recipes() ÇAĞRILDI")
	print("  - selected_tier: " + str(selected_tier))
	print("  - selected_category: " + selected_category)
	print("  - panel_visible: " + str(panel_visible))
	print("  - is_crafting_in_progress: " + str(is_crafting_in_progress))
	print("  - recipe_template: " + ("✅" if recipe_template else "❌"))
	print("=".repeat(50))
	
	if not panel_visible:
		print("⚠️ Panel görünür değil, iptal")
		return
	
	if is_crafting_in_progress:
		print("⚠️ Crafting devam ediyor, sadece progress güncelle")
		_update_progress_display()
		return
	
	# ⭐⭐ DÜZELTME: Recipe template'i KORU!
	if recipes_container:
		# 1. Önce SADECE Recipe_ ile başlayanları ve separator'ları bul
		var children_to_remove = []
		for child in recipes_container.get_children():
			# ⭐ TEMPLATE'İ KORU! RecipeTemplate'i silme
			if child.name != "RecipeTemplate" and (child.name.begins_with("Recipe_") or (child is Control and child.name != "RecipeTemplate")):
				children_to_remove.append(child)
				print("🗑️ Silinecek: " + child.name)
		
		# 2. Silinecekleri temizle
		for child in children_to_remove:
			child.queue_free()
		
		# 3. Bekle
		await get_tree().process_frame
		print("✅ Temizlendi, kalan child: " + str(recipes_container.get_child_count()))
		print("   - RecipeTemplate korundu: " + ("✅" if recipes_container.has_node("RecipeTemplate") else "❌"))
	else:
		print("❌ recipes_container yok!")
		return
	
	# Template'i tekrar kontrol et
	if not recipe_template:
		print("⚠️ recipe_template null, yeniden alınıyor...")
		recipe_template = recipes_container.get_node("RecipeTemplate") if recipes_container else null
		if recipe_template:
			print("✅ RecipeTemplate yeniden bulundu")
			recipe_template.visible = false  # Template'i gizli tut
		else:
			print("❌ RecipeTemplate HİÇBİR YERDE BULUNAMADI!")
			return
	
	# Progress container'ı gizle
	if progress_container:
		progress_container.visible = false
		print("📊 progress_container gizlendi")
	
	# Recipes scroll'u göster
	var recipes_scroll = main_panel.get_node("RecipesScroll") if main_panel else null
	if recipes_scroll:
		recipes_scroll.visible = true
		print("📜 recipes_scroll gösterildi")
	
	# Başlık güncelle
	_update_title()
	
	# Filtrelenmiş tarifleri getir
	var filtered_recipes = _get_filtered_recipes()
	print("🔍 Filtrelenmiş tarif sayısı: " + str(filtered_recipes.size()))
	
	if filtered_recipes.is_empty():
		print("⚠️ Hiç tarif bulunamadı, mesaj gösteriliyor...")
		_show_no_recipes_message()
	else:
		print("✅ Tarifler bulundu, gösteriliyor...")
		_display_recipes(filtered_recipes)
	
	# Son durumu yazdır
	if recipes_container:
		print("📊 SON DURUM - recipes_container child sayısı: " + str(recipes_container.get_child_count()))
		for i in range(recipes_container.get_child_count()):
			var child = recipes_container.get_child(i)
			print("  " + str(i) + ". " + child.name + " (" + child.get_class() + ", visible: " + str(child.visible) + ")")

func _update_title() -> void:
	if not title_label:
		return
	
	var tier_text = ""
	match selected_tier:
		1: tier_text = "TIER I"
		2: tier_text = "TIER II"
		3: tier_text = "TIER III"
	
	var category_text = ""
	match selected_category:
		"all": category_text = "TÜMÜ"
		"medical": category_text = "MEDİKAL"
		"electronic": category_text = "ELEKTRONİK"
		"mechanical": category_text = "MEKANİK"
	
	title_label.text = "🛠️ CRAFTING - %s | %s" % [tier_text, category_text]

func _get_filtered_recipes() -> Array:
	if not CraftingManager:
		print("❌ CraftingManager yok!")
		return []
	
	print("🔍 CraftingManager'dan tarifler alınıyor...")
	
	# ⭐⭐ DÜZELTME: TÜM discovered recipes'leri al
	var discovered_recipes = []
	if CraftingManager.player_stats and "discovered_recipes" in CraftingManager.player_stats:
		discovered_recipes = CraftingManager.player_stats["discovered_recipes"]
	else:
		# Fallback
		discovered_recipes = CraftingManager.get_available_recipes()
	
	print("  - Discovered recipes: " + str(discovered_recipes))
	
	var filtered = []
	
	for recipe_id in discovered_recipes:
		var recipe = CraftingManager.get_recipe_info(recipe_id)
		if recipe.is_empty():
			print("  ⚠️ Recipe boş: " + recipe_id)
			continue
		
		print("  🔍 Kontrol: " + recipe["name"] + 
			  " (Tier: " + str(recipe["tier"]) + 
			  ", Category: " + recipe["category"] + ")")
		
		# ⭐⭐ DÜZELTME: SADECE tier kontrolü (kategori "all" ise hepsini göster)
		if recipe["tier"] != selected_tier:
			print("    ❌ Tier uymuyor: " + str(recipe["tier"]) + " != " + str(selected_tier))
			continue
		
		# Kategori kontrolü (eğer "all" değilse filtrel)
		if selected_category != "all" and recipe["category"] != selected_category:
			print("    ❌ Kategori uymuyor: " + recipe["category"] + " != " + selected_category)
			continue
		
		print("    ✅ Filtreden geçti!")
		filtered.append({"id": recipe_id, "data": recipe})
	
	print("📊 Filtrelenmiş tarifler: " + str(filtered.size()))
	return filtered

func _display_recipes(recipes: Array) -> void:
	print("🎨 Tarifler gösteriliyor:", recipes.size())
	
	if recipes_container:
		print("📦 Container hazır, child sayısı: ", recipes_container.get_child_count())
	
	for i in range(recipes.size()):
		var recipe_data = recipes[i]
		print("  " + str(i) + ". " + recipe_data["data"]["name"] + " (Tier: " + str(recipe_data["data"]["tier"]) + ")")
		_add_recipe_item(recipe_data["id"], recipe_data["data"])
	
	# ⭐ DEBUG: Container'ın son durumu
	if recipes_container:
		print("📊 Gösterim bitti, container child: ", recipes_container.get_child_count())
		for j in range(recipes_container.get_child_count()):
			var child = recipes_container.get_child(j)
			print("    " + str(j) + ". " + child.name + " (" + child.get_class() + ")")

func _add_recipe_item(recipe_id: String, recipe: Dictionary) -> void:
	# ⭐⭐ ÖNCE TEMPLATE KONTROLÜ
	if not recipes_container:
		print("❌ recipes_container yok!")
		return
	
	if not recipe_template:
		# Acil durum: Template'i yeniden ara
		recipe_template = recipes_container.get_node("RecipeTemplate") as Panel
		if not recipe_template:
			print("❌ recipe_template HİÇBİR YERDE YOK!")
			return
	
	print("➕ Recipe ekleniyor: " + recipe["name"] + " (Template: " + ("✅" if recipe_template else "❌") + ")")
	
	# TEMPLATE'İ KOPYALA
	var container = recipe_template.duplicate()
	container.visible = true
	container.name = "Recipe_" + recipe_id
	
	# TÜM LABEL ve BUTON'ları bul
	var all_labels = []
	var all_buttons = []
	_collect_all_nodes(container, all_labels, all_buttons)
	
	print("📋 Bulunan Label'lar (" + str(all_labels.size()) + "):")
	for i in range(all_labels.size()):
		var label = all_labels[i]
		print("  " + str(i) + ". " + label.name + " -> " + label.text)
	
	print("📋 Bulunan Button'lar (" + str(all_buttons.size()) + "):")
	for i in range(all_buttons.size()):
		var btn = all_buttons[i]
		print("  " + str(i) + ". " + btn.name + " -> " + btn.text)
	
	# ELEMENTLERİ SEÇ (ilk Label'ları ve ilk Button'ı kullan)
	if all_labels.size() >= 1:
		var icon_label = all_labels[0]  # İlk Label = icon
		icon_label.text = _get_category_icon(recipe["category"])
		print("✅ Icon ayarlandı: " + icon_label.text)
	
	if all_labels.size() >= 2:
		var name_label = all_labels[1]  # İkinci Label = name
		name_label.text = recipe["name"]
		print("✅ Name ayarlandı: " + name_label.text)
	
	if all_labels.size() >= 3:
		var desc_label = all_labels[2]  # Üçüncü Label = description
		desc_label.text = recipe["description"]
		print("✅ Description ayarlandı: " + desc_label.text)
	
	if all_buttons.size() >= 1:
		var craft_btn = all_buttons[0]  # İlk Button = craft butonu
		craft_btn.text = "CRAFT"
		craft_btn.pressed.connect(_on_craft_button_pressed.bind(recipe_id))
		print("✅ Craft butonu ayarlandı")
		
		# Craft edilebilir mi?
		if CraftingManager:
			var can_craft = CraftingManager.can_craft(recipe_id)
			if not can_craft["can_craft"]:
				craft_btn.disabled = true
				craft_btn.text = "YETERSİZ"
				var disabled_style = StyleBoxFlat.new()
				disabled_style.bg_color = Color(0.7, 0.3, 0.3)
				disabled_style.corner_radius_top_left = 8
				disabled_style.corner_radius_top_right = 8
				disabled_style.corner_radius_bottom_left = 8
				disabled_style.corner_radius_bottom_right = 8
				craft_btn.add_theme_stylebox_override("disabled", disabled_style)
				print("✅ Buton disabled yapıldı")
	
	# CONTAINER'I EKLE
	recipes_container.add_child(container)
	container.visible = true
	print("✅ Recipe eklendi: " + recipe["name"] + " (visible: " + str(container.visible) + ")")
	
	# AYIRICI EKLE
	var separator = Control.new()
	separator.custom_minimum_size = Vector2(0, 10)
	separator.visible = true  # ⭐ Bu da görünür olmalı
	recipes_container.add_child(separator)

# YARDIMCI FONKSİYONLAR
func _debug_print_all_nodes(node: Node, indent: int = 0) -> void:
	var indent_str = "  ".repeat(indent)
	var node_info = indent_str + "└─ " + node.name + " (" + node.get_class() + ")"
	
	# Ek bilgiler
	if node is Label:
		node_info += " [Label: '" + node.text + "']"
	elif node is Button:
		node_info += " [Button: '" + node.text + "']"
	elif node is Panel:
		node_info += " [Panel]"
	elif node is HBoxContainer:
		node_info += " [HBox]"
	elif node is VBoxContainer:
		node_info += " [VBox]"
	elif node is Control:
		node_info += " [Control]"
	
	print(node_info)
	
	for child in node.get_children():
		_debug_print_all_nodes(child, indent + 1)

func _collect_all_nodes(node: Node, labels: Array, buttons: Array) -> void:
	if node is Label:
		labels.append(node)
	elif node is Button:
		buttons.append(node)
	
	for child in node.get_children():
		_collect_all_nodes(child, labels, buttons)

func _print_node_tree(node: Node, indent: int) -> void:
	var indent_str = "  ".repeat(indent)
	print(indent_str + "└─ " + node.name + " (" + node.get_class() + ")")
	
	for child in node.get_children():
		_print_node_tree(child, indent + 1)

func _show_no_recipes_message() -> void:
	if not recipes_container:
		return
	
	var message = Label.new()
	message.text = "Bu kategoride craft edilebilir tarif yok."
	message.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message.add_theme_font_size_override("font_size", 18)
	message.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	recipes_container.add_child(message)

func _on_craft_button_pressed(recipe_id: String) -> void:
	print("🔨 Craft butonuna tıklandı:", recipe_id)
	if not CraftingManager:
		print("⚠️ CraftingManager yok")
		return
	
	var can_craft = CraftingManager.can_craft(recipe_id)
	if not can_craft["can_craft"]:
		_show_error_message(can_craft["message"])
		return
	
	is_crafting_in_progress = true
	_show_crafting_progress(recipe_id)

func _show_crafting_progress(recipe_id: String) -> void:
	print("⏳ Crafting başlatılıyor:", recipe_id)
	current_crafting_item = recipe_id
	var recipes_scroll = main_panel.get_node("RecipesScroll") if main_panel else null
	if recipes_scroll:
		recipes_scroll.visible = false
	if progress_container:
		progress_container.visible = true
	if progress_bar:
		progress_bar.value = 0
	if progress_label:
		progress_label.text = "Crafting... 0%"
	if CraftingManager:
		print("🔄 CraftingManager.start_crafting çağrılıyor...")
		var result = await CraftingManager.start_crafting(recipe_id, workbench_tier)
		print("🔧 Crafting sonucu:", result)

func _update_progress_display() -> void:
	if not CraftingManager or not CraftingManager.is_crafting:
		return
	
	var progress = CraftingManager.crafting_progress * 100
	if progress_bar:
		progress_bar.value = progress
	if progress_label:
		progress_label.text = "Crafting... %d%%" % int(progress)

func _show_recipes() -> void:
	print("📋 Recipe listesine dönülüyor")
	is_crafting_in_progress = false
	if progress_container:
		progress_container.visible = false
	var recipes_scroll = main_panel.get_node("RecipesScroll") if main_panel else null
	if recipes_scroll:
		recipes_scroll.visible = true
	_refresh_recipes()

func _on_materials_updated() -> void:
	if CraftingManager and CraftingManager.is_crafting:
		_update_progress_display()
	else:
		_refresh_recipes()

func _on_crafting_completed(item_name: String, amount: int) -> void:
	print("🎉 Crafting tamamlandı:", item_name, "×", amount)
	await get_tree().create_timer(1.5).timeout
	_show_success_message("%s ×%d craft edildi!" % [item_name, amount])

func _on_crafting_failed(reason: String) -> void:
	print("💔 Crafting başarısız:", reason)
	await get_tree().create_timer(1.0).timeout
	_show_error_message("Craft başarısız: " + reason)

func _on_recipe_discovered(recipe_id: String) -> void:
	print("📜 Yeni tarif keşfedildi:", recipe_id)
	_refresh_recipes()

func _show_error_message(message: String) -> void:
	if not title_label:
		return
	
	var original_text = title_label.text
	title_label.text = "❌ " + message
	title_label.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4))
	await get_tree().create_timer(2.0).timeout
	title_label.text = original_text
	title_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))

func _show_success_message(message: String) -> void:
	if not title_label:
		return
	
	var original_text = title_label.text
	title_label.text = "✅ " + message
	title_label.add_theme_color_override("font_color", Color(0.4, 0.8, 0.4))
	await get_tree().create_timer(2.0).timeout
	_show_recipes()
	title_label.text = original_text
	title_label.add_theme_color_override("font_color", Color(0.9, 0.7, 0.3))

func _get_category_icon(category: String) -> String:
	match category:
		"medical": return "🩹"
		"electronic": return "🔋"
		"mechanical": return "🛠️"
		_: return "📦"

func _input(event: InputEvent) -> void:
	if panel_visible and event.is_action_pressed("ui_cancel"):
		print("⎋ ESC tuşuna basıldı")
		if is_crafting_in_progress and CraftingManager and CraftingManager.is_crafting:
			_on_cancel_pressed()
		else:
			hide_panel()
		get_viewport().set_input_as_handled()
