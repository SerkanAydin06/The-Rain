# InteractionHUD.gd - TAM DÜZELTİLMİŞ
extends CanvasLayer

# UI elementleri
var container: Control
var hint_label: Label
var hint_panel: Panel

# Tema ayarları
const COLORS = {
	"panel_bg": Color(0.1, 0.12, 0.16, 0.85),
	"panel_border": Color(0.9, 0.7, 0.3, 1.0),
	"text_color": Color(0.98, 0.85, 0.45, 1.0),
	"shadow": Color(0, 0, 0, 0.6)
}

func _ready():
	print("🔧 InteractionHUD hazırlanıyor...")
	_create_hud()
	hide_hint()

func _create_hud():
	container = Control.new()
	container.name = "Container"
	container.anchor_right = 1.0
	container.anchor_bottom = 1.0
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(container)
	
	hint_panel = Panel.new()
	hint_panel.name = "HintPanel"
	hint_panel.visible = false
	hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_panel.custom_minimum_size = Vector2(350, 60)
	
	# Panel stili
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = COLORS.panel_bg
	panel_style.border_width_bottom = 3
	panel_style.border_color = COLORS.panel_border
	panel_style.corner_radius_top_left = 12
	panel_style.corner_radius_top_right = 12
	panel_style.corner_radius_bottom_left = 0
	panel_style.corner_radius_bottom_right = 0
	panel_style.shadow_color = COLORS.shadow
	panel_style.shadow_size = 6
	panel_style.shadow_offset = Vector2(0, 4)
	hint_panel.add_theme_stylebox_override("panel", panel_style)
	
	container.add_child(hint_panel)
	
	hint_label = Label.new()
	hint_label.name = "HintLabel"
	hint_label.text = ""
	hint_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	hint_panel.add_child(hint_label)
	
	await get_tree().process_frame
	
	if hint_label and GlobalHintManager:
		GlobalHintManager.setup_hint_label(hint_label)
	
	# Label stili
	hint_label.add_theme_font_size_override("font_size", 22)
	hint_label.add_theme_color_override("font_color", COLORS.text_color)
	hint_label.add_theme_constant_override("outline_size", 2)
	hint_label.add_theme_color_override("font_outline_color", Color.BLACK)
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	_update_positions()
	get_viewport().size_changed.connect(_update_positions)

func _update_positions():
	if not container or not hint_panel:
		return
	
	var viewport_size = get_viewport().size
	
	# SABİT POZİSYON
	hint_panel.position = Vector2(
		(viewport_size.x - 350) / 2,
		viewport_size.y - 150
	)
	
	if hint_label:
		hint_label.position = Vector2.ZERO
		hint_label.size = Vector2(350, 60)

func show_hint(text: String):
	"""Hint göster - ANİMASYONSUZ (önerilen)"""
	if not hint_panel or not hint_label:
		return
	
	print("🔔 Hint göster: ", text)
	
	hint_label.text = text
	hint_panel.visible = true
	hint_panel.modulate.a = 1.0

func hide_hint():
	"""Hint gizle - ANİMASYONSUZ"""
	if not hint_panel:
		return
	
	print("🔔 Hint gizleniyor")
	hint_panel.visible = false
	hint_label.text = ""

# ⭐ ANİMASYONLU VERSİYON (EĞER İSTERSEN) - DÜZELTİLMİŞ
func show_hint_with_animation(text: String):
	if not hint_panel or not hint_label:
		return
	
	print("🔔 Hint göster (animasyonlu): ", text)
	
	hint_label.text = text
	
	# Pozisyonu resetle
	_update_positions()
	
	# Animasyon başlangıcı
	hint_panel.visible = true
	hint_panel.modulate.a = 0
	hint_panel.scale = Vector2(0.9, 0.9)
	
	# Tween animasyonu
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(hint_panel, "modulate:a", 1.0, 0.3)
	tween.tween_property(hint_panel, "scale", Vector2(1, 1), 0.3)\
		 .set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func hide_hint_with_animation():
	if not hint_panel:
		return
	
	var tween = create_tween()
	tween.tween_property(hint_panel, "modulate:a", 0.0, 0.2)
	tween.tween_property(hint_panel, "scale", Vector2(0.9, 0.9), 0.2)
	tween.tween_callback(func():
		hint_panel.visible = false
		hint_label.text = ""
		hint_panel.modulate.a = 1.0
		hint_panel.scale = Vector2(1, 1)
	)
