# RightSideInventory.gd - Sağ taraftaki envanter paneli (TAB)
extends CanvasLayer

const SECTIONS := [
	["TÜKETİLEBİLİR", ["food", "water", "dirty_water", "medkit", "energy_drink", "battery"]],
	["TEMEL MALZEME", ["wood", "stone", "scrap", "cloth"]],
	["ORTA MALZEME", ["wire", "plastic", "metal", "chemical"]],
	["NADİR MALZEME", ["electronic", "fuel", "medicine", "component"]],
	["ÜRETİLEN", ["toolkit", "radio_part"]],
]

@onready var container: Control = $Control
@onready var items_container: VBoxContainer = $Control/VBox/ScrollContainer/VBoxContainer

var _tween: Tween

func _ready() -> void:
	container.visible = false
	GameState.inventory_changed.connect(update_display)
	update_display()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_inventory"):
		var player = get_tree().get_first_node_in_group("player")
		if player and (player.is_dead or (player.ui_blocked and not container.visible)):
			return
		toggle_inventory()
		get_viewport().set_input_as_handled()
	elif container.visible and event.is_action_pressed("ui_cancel"):
		hide_inventory()
		get_viewport().set_input_as_handled()

func toggle_inventory() -> void:
	if container.visible:
		hide_inventory()
	else:
		show_inventory()

func show_inventory() -> void:
	update_display()
	if _tween:
		_tween.kill()
	container.visible = true
	container.modulate.a = 0.0
	container.position.x += 24
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(container, "modulate:a", 1.0, 0.18)
	_tween.tween_property(container, "position:x", container.position.x - 24, 0.22)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func hide_inventory() -> void:
	if _tween:
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(container, "modulate:a", 0.0, 0.14)
	_tween.tween_callback(func(): container.visible = false)

func hide_inventory_immediately() -> void:
	container.visible = false

func update_display() -> void:
	for child in items_container.get_children():
		child.queue_free()
	for section in SECTIONS:
		var title := Label.new()
		title.text = section[0]
		title.theme_type_variation = &"SectionLabel"
		items_container.add_child(title)
		var grid := GridContainer.new()
		grid.columns = 4
		grid.add_theme_constant_override("h_separation", 8)
		grid.add_theme_constant_override("v_separation", 8)
		for item_id in section[1]:
			grid.add_child(_create_item_card(item_id))
		items_container.add_child(grid)

func _create_item_card(item_id: String) -> Control:
	var amount := GameState.get_item_count(item_id)
	var limit: int = GameState.stack_limits.get(item_id, 99)
	var card := PanelContainer.new()
	card.theme_type_variation = &"CardPanel"
	card.custom_minimum_size = Vector2(84, 84)
	card.tooltip_text = "%s\n%d / %d" % [InventoryManager.get_item_name(item_id), amount, limit]

	var vbox := VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_theme_constant_override("separation", 2)
	card.add_child(vbox)

	var tex := InventoryManager.get_item_icon(item_id)
	if tex:
		var icon := TextureRect.new()
		icon.texture = tex
		icon.custom_minimum_size = Vector2(0, 34)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		vbox.add_child(icon)
	else:
		var emoji := Label.new()
		emoji.text = InventoryManager.get_item_emoji(item_id)
		emoji.custom_minimum_size = Vector2(0, 34)
		emoji.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		emoji.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		emoji.add_theme_font_size_override("font_size", 24)
		vbox.add_child(emoji)

	var count := Label.new()
	count.text = str(amount)
	count.theme_type_variation = &"ValueLabel"
	count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if amount >= limit:
		count.add_theme_color_override("font_color", UIPalette.WARNING)
	vbox.add_child(count)

	if amount == 0:
		vbox.modulate.a = 0.35
	return card
