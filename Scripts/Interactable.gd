# Interactable.gd - Sığınaktaki etkileşimli nesnelerin ortak tabanı
# Alt sınıflar get_hint() ve interact() fonksiyonlarını uygular.
class_name Interactable
extends Node2D

@export var dialogue_ui_path: NodePath
@export var interaction_cooldown: float = 0.4

@onready var dialogue_ui: Node = get_node_or_null(dialogue_ui_path)
@onready var interaction_area: Area2D = get_node_or_null("Area2D")

var player_inside := false
var player_ref: CharacterBody2D = null
var _cooldown := false

func _ready() -> void:
	if dialogue_ui == null:
		dialogue_ui = get_tree().get_first_node_in_group("dialogue_ui")
	if interaction_area:
		if not interaction_area.body_entered.is_connected(_on_area_2d_body_entered):
			interaction_area.body_entered.connect(_on_area_2d_body_entered)
		if not interaction_area.body_exited.is_connected(_on_area_2d_body_exited):
			interaction_area.body_exited.connect(_on_area_2d_body_exited)

func _process(_delta: float) -> void:
	if player_inside and not _cooldown and Input.is_action_just_pressed("interact") and can_interact():
		_cooldown = true
		InteractionHUD.hide_hint()
		interact()
		await get_tree().create_timer(interaction_cooldown).timeout
		_cooldown = false

# ==================================================
# ALT SINIFLAR İÇİN
# ==================================================
func get_hint() -> String:
	return "[E] Etkileşim"

func interact() -> void:
	pass

func can_interact() -> bool:
	if player_ref == null:
		return false
	return not (player_ref.is_dead or player_ref.is_unconscious or player_ref.is_sleeping or player_ref.ui_blocked)

# ==================================================
# YARDIMCILAR
# ==================================================
func refresh_hint() -> void:
	if player_inside and can_interact():
		InteractionHUD.show_hint(get_hint())

func show_message(text: String, duration: float = 2.5) -> void:
	if dialogue_ui and dialogue_ui.has_method("show_dialogue_for_time"):
		dialogue_ui.show_dialogue_for_time(text, duration)

func _on_area_2d_body_entered(body: Node) -> void:
	if body.is_in_group("player"):
		player_inside = true
		player_ref = body
		refresh_hint()

func _on_area_2d_body_exited(body: Node) -> void:
	if body.is_in_group("player"):
		player_inside = false
		player_ref = null
		InteractionHUD.hide_hint()
