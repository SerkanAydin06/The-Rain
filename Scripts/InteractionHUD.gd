# InteractionHUD.gd - Etkileşim ipucu: alt ortada [E] Eylem
extends CanvasLayer
# Autoload: "InteractionHUD"

var hint_panel: PanelContainer
var key_label: Label
var hint_label: Label
var _tween: Tween

func _ready() -> void:
	layer = 5
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	hint_panel = PanelContainer.new()
	hint_panel.theme_type_variation = &"PillPanel"
	hint_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_panel.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint_panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	hint_panel.grow_vertical = Control.GROW_DIRECTION_BEGIN
	hint_panel.offset_top = -186
	hint_panel.offset_bottom = -142
	root.add_child(hint_panel)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hint_panel.add_child(hbox)

	key_label = Label.new()
	key_label.theme_type_variation = &"KeyCap"
	key_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	hbox.add_child(key_label)

	hint_label = Label.new()
	hint_label.add_theme_font_size_override("font_size", 19)
	hbox.add_child(hint_label)

	hint_panel.visible = false

func show_hint(text: String) -> void:
	# "[E] Uyu" -> tuş: E, metin: Uyu
	var key := "E"
	var body := text
	var rx := RegEx.create_from_string("^\\s*\\[(.+?)\\]\\s*(.*)$")
	var m := rx.search(text)
	if m:
		key = m.get_string(1)
		body = m.get_string(2)
	key_label.text = key
	hint_label.text = body
	if _tween:
		_tween.kill()
	if not hint_panel.visible:
		hint_panel.visible = true
		hint_panel.modulate.a = 0.0
		_tween = create_tween()
		_tween.tween_property(hint_panel, "modulate:a", 1.0, 0.15)
	else:
		hint_panel.modulate.a = 1.0
	# Metin değişince ortalamayı koru
	hint_panel.reset_size()
	hint_panel.offset_left = -hint_panel.get_combined_minimum_size().x / 2
	hint_panel.offset_right = hint_panel.get_combined_minimum_size().x / 2

func hide_hint() -> void:
	if not hint_panel.visible:
		return
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(hint_panel, "modulate:a", 0.0, 0.12)
	_tween.tween_callback(func(): hint_panel.visible = false)

func show_hint_with_animation(text: String) -> void:
	show_hint(text)

func hide_hint_with_animation() -> void:
	hide_hint()
