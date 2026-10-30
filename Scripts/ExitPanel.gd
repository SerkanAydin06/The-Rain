extends Control

# ==================================================
# SIGNALS
# ==================================================
signal panel_shown
signal panel_hidden
signal exit_confirmed(hours: int)

# ==================================================
# UI REFERENCES
# ==================================================
@export var loading_box_path: NodePath
@export var result_box_path: NodePath
@export var outside_panel_path: NodePath

@onready var title_label: Label = $MainMargin/MainVBox/TitleLabel
@onready var time_label: Label = $MainMargin/MainVBox/TimeRow/TimeLabel
@onready var risk_label: Label = $MainMargin/MainVBox/InfoVBox/RiskLabel
@onready var suit_label: Label = $MainMargin/MainVBox/InfoVBox/SuitLabel

@onready var btn_time_plus: Button = $MainMargin/MainVBox/TimeRow/BtnTimePlus
@onready var btn_time_minus: Button = $MainMargin/MainVBox/TimeRow/BtnTimeMinus
@onready var btn_exit: Button = $MainMargin/MainVBox/ButtonsRow/BtnExit
@onready var btn_cancel: Button = $MainMargin/MainVBox/ButtonsRow/BtnCancel

@onready var loading_box: Control = get_node_or_null(loading_box_path)
@onready var loading_title: Label = loading_box.get_node("LoadingTitle") if loading_box else null
@onready var loading_text: Label = loading_box.get_node("LoadingText") if loading_box else null

@onready var result_box: Control = get_node_or_null(result_box_path)
@onready var result_title: Label = result_box.get_node("MarginContainer/VBoxContainer/ResultTitle") if result_box else null
@onready var result_text: RichTextLabel = result_box.get_node("MarginContainer/VBoxContainer/ResultText") if result_box else null
@onready var btn_ok: Button = result_box.get_node("MarginContainer/VBoxContainer/BtnOk") if result_box else null

@onready var outside_panel: Control = get_node_or_null(outside_panel_path)

# ==================================================
# CONFIGURATION
# ==================================================
@export_category("Exit Settings")
@export_range(1, 12, 1) var min_hours: int = 1
@export_range(1, 24, 1) var max_hours: int = 8
@export_range(0, 100, 1) var base_risk: int = 20
@export_range(1, 50, 1) var risk_per_hour: int = 10

# ==================================================
# RUNTIME VARIABLES
# ==================================================
var player: CharacterBody2D = null
var exit_hours: int = 3
var is_initialized: bool = false

# ==================================================
# LIFECYCLE
# ==================================================
func _ready() -> void:
	_initialize_ui()
	_connect_signals()
	_hide_all_subpanels()

func _initialize_ui() -> void:
	hide()
	modulate = Color.TRANSPARENT
	
	if loading_box:
		loading_box.hide()
		_set_loading_text("DIŞARI ÇIKILIYOR...", "Hazırlanıyor...")
	
	if result_box:
		result_box.hide()
		result_box.modulate = Color.TRANSPARENT
	
	is_initialized = true
	print_debug("[ExitPanel] UI initialized")

func _connect_signals() -> void:
	# Button connections
	_safe_connect(btn_exit, _on_exit_pressed)
	_safe_connect(btn_cancel, _on_cancel_pressed)
	_safe_connect(btn_time_plus, _on_time_plus)
	_safe_connect(btn_time_minus, _on_time_minus)
	
	if btn_ok:
		_safe_connect(btn_ok, _on_result_ok)
	
	# GameState connections
	if GameState.inventory_changed.is_connected(_on_game_state_changed):
		GameState.inventory_changed.disconnect(_on_game_state_changed)
	GameState.inventory_changed.connect(_on_game_state_changed)

func _safe_connect(node: Button, method: Callable) -> void:
	if node and not node.pressed.is_connected(method):
		node.pressed.connect(method)
	elif not node:
		push_warning("[ExitPanel] Attempted to connect null node")

# ==================================================
# PUBLIC API
# ==================================================
func show_panel() -> void:
	if not is_initialized:
		_initialize_ui()
	
	_find_player()
	
	if not _validate_player_state():
		_show_error_state()
		return
	
	_calculate_initial_hours()
	_update_ui()
	_animate_show()

func hide_panel() -> void:
	_animate_hide()
	_reset_player_block()
	panel_hidden.emit()

# ==================================================
# CORE LOGIC
# ==================================================
func _find_player() -> void:
	player = get_tree().get_first_node_in_group("player")
	
	if not player:
		print_debug("[ExitPanel] Player not found, searching...")
		await get_tree().process_frame
		player = get_tree().get_first_node_in_group("player")
	
	if player:
		print_debug("[ExitPanel] Player found: HP=", player.health, 
				   " Hunger=", player.hunger, " Energy=", player.energy)
	else:
		print_debug("[ExitPanel] ❌ Player could not be located")

func _validate_player_state() -> bool:
	if not player:
		return false
	
	if player.health <= 0:
		print_debug("[ExitPanel] Player health too low")
		return false
	
	return true

func _calculate_initial_hours() -> void:
	var max_allowed = _calculate_max_allowed_hours()
	exit_hours = clamp(exit_hours, min_hours, max_allowed)
	
	print_debug("[ExitPanel] Initial hours: ", exit_hours, 
			   " (max allowed: ", max_allowed, ")")

func _calculate_max_allowed_hours() -> int:
	if not player:
		return min_hours
	
	var energy_factor = max(0, floor((player.energy - 10) / 8.0))
	var hunger_factor = max(0, floor((player.hunger - 10) / 5.0))
	
	var allowed = min(energy_factor, hunger_factor)
	allowed = max(allowed, min_hours)
	allowed = min(allowed, max_hours)
	
	return int(allowed)

func _calculate_risk() -> int:
	return base_risk + (exit_hours - 1) * risk_per_hour

# ==================================================
# UI UPDATES
# ==================================================
func _update_ui() -> void:
	if not is_initialized:
		return
	
	var risk = _calculate_risk()
	var max_allowed = _calculate_max_allowed_hours()
	
	# Update labels with safe null checks
	_set_label_text(time_label, "Süre: %d Saat" % exit_hours)
	_set_label_text(risk_label, "Tehlike: %d%%" % risk)
	_set_label_text(suit_label, "Giysi: %d%%" % GameState.suit_durability)
	
	# Update button states
	btn_exit.disabled = (exit_hours > max_allowed)
	btn_time_plus.disabled = (exit_hours >= min(max_hours, max_allowed))
	btn_time_minus.disabled = (exit_hours <= min_hours)
	
	print_debug("[ExitPanel] UI Updated - Hours: ", exit_hours, 
			   " Risk: ", risk, " Suit: ", GameState.suit_durability)

func _set_label_text(label: Label, text: String) -> void:
	if label:
		label.text = text
	else:
		print_debug("[ExitPanel] Attempted to update null label")

func _set_loading_text(title: String, text: String = "") -> void:
	if loading_title:
		loading_title.text = title
	if loading_text and not text.is_empty():
		loading_text.text = text

func _show_error_state() -> void:
	_set_label_text(time_label, "Durumun dışarı çıkmak için çok kötü!")
	_set_label_text(risk_label, "Tehlike: ÇOK YÜKSEK")
	_set_label_text(suit_label, "Giysi: %d%%" % GameState.suit_durability)
	
	btn_exit.disabled = true
	btn_time_plus.disabled = true
	btn_time_minus.disabled = true
	
	show()

# ==================================================
# ANIMATIONS
# ==================================================
func _animate_show() -> void:
	GameState.game_paused = true
	
	if player:
		player.ui_blocked = true
	
	show()
	
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.WHITE, 0.3)\
		 .set_ease(Tween.EASE_OUT)\
		 .set_trans(Tween.TRANS_CUBIC)
	
	await tween.finished
	panel_shown.emit()
	print_debug("[ExitPanel] Panel shown animation complete")

func _hide_all_subpanels() -> void:
	if loading_box:
		loading_box.hide()
	if result_box:
		result_box.hide()

# ==================================================
# BUTTON HANDLERS
# ==================================================
func _on_time_plus() -> void:
	var max_allowed = _calculate_max_allowed_hours()
	if exit_hours < min(max_hours, max_allowed):
		exit_hours += 1
		_update_ui()
		_play_button_sound()

func _on_time_minus() -> void:
	if exit_hours > min_hours:
		exit_hours -= 1
		_update_ui()
		_play_button_sound()

func _on_cancel_pressed() -> void:
	_play_button_sound()
	hide_panel()

func _on_exit_pressed() -> void:
	if not player or not _validate_exit_conditions():
		return
	
	_play_button_sound()
	_prepare_for_exit()
	await _simulate_exit()
	_show_results()

func _on_result_ok() -> void:
	_play_button_sound()
	_hide_result_box()
	hide_panel()

# ==================================================
# EXIT FLOW
# ==================================================
func _validate_exit_conditions() -> bool:
	var max_allowed = _calculate_max_allowed_hours()
	
	if exit_hours > max_allowed:
		print_debug("[ExitPanel] Exit validation failed: ", 
				   exit_hours, " > ", max_allowed)
		return false
	
	if GameState.suit_durability <= 0:
		print_debug("[ExitPanel] Exit validation failed: Suit durability 0")
		return false
	
	return true

func _prepare_for_exit() -> void:
	
	if player:
		player.ui_blocked = true
	
	# Butonları devre dışı bırak
	btn_exit.disabled = true
	btn_cancel.disabled = true
	btn_time_plus.disabled = true
	btn_time_minus.disabled = true
	
	print_debug("[ExitPanel] Preparing for exit: ", exit_hours, " hours")

func _animate_hide() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate", Color.TRANSPARENT, 0.2)\
		 .set_ease(Tween.EASE_IN)\
		 .set_trans(Tween.TRANS_CUBIC)
	
	await tween.finished
	hide()

func _simulate_exit() -> void:
	_show_loading_screen()
	
	await get_tree().create_timer(1.0).timeout
	
	_hide_loading_screen()
	hide()
	
	if outside_panel and outside_panel.has_method("start_outside"):
		exit_confirmed.emit(exit_hours)
		await outside_panel.start_outside(exit_hours)
	else:
		push_error("[ExitPanel] OutsidePanel not found or missing method")
		await get_tree().create_timer(2.0).timeout

func _show_results() -> void:
	if not result_box or not player or not outside_panel:
		return
	
	var collected = {}
	if outside_panel and "last_collected" in outside_panel:
		collected = outside_panel.last_collected
	else:
		print_debug("[ExitPanel] OutsidePanel'de last_collected bulunamadı")
	
	if result_text:
		var report = _generate_result_report(collected)
		result_text.text = report
	
	_animate_result_box()

# ==================================================
# RESULT GENERATION
# ==================================================
func _generate_result_report(collected: Dictionary) -> String:
	var report := "[center][b][color=#3498db]🎯 DIŞARI ÇIKIŞ RAPORU[/color][/b][/center]\n\n"
	
	# Trip summary
	report += "[b]Süre:[/b] %d Saat\n" % exit_hours
	report += "[b]Durum:[/b] [color=#e74c3c]HP %d[/color] | [color=#e67e22]Açlık %d[/color]\n\n" % [
		player.health, 
		player.hunger
	]
	
	# Collected items
	report += "[b][color=#2ecc71]📦 BU GEZİDE TOPLANANLAR:[/color][/b]\n"
	
	var found_items := false
	var items := [
		{"key": "food", "name": "Yiyecek", "color": "#2ecc71"},
		{"key": "battery", "name": "Pil", "color": "#3498db"},
		{"key": "medkit", "name": "Medkit", "color": "#e74c3c"},
		{"key": "scrap", "name": "Parça", "color": "#f39c12"}
	]
	
	for item in items:
		var amount = collected.get(item.key, 0)
		if amount > 0:
			report += "• %s: [color=%s]+%d[/color]\n" % [item.name, item.color, amount]
			found_items = true
	
	if not found_items:
		report += "[color=#95a5a6]Kayda değer bir şey bulunamadı.[/color]\n"
	
	# Suit status
	report += "\n[color=#f1c40f]🛡️ Kalan Giysi Dayanıklılığı: %d%%[/color]" % GameState.suit_durability
	
	return report

# ==================================================
# UI STATE MANAGEMENT
# ==================================================
func _show_loading_screen() -> void:
	if loading_box:
		loading_box.show()
		loading_box.modulate = Color.TRANSPARENT
		
		var tween = create_tween()
		tween.tween_property(loading_box, "modulate", Color.WHITE, 0.3)

func _hide_loading_screen() -> void:
	if loading_box:
		var tween = create_tween()
		tween.tween_property(loading_box, "modulate", Color.TRANSPARENT, 0.3)
		await tween.finished
		loading_box.hide()

func _animate_result_box() -> void:
	if result_box:
		result_box.show()
		result_box.modulate = Color.TRANSPARENT
		
		var tween = create_tween()
		tween.tween_property(result_box, "modulate", Color.WHITE, 0.3)\
			 .set_ease(Tween.EASE_OUT)\
			 .set_trans(Tween.TRANS_CUBIC)

func _hide_result_box() -> void:
	if result_box:
		var tween = create_tween()
		tween.tween_property(result_box, "modulate", Color.TRANSPARENT, 0.2)\
			 .set_ease(Tween.EASE_IN)
		
		await tween.finished
		result_box.hide()

func _reset_player_block() -> void:
	if player:
		player.ui_blocked = false

# ==================================================
# HELPER FUNCTIONS
# ==================================================
func _play_button_sound() -> void:
	# Placeholder for sound system integration
	# AudioManager.play_sound("button_click")
	pass

func _on_game_state_changed() -> void:
	if visible:
		_update_ui()

# ==================================================
# DEBUG & DEVELOPMENT
# ==================================================
func _debug_print_state() -> void:
	print_debug("=== EXITPANEL DEBUG ===")
	print_debug("Visible: ", visible)
	print_debug("Player: ", "Found" if player else "Not found")
	print_debug("Exit Hours: ", exit_hours)
	print_debug("Max Allowed: ", _calculate_max_allowed_hours())
	print_debug("Suit Durability: ", GameState.suit_durability)
	print_debug("Game Paused: ", GameState.game_paused)
	print_debug("======================")
