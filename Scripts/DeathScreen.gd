extends CanvasLayer

# ==================================================
# UI REFERENCES
# ==================================================
@onready var background: ColorRect = $Control/Background
@onready var main_panel: Panel = $Control/CenterContainer/MainPanel
@onready var title_label: Label = $Control/CenterContainer/MainPanel/MarginContainer/VBoxContainer/TitleLabel
@onready var reason_label: RichTextLabel = $Control/CenterContainer/MainPanel/MarginContainer/VBoxContainer/ReasonLabel
@onready var stats_vbox: VBoxContainer = $Control/CenterContainer/MainPanel/MarginContainer/VBoxContainer/StatsPanel/StatsVBox
@onready var restart_btn: Button = $Control/CenterContainer/MainPanel/MarginContainer/VBoxContainer/ButtonsHBox/RestartBtn
@onready var menu_btn: Button = $Control/CenterContainer/MainPanel/MarginContainer/VBoxContainer/ButtonsHBox/MenuBtn

# ==================================================
# ENUMS & CONSTANTS
# ==================================================
enum DeathReason {
	STARVATION,      # Açlık
	INJURY,          # Yaralanma
	EXHAUSTION,      # Yorgunluk
	OUTSIDE_DANGER,  # Dışarıda ölüm
	DEHYDRATION,     # Susuzluk
	UNKNOWN          # Bilinmeyen
}

# Ölüm nedenlerine göre BBCode mesajlar
const REASON_TEXTS := {
	DeathReason.STARVATION: "[color=#e67e22]🍖 AÇLIKTAN ÖLDÜN[/color]",
	DeathReason.INJURY: "[color=#e74c3c]💀 AĞIR YARALANARAK ÖLDÜN[/color]",
	DeathReason.EXHAUSTION: "[color=#3498db]😴 ENERJİSİZLİKTEN ÖLDÜN[/color]",
	DeathReason.OUTSIDE_DANGER: "[color=#9b59b6]🌧️ ZEHİRLİ YAĞMURDA MAHVOLDUN[/color]",
	DeathReason.DEHYDRATION: "[color=#2980b9]💧 SUSUZLUKTAN ÖLDÜN[/color]",
	DeathReason.UNKNOWN: "[color=#95a5a6]☠️ ÖLDÜN[/color]"
}

# ==================================================
# READY
# ==================================================
func _ready() -> void:
	# Başlangıçta gizli ve saydam
	hide()
	background.modulate.a = 0.0
	main_panel.modulate.a = 0.0
	
	# Buton bağlantıları
	restart_btn.pressed.connect(_on_restart_pressed)
	menu_btn.pressed.connect(_on_menu_pressed)
	
	# Butonları başlangıçta gizle
	restart_btn.modulate.a = 0.0
	menu_btn.modulate.a = 0.0

# ==================================================
# PUBLIC FUNCTIONS
# ==================================================
func show_death_screen(reason: String, stats: Dictionary = {}) -> void:
	"""Ölüm ekranını göster"""
	print("DeathScreen gösteriliyor... Neden: ", reason)
	
	# Oyunu durdur
	GameState.game_paused = true
	
	# String'i DeathReason enum'ına çevir
	var death_reason: DeathReason = _string_to_reason(reason)
	
	# UI'yi güncelle
	_set_reason_text(death_reason)
	_fill_stats(stats)
	
	# Göster ve animasyonu başlat
	show()
	_start_fade_animation()

func show_victory_screen(stats: Dictionary = {}) -> void:
	"""Kurtarılma (kazanma) ekranı"""
	GameState.game_paused = true
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.ui_blocked = true
	title_label.text = "KURTULDUN"
	title_label.add_theme_color_override("font_color", Color("#2ecc71"))
	reason_label.text = "[color=#2ecc71]🚁 Kurtarma ekibi seni yağmurun ortasından çıkardı.[/color]"
	_fill_stats(stats)
	show()
	_start_fade_animation()

# ==================================================
# HELPER FUNCTIONS
# ==================================================
func _string_to_reason(reason_str: String) -> DeathReason:
	"""String'i DeathReason enum'ına çevir"""
	match reason_str:
		"starvation":
			return DeathReason.STARVATION
		"injury":
			return DeathReason.INJURY
		"exhaustion":
			return DeathReason.EXHAUSTION
		"outside":
			return DeathReason.OUTSIDE_DANGER
		"dehydration":
			return DeathReason.DEHYDRATION
		_:
			return DeathReason.UNKNOWN

func _set_reason_text(reason: DeathReason) -> void:
	"""Ölüm nedenine göre metni ayarla"""
	# ReasonLabel'a BBCode'lu metni ata
	reason_label.text = REASON_TEXTS.get(reason, REASON_TEXTS[DeathReason.UNKNOWN])
	
	# Başlık rengini nedenine göre değiştir
	match reason:
		DeathReason.STARVATION:
			title_label.add_theme_color_override("font_color", Color("#e67e22"))
		DeathReason.INJURY:
			title_label.add_theme_color_override("font_color", Color("#e74c3c"))
		DeathReason.EXHAUSTION:
			title_label.add_theme_color_override("font_color", Color("#3498db"))
		DeathReason.OUTSIDE_DANGER:
			title_label.add_theme_color_override("font_color", Color("#9b59b6"))
		DeathReason.DEHYDRATION:
			title_label.add_theme_color_override("font_color", Color("#2980b9"))
		_:
			title_label.add_theme_color_override("font_color", Color("#95a5a6"))

func _fill_stats(stats: Dictionary) -> void:
	"""İstatistikleri panele ekle"""
	# Önce mevcut istatistikleri temizle
	for child in stats_vbox.get_children():
		child.queue_free()
	
	# İstatistikleri oluştur
	if stats.has("days_survived"):
		_add_stat_line("📅 Hayatta Kalınan Gün", str(stats["days_survived"]))
	
	if stats.has("total_loot"):
		_add_stat_line("🎒 Toplanan Eşya", str(stats["total_loot"]))
	
	if stats.has("longest_outside"):
		_add_stat_line("⏱️ En Uzun Dışarı Kalma", "%d saat" % stats["longest_outside"])
	
	if stats.has("total_hours_outside"):
		_add_stat_line("🚪 Toplam Dışarıda Kalma", "%d saat" % stats["total_hours_outside"])
	
	# Varsayılan istatistik (boşsa)
	if stats.is_empty():
		_add_stat_line("💀 Öldün", "Daha iyi şanslar!")

func _add_stat_line(label_text: String, value_text: String) -> void:
	"""İstatistik satırı ekle"""
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Label (sol)
	var label = Label.new()
	label.text = label_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.add_theme_color_override("font_color", Color("#bdc3c7"))
	
	# Value (sağ)
	var value = Label.new()
	value.text = value_text
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value.add_theme_color_override("font_color", Color("#ecf0f1"))
	value.add_theme_font_size_override("font_size", 18)
	
	hbox.add_child(label)
	hbox.add_child(value)
	stats_vbox.add_child(hbox)

# ==================================================
# ANIMATIONS
# ==================================================
func _start_fade_animation() -> void:
	"""Ölüm ekranı animasyonunu başlat"""
	var tween = create_tween()
	tween.set_parallel(false)  # Sıralı animasyon
	
	# 1. Arkaplan kararsın (2 saniye)
	tween.tween_property(background, "modulate:a", 0.9, 2.0)
	
	# 2. Panel belirsin (1.5 saniye)
	tween.tween_property(main_panel, "modulate:a", 1.0, 1.5)
	
	# 3. Butonlar belirsin (1 saniye)
	tween.tween_property(restart_btn, "modulate:a", 1.0, 1.0)
	tween.tween_property(menu_btn, "modulate:a", 1.0, 1.0)
	
	# 4. Başlık pulsating animasyonu
	_start_title_animation()

func _start_title_animation() -> void:
	"""Başlık yanıp sönen animasyon"""
	var tween = create_tween()
	tween.set_loops()  # Sonsuz döngü
	
	# Hafifçe büyüyüp küçülsün
	tween.tween_property(title_label, "scale", Vector2(1.05, 1.05), 1.0)
	tween.tween_property(title_label, "scale", Vector2(1.0, 1.0), 1.0)

# ==================================================
# BUTTON HANDLERS
# ==================================================
func _on_restart_pressed() -> void:
	"""Yeniden başlat butonu"""
	print("Oyun yeniden başlatılıyor...")
	
	# Fade out animasyonu
	var tween = create_tween()
	tween.tween_property(main_panel, "modulate:a", 0.0, 0.5)
	tween.tween_property(background, "modulate:a", 0.0, 1.0)
	await tween.finished
	
	# Oyunu yeniden başlat
	GameState.reset_game()
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	"""Ana menü butonu"""
	print("Ana menüye dönülüyor...")
	
	# Fade out animasyonu
	var tween = create_tween()
	tween.tween_property(main_panel, "modulate:a", 0.0, 0.5)
	tween.tween_property(background, "modulate:a", 0.0, 1.0)
	await tween.finished
	
	# Ana menüye dön
	GameState.game_paused = false
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")


func _on_player_player_died(reason: String, stats: Dictionary):
	show_death_screen(reason, stats)  # ⭐ BU SATIRI EKLE
	print("💀 DeathScreen: Player öldü, neden: ", reason)
