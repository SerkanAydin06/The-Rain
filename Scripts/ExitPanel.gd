# ExitPanel.gd - Dışarı çıkış penceresi (süre seçimi, yükleme ve keşif raporu)
extends Control

signal panel_shown
signal panel_hidden
signal exit_confirmed(hours: int)

@export var loading_box_path: NodePath
@export var result_box_path: NodePath
@export var outside_panel_path: NodePath

@export_category("Exit Settings")
@export_range(1, 12, 1) var min_hours: int = 1
@export_range(1, 24, 1) var max_hours: int = 8

const BODY := "Center/Card/VBox/"

@onready var card: Control = $Center/Card
@onready var time_label: Label = get_node(BODY + "TimeRow/TimeBox/TimeLabel")
@onready var btn_time_minus: Button = get_node(BODY + "TimeRow/BtnTimeMinus")
@onready var btn_time_plus: Button = get_node(BODY + "TimeRow/BtnTimePlus")
@onready var risk_bar: ProgressBar = get_node(BODY + "Info/Grid/RiskBar")
@onready var risk_label: Label = get_node(BODY + "Info/Grid/RiskLabel")
@onready var suit_bar: ProgressBar = get_node(BODY + "Info/Grid/SuitBar")
@onready var suit_label: Label = get_node(BODY + "Info/Grid/SuitLabel")
@onready var cost_label: Label = get_node(BODY + "CostLabel")
@onready var warning_label: Label = get_node(BODY + "WarningLabel")
@onready var btn_exit: Button = get_node(BODY + "ButtonsRow/BtnExit")
@onready var btn_cancel: Button = get_node(BODY + "ButtonsRow/BtnCancel")

@onready var loading_box: Control = get_node_or_null(loading_box_path)
@onready var loading_text: Label = loading_box.get_node("Center/VBox/LoadingText") if loading_box else null
@onready var result_box: Control = get_node_or_null(result_box_path)
@onready var result_text: RichTextLabel = result_box.get_node("Center/Card/VBox/ResultText") if result_box else null
@onready var btn_ok: Button = result_box.get_node("Center/Card/VBox/Footer/BtnOk") if result_box else null
@onready var outside_panel: Control = get_node_or_null(outside_panel_path)

var player: CharacterBody2D = null
var exit_hours: int = 3
var _busy := false

func _ready() -> void:
	hide()
	if loading_box:
		loading_box.hide()
	if result_box:
		result_box.hide()
	btn_exit.pressed.connect(_on_exit_pressed)
	btn_cancel.pressed.connect(hide_panel)
	btn_time_plus.pressed.connect(_change_hours.bind(1))
	btn_time_minus.pressed.connect(_change_hours.bind(-1))
	if btn_ok:
		btn_ok.pressed.connect(_on_result_ok)
	GameState.inventory_changed.connect(func(): if visible: _update_ui())

# ==================================================
# PUBLIC API
# ==================================================
func show_panel() -> void:
	player = get_tree().get_first_node_in_group("player")
	if player == null or _busy:
		return
	exit_hours = clamp(exit_hours, min_hours, max(_max_allowed_hours(), min_hours))
	_update_ui()
	GameState.game_paused = true
	player.ui_blocked = true
	show()
	modulate.a = 0.0
	card.scale = Vector2(0.96, 0.96)
	card.pivot_offset = card.size / 2
	var tw := create_tween().set_parallel(true)
	tw.tween_property(self, "modulate:a", 1.0, 0.18)
	tw.tween_property(card, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	if btn_exit.disabled:
		btn_cancel.grab_focus()
	else:
		btn_exit.grab_focus()
	panel_shown.emit()

func hide_panel() -> void:
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.15)
	await tw.finished
	hide()
	GameState.game_paused = false
	if player:
		player.ui_blocked = false
	panel_hidden.emit()

# ==================================================
# HESAPLAMALAR
# ==================================================
func _max_allowed_hours() -> int:
	if not player:
		return min_hours
	var energy_factor = max(0, floor((player.energy - 10) / 8.0))
	var hunger_factor = max(0, floor((player.hunger - 10) / 5.0))
	var thirst_factor = max(0, floor((player.thirst - 10) / 6.0))
	return int(clamp(min(energy_factor, min(hunger_factor, thirst_factor)), 0, max_hours))

func _change_hours(delta: int) -> void:
	exit_hours = clamp(exit_hours + delta, min_hours, max_hours)
	_update_ui()

func _update_ui() -> void:
	var allowed := _max_allowed_hours()
	var risk := SurvivalManager.get_outside_risk(exit_hours)
	time_label.text = "%d SAAT" % exit_hours
	risk_bar.value = risk
	risk_label.text = "%d%%" % risk
	suit_bar.value = GameState.suit_durability
	suit_label.text = "%d%%" % GameState.suit_durability
	cost_label.text = "Tahmini tüketim:  -%d Açlık  ·  -%d Su  ·  -%d Enerji  ·  -%d Giysi" % [
		exit_hours * 5, exit_hours * 6, exit_hours * 8, exit_hours * (3 if SurvivalManager.storm_active else 2)]

	var warning := ""
	if GameState.suit_durability <= 0:
		warning = "Koruyucu giysin parçalanmış. Önce tezgahta onar."
	elif allowed < exit_hours:
		warning = "Bu kadar uzun dayanamazsın. Önce ye, iç ya da dinlen. (En fazla %d saat)" % allowed
	elif SurvivalManager.storm_active:
		warning = "Fırtına var: dışarısı bugün çok daha tehlikeli."
	warning_label.text = warning
	warning_label.visible = not warning.is_empty()

	btn_exit.disabled = GameState.suit_durability <= 0 or allowed < exit_hours
	btn_time_plus.disabled = exit_hours >= max_hours
	btn_time_minus.disabled = exit_hours <= min_hours

# ==================================================
# ÇIKIŞ AKIŞI
# ==================================================
func _on_exit_pressed() -> void:
	if _busy or btn_exit.disabled:
		return
	_busy = true
	hide()
	if loading_box:
		loading_text.text = ["Giysini kontrol ediyorsun...", "Maskeni takıyorsun...", "Kapıyı açıyorsun..."].pick_random()
		loading_box.show()
		loading_box.modulate.a = 0.0
		await create_tween().tween_property(loading_box, "modulate:a", 1.0, 0.3).finished
		await get_tree().create_timer(0.8).timeout
		loading_box.hide()

	if outside_panel and outside_panel.has_method("start_outside"):
		exit_confirmed.emit(exit_hours)
		await outside_panel.start_outside(exit_hours)

	_busy = false
	if player and player.is_dead:
		return
	_show_results()

func _show_results() -> void:
	if not result_box:
		hide_panel()
		return
	var collected: Dictionary = outside_panel.last_collected if outside_panel else {}
	result_text.text = _generate_result_report(collected)
	result_box.show()
	result_box.modulate.a = 0.0
	create_tween().tween_property(result_box, "modulate:a", 1.0, 0.25)
	btn_ok.grab_focus()

func _on_result_ok() -> void:
	var tw := create_tween()
	tw.tween_property(result_box, "modulate:a", 0.0, 0.15)
	await tw.finished
	result_box.hide()
	GameState.game_paused = false
	if player:
		player.ui_blocked = false
	panel_hidden.emit()

func _generate_result_report(collected: Dictionary) -> String:
	var muted := UIPalette.TEXT_MUTED.to_html(false)
	var accent := UIPalette.ACCENT.to_html(false)
	var report := "[color=#%s]%d saat dışarıda kaldın.[/color]\n\n" % [muted, exit_hours]
	report += "[b]TOPLANANLAR[/b]\n"
	var found := false
	for key in collected:
		if collected[key] > 0:
			report += "  %s  [color=#%s]+%d[/color]\n" % [InventoryManager.get_item_display_name(key), accent, collected[key]]
			found = true
	if not found:
		report += "  [color=#%s]Kayda değer bir şey bulunamadı.[/color]\n" % muted
	report += "\n[b]DURUM[/b]\n"
	report += "  Can %d  ·  Açlık %d  ·  Su %d  ·  Enerji %d  ·  Giysi %d%%" % [
		player.health, player.hunger, player.thirst, player.energy, GameState.suit_durability]
	return report

func _unhandled_input(event: InputEvent) -> void:
	if visible and not _busy and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		hide_panel()
