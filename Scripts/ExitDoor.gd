extends Node2D

@export var exit_panel_path: NodePath
@onready var exit_panel = get_node_or_null(exit_panel_path)

var player_inside := false

func _ready():
	# Artık local hint yok
	pass

func _process(_delta):
	if player_inside and Input.is_action_just_pressed("interact"):
		if exit_panel:
			# Önce hint'i kapat
			var hud = get_node_or_null("/root/InteractionHUD")
			if hud:
				hud.hide_hint()
			
			# Panel'i göster
			exit_panel.show_panel()

func _on_area_2d_body_entered(body):
	if body.is_in_group("player"):
		player_inside = true
		
		# InteractionHUD'da göster
		var hud = get_node_or_null("/root/InteractionHUD")
		if hud:
			hud.show_hint("[E] Dışarı Çık")

func _on_area_2d_body_exited(body):
	if body.is_in_group("player"):
		player_inside = false
		
		# InteractionHUD'u gizle
		var hud = get_node_or_null("/root/InteractionHUD")
		if hud:
			hud.hide_hint()
