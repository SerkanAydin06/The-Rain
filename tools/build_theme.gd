# Ortak arayüz temasını üretir: Assets/UI/theme.tres
# Çalıştır: godot --headless -s res://tools/build_theme.gd
extends SceneTree

const P := preload("res://Scripts/UI/UIPalette.gd")
const OUT := "res://Assets/UI/theme.tres"

var regular: FontFile = load("res://Assets/Fonts/Barlow-Regular.ttf")
var semibold: FontFile = load("res://Assets/Fonts/Barlow-SemiBold.ttf")
var cond: FontFile = load("res://Assets/Fonts/BarlowCondensed-SemiBold.ttf")
var cond_bold: FontFile = load("res://Assets/Fonts/BarlowCondensed-Bold.ttf")

func _initialize() -> void:
	var t := Theme.new()
	t.default_font = regular
	t.default_font_size = 20

	_panels(t)
	_labels(t)
	_buttons(t)
	_bars(t)
	_misc(t)

	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://Assets/UI"))
	var err := ResourceSaver.save(t, OUT)
	print("Theme saved: ", OUT, " err=", err)
	quit()

func box(bg: Color, border := Color.TRANSPARENT, bw := 0, radius := 6, margin := Vector4(0, 0, 0, 0)) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.content_margin_left = margin.x
	s.content_margin_top = margin.y
	s.content_margin_right = margin.z
	s.content_margin_bottom = margin.w
	s.anti_aliasing = true
	return s

func _panels(t: Theme) -> void:
	var panel := box(P.PANEL, P.BORDER, 1, 8, Vector4(24, 20, 24, 20))
	panel.shadow_color = Color(0, 0, 0, 0.45)
	panel.shadow_size = 18
	panel.shadow_offset = Vector2(0, 6)
	t.set_stylebox("panel", "Panel", panel)
	t.set_stylebox("panel", "PanelContainer", panel)

	# Kart: panel içi bölümler
	t.add_type("CardPanel")
	t.set_type_variation("CardPanel", "PanelContainer")
	t.set_stylebox("panel", "CardPanel", box(P.PANEL_LIGHT, P.BORDER, 1, 6, Vector4(16, 12, 16, 12)))

	# HUD: daha şeffaf, gölgesiz
	t.add_type("HudPanel")
	t.set_type_variation("HudPanel", "PanelContainer")
	t.set_stylebox("panel", "HudPanel", box(Color(0.04, 0.05, 0.06, 0.78), P.BORDER, 1, 6, Vector4(14, 12, 14, 12)))

	# Hap şeklinde bilgi kutusu
	t.add_type("PillPanel")
	t.set_type_variation("PillPanel", "PanelContainer")
	t.set_stylebox("panel", "PillPanel", box(Color(0.04, 0.05, 0.06, 0.8), P.BORDER, 1, 20, Vector4(18, 6, 18, 6)))

	# Seçili yuva / vurgulu kart
	t.add_type("AccentPanel")
	t.set_type_variation("AccentPanel", "PanelContainer")
	t.set_stylebox("panel", "AccentPanel", box(Color(P.ACCENT, 0.12), P.ACCENT, 1, 6, Vector4(16, 12, 16, 12)))

func _labels(t: Theme) -> void:
	t.set_color("font_color", "Label", P.TEXT)
	t.set_color("font_outline_color", "Label", Color(0, 0, 0, 0.8))
	t.set_constant("outline_size", "Label", 0)
	t.set_constant("line_spacing", "Label", 2)

	_label_var(t, "TitleLabel", cond_bold, 64, P.TEXT)
	_label_var(t, "HeaderLabel", cond, 32, P.TEXT)
	_label_var(t, "SectionLabel", cond, 18, P.ACCENT)
	_label_var(t, "SubLabel", regular, 17, P.TEXT_MUTED)
	_label_var(t, "SmallLabel", semibold, 14, P.TEXT_MUTED)
	_label_var(t, "ValueLabel", semibold, 18, P.TEXT)

	# Tuş kutucuğu: [E], [1] ...
	t.add_type("KeyCap")
	t.set_type_variation("KeyCap", "Label")
	t.set_font("font", "KeyCap", semibold)
	t.set_font_size("font_size", "KeyCap", 14)
	t.set_color("font_color", "KeyCap", P.TEXT_DARK)
	t.set_stylebox("normal", "KeyCap", box(P.ACCENT, Color.TRANSPARENT, 0, 4, Vector4(7, 1, 7, 1)))

	t.set_font("normal_font", "RichTextLabel", regular)
	t.set_font("bold_font", "RichTextLabel", semibold)
	t.set_font_size("normal_font_size", "RichTextLabel", 19)
	t.set_font_size("bold_font_size", "RichTextLabel", 19)
	t.set_color("default_color", "RichTextLabel", P.TEXT)

func _label_var(t: Theme, name: String, font: Font, size: int, color: Color) -> void:
	t.add_type(name)
	t.set_type_variation(name, "Label")
	t.set_font("font", name, font)
	t.set_font_size("font_size", name, size)
	t.set_color("font_color", name, color)

func _button_set(t: Theme, type: String, normal: StyleBox, hover: StyleBox, pressed: StyleBox, disabled: StyleBox,
		fc: Color, fc_hover: Color, fc_pressed: Color) -> void:
	t.set_stylebox("normal", type, normal)
	t.set_stylebox("hover", type, hover)
	t.set_stylebox("pressed", type, pressed)
	t.set_stylebox("hover_pressed", type, pressed)
	t.set_stylebox("disabled", type, disabled)
	var focus := box(Color.TRANSPARENT, P.ACCENT, 2, 6)
	focus.draw_center = false
	t.set_stylebox("focus", type, focus)
	t.set_color("font_color", type, fc)
	t.set_color("font_hover_color", type, fc_hover)
	t.set_color("font_focus_color", type, fc)
	t.set_color("font_pressed_color", type, fc_pressed)
	t.set_color("font_hover_pressed_color", type, fc_pressed)
	t.set_color("font_disabled_color", type, P.TEXT_DIM)

func _buttons(t: Theme) -> void:
	var m := Vector4(20, 10, 20, 10)
	t.set_font("font", "Button", semibold)
	t.set_font_size("font_size", "Button", 19)
	_button_set(t, "Button",
		box(P.PANEL_LIGHT, P.BORDER_STRONG, 1, 6, m),
		box(P.PANEL_HOVER, P.ACCENT, 1, 6, m),
		box(Color(P.ACCENT, 0.25), P.ACCENT, 1, 6, m),
		box(Color(P.PANEL_LIGHT, 0.5), P.BORDER, 1, 6, m),
		P.TEXT, P.ACCENT, P.TEXT)

	# Birincil (onay) buton
	t.add_type("PrimaryButton")
	t.set_type_variation("PrimaryButton", "Button")
	_button_set(t, "PrimaryButton",
		box(P.ACCENT, Color.TRANSPARENT, 0, 6, m),
		box(P.ACCENT.lightened(0.15), Color.TRANSPARENT, 0, 6, m),
		box(P.ACCENT_DARK, Color.TRANSPARENT, 0, 6, m),
		box(Color(P.ACCENT, 0.25), Color.TRANSPARENT, 0, 6, m),
		P.TEXT_DARK, P.TEXT_DARK, P.TEXT_DARK)

	# Tehlikeli işlem butonu
	t.add_type("DangerButton")
	t.set_type_variation("DangerButton", "Button")
	_button_set(t, "DangerButton",
		box(P.PANEL_LIGHT, Color(P.DANGER, 0.6), 1, 6, m),
		box(Color(P.DANGER, 0.85), P.DANGER, 1, 6, m),
		box(P.DANGER.darkened(0.25), P.DANGER, 1, 6, m),
		box(Color(P.PANEL_LIGHT, 0.5), P.BORDER, 1, 6, m),
		P.DANGER, P.TEXT, P.TEXT)

	# Ana menü butonu: sade, sola hizalı, hover'da sol çizgi
	t.add_type("MainMenuButton")
	t.set_type_variation("MainMenuButton", "Button")
	t.set_font("font", "MainMenuButton", cond)
	t.set_font_size("font_size", "MainMenuButton", 34)
	t.set_constant("h_separation", "MainMenuButton", 12)
	var mm := Vector4(18, 4, 18, 4)
	var mnormal := box(Color.TRANSPARENT, Color.TRANSPARENT, 0, 0, mm)
	var mhover := box(Color(P.ACCENT, 0.08), P.ACCENT, 0, 0, mm)
	mhover.border_width_left = 4
	var mpressed := box(Color(P.ACCENT, 0.16), P.ACCENT, 0, 0, mm)
	mpressed.border_width_left = 4
	_button_set(t, "MainMenuButton", mnormal, mhover, mpressed, mnormal, P.TEXT, P.ACCENT, P.ACCENT)
	var mfocus := box(Color(P.ACCENT, 0.08), P.ACCENT, 0, 0, mm)
	mfocus.border_width_left = 4
	t.set_stylebox("focus", "MainMenuButton", mfocus)
	t.set_color("font_focus_color", "MainMenuButton", P.ACCENT)

	# Sekme / filtre butonu (toggle)
	t.add_type("TabButton")
	t.set_type_variation("TabButton", "Button")
	t.set_font_size("font_size", "TabButton", 17)
	var tm := Vector4(14, 7, 14, 7)
	_button_set(t, "TabButton",
		box(Color.TRANSPARENT, P.BORDER, 1, 5, tm),
		box(P.PANEL_HOVER, P.BORDER_STRONG, 1, 5, tm),
		box(Color(P.ACCENT, 0.18), P.ACCENT, 1, 5, tm),
		box(Color.TRANSPARENT, P.BORDER, 1, 5, tm),
		P.TEXT_MUTED, P.TEXT, P.ACCENT)

	# Küçük kare buton (+ / -)
	t.add_type("IconButton")
	t.set_type_variation("IconButton", "Button")
	t.set_font_size("font_size", "IconButton", 24)
	var im := Vector4(0, 0, 0, 2)
	_button_set(t, "IconButton",
		box(P.PANEL_LIGHT, P.BORDER_STRONG, 1, 6, im),
		box(P.PANEL_HOVER, P.ACCENT, 1, 6, im),
		box(Color(P.ACCENT, 0.25), P.ACCENT, 1, 6, im),
		box(Color(P.PANEL_LIGHT, 0.4), P.BORDER, 1, 6, im),
		P.TEXT, P.ACCENT, P.TEXT)

func _bars(t: Theme) -> void:
	t.set_stylebox("background", "ProgressBar", box(Color(0, 0, 0, 0.55), Color(1, 1, 1, 0.06), 1, 3))
	t.set_stylebox("fill", "ProgressBar", box(P.ACCENT, Color.TRANSPARENT, 0, 3))
	t.set_font("font", "ProgressBar", semibold)
	t.set_font_size("font_size", "ProgressBar", 13)
	t.set_color("font_color", "ProgressBar", P.TEXT)
	for pair in [["BarHealth", P.HEALTH], ["BarHunger", P.HUNGER], ["BarThirst", P.THIRST],
			["BarEnergy", P.ENERGY], ["BarSuit", P.SUIT], ["BarAccent", P.ACCENT]]:
		t.add_type(pair[0])
		t.set_type_variation(pair[0], "ProgressBar")
		t.set_stylebox("fill", pair[0], box(pair[1], Color.TRANSPARENT, 0, 3))

func _misc(t: Theme) -> void:
	# Ayırıcı
	var line := StyleBoxLine.new()
	line.color = P.BORDER
	line.thickness = 1
	t.set_stylebox("separator", "HSeparator", line)
	t.set_constant("separation", "HSeparator", 12)

	# Kaydırma çubuğu
	t.set_stylebox("scroll", "VScrollBar", box(Color(0, 0, 0, 0.25), Color.TRANSPARENT, 0, 3, Vector4(3, 0, 3, 0)))
	t.set_stylebox("grabber", "VScrollBar", box(Color(1, 1, 1, 0.18), Color.TRANSPARENT, 0, 3))
	t.set_stylebox("grabber_highlight", "VScrollBar", box(Color(P.ACCENT, 0.6), Color.TRANSPARENT, 0, 3))
	t.set_stylebox("grabber_pressed", "VScrollBar", box(P.ACCENT, Color.TRANSPARENT, 0, 3))

	# Kaydırıcı (ses vb.)
	t.set_stylebox("slider", "HSlider", box(Color(0, 0, 0, 0.5), P.BORDER, 1, 3, Vector4(0, 3, 0, 3)))
	t.set_stylebox("grabber_area", "HSlider", box(P.ACCENT, Color.TRANSPARENT, 0, 3, Vector4(0, 3, 0, 3)))
	t.set_stylebox("grabber_area_highlight", "HSlider", box(P.ACCENT.lightened(0.15), Color.TRANSPARENT, 0, 3, Vector4(0, 3, 0, 3)))

	# CheckButton yazıları
	t.set_font("font", "CheckButton", regular)
	t.set_font_size("font_size", "CheckButton", 19)
	t.set_color("font_color", "CheckButton", P.TEXT)
	t.set_color("font_hover_color", "CheckButton", P.ACCENT)
	t.set_color("font_pressed_color", "CheckButton", P.TEXT)
	t.set_color("font_hover_pressed_color", "CheckButton", P.ACCENT)
	var empty := StyleBoxEmpty.new()
	for s in ["normal", "hover", "pressed", "hover_pressed", "focus"]:
		t.set_stylebox(s, "CheckButton", empty)

	# İpucu
	t.set_stylebox("panel", "TooltipPanel", box(P.PANEL_LIGHT, P.BORDER_STRONG, 1, 5, Vector4(10, 6, 10, 6)))
	t.set_color("font_color", "TooltipLabel", P.TEXT)
	t.set_font_size("font_size", "TooltipLabel", 16)
