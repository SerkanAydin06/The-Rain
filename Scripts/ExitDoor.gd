# ExitDoor.gd - Sığınak kapısı: dışarı çıkış penceresini açar
extends Interactable

@export var exit_panel_path: NodePath
@onready var exit_panel: Node = get_node_or_null(exit_panel_path)

func _ready() -> void:
	super._ready()
	if exit_panel and exit_panel.has_signal("panel_hidden"):
		exit_panel.panel_hidden.connect(refresh_hint)

func get_hint() -> String:
	return "[E] Dışarı çık"

func interact() -> void:
	if exit_panel:
		exit_panel.show_panel()
