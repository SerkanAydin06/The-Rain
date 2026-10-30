# Workbench.gd - Üretim tezgahı: üretim panelini açar
extends Interactable

@export var workbench_name: String = "Üretim tezgahı"
@export var workbench_tier: int = 1  # Yükseltmelerle CraftingManager.workbench_level artar

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")

var pulse_tween: Tween = null

func _ready() -> void:
	super._ready()
	_update_visuals()

func get_hint() -> String:
	return "[E] %s" % workbench_name

func interact() -> void:
	var panel := _get_panel()
	if panel == null:
		show_message("Üretim paneli bulunamadı.")
		return
	if not panel.panel_closed.is_connected(_on_panel_closed):
		panel.panel_closed.connect(_on_panel_closed)
	player_ref.ui_blocked = true
	panel.show_panel(max(workbench_tier, CraftingManager.workbench_level))

func _get_panel() -> Node:
	return get_tree().root.find_child("CraftingPanel", true, false)

func _on_panel_closed() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.ui_blocked = false
	_update_visuals()
	refresh_hint()

func _update_visuals() -> void:
	# Tezgah seviyesi arttıkça görünüm değişir
	if not sprite:
		return
	if pulse_tween and pulse_tween.is_valid():
		pulse_tween.kill()
	match max(workbench_tier, CraftingManager.workbench_level):
		1:
			sprite.modulate = Color(1, 1, 1)
		2:
			sprite.modulate = Color(0.9, 0.95, 1.1)
		_:
			sprite.modulate = Color(0.8, 0.9, 1.2)
			pulse_tween = create_tween().set_loops()
			pulse_tween.tween_property(sprite, "modulate", Color(0.9, 1.0, 1.4), 1.5).set_trans(Tween.TRANS_SINE)
			pulse_tween.tween_property(sprite, "modulate", Color(0.8, 0.9, 1.2), 1.5).set_trans(Tween.TRANS_SINE)
