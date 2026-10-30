# HUD.gd - Oyun içi arayüz: durum barları, saat, hedef ve hızlı erişim çubuğu
extends Control

const LOW_THRESHOLD := 25.0
const HOTBAR_ITEMS := ["food", "water", "medkit", "energy_drink", "battery"]

@onready var bars := {
	"health": $Stats/Rows/HealthRow/HealthBar,
	"hunger": $Stats/Rows/HungerRow/HungerBar,
	"thirst": $Stats/Rows/ThirstRow/ThirstBar,
	"energy": $Stats/Rows/EnergyRow/EnergyBar,
	"suit": $Stats/Rows/SuitRow/SuitBar,
}
@onready var values := {
	"health": $Stats/Rows/HealthRow/HealthValue,
	"hunger": $Stats/Rows/HungerRow/HungerValue,
	"thirst": $Stats/Rows/ThirstRow/ThirstValue,
	"energy": $Stats/Rows/EnergyRow/EnergyValue,
	"suit": $Stats/Rows/SuitRow/SuitValue,
}
@onready var day_label: Label = $Clock/HBox/DayLabel
@onready var time_label: Label = $Clock/HBox/TimeLabel
@onready var phase_label: Label = $Clock/HBox/PhaseLabel
@onready var storm_chip: Label = $Chips/StormChip
@onready var dark_chip: Label = $Chips/DarkChip
@onready var rescue_chip: Label = $Chips/RescueChip
@onready var objective_text: Label = $Objective/VBox/Text
@onready var objective_bar: ProgressBar = $Objective/VBox/Progress
@onready var hotbar: HBoxContainer = $Hotbar

var _low_time := 0.0

func _ready() -> void:
	storm_chip.add_theme_stylebox_override("normal", _chip_style(UIPalette.DANGER))
	dark_chip.add_theme_stylebox_override("normal", _chip_style(UIPalette.TEXT_DIM))
	dark_chip.add_theme_color_override("font_color", UIPalette.TEXT)
	rescue_chip.add_theme_stylebox_override("normal", _chip_style(UIPalette.ACCENT))

	_on_player_stats_changed(100, 100, 100, GameState.suit_durability, 100)
	GameState.inventory_changed.connect(_on_inventory_changed)
	GameState.hour_passed.connect(func(_h, _d): _refresh_clock())
	SurvivalManager.radio_state_changed.connect(_refresh_objective)

	for item in HOTBAR_ITEMS:
		var slot: Control = hotbar.get_node("Slot_" + item)
		slot.gui_input.connect(_on_slot_input.bind(item))
		slot.mouse_entered.connect(func(): slot.theme_type_variation = &"AccentPanel")
		slot.mouse_exited.connect(func(): slot.theme_type_variation = &"CardPanel")

	_refresh_hotbar()
	_refresh_objective()
	_apply_hint_setting()
	GameSettings.changed.connect(_apply_hint_setting)
	await get_tree().process_frame
	_refresh_clock()

func _process(delta: float) -> void:
	# Kritik seviyedeki değerleri yanıp söndür
	_low_time += delta
	var pulse := 0.55 + 0.45 * sin(_low_time * 6.0)
	for key in bars:
		var low: bool = bars[key].value <= LOW_THRESHOLD
		values[key].modulate = Color(1, 0.45, 0.4, pulse) if low else Color.WHITE

# ==================================================
# DURUM
# ==================================================
func _on_player_stats_changed(h: float, n: float, e: float, s: float, t: float = 100.0) -> void:
	_set_stat("health", h)
	_set_stat("hunger", n)
	_set_stat("thirst", t)
	_set_stat("energy", e)
	_set_stat("suit", float(GameState.suit_durability))
	_refresh_clock()

func _set_stat(key: String, value: float) -> void:
	var bar: ProgressBar = bars[key]
	create_tween().tween_property(bar, "value", value, 0.25)
	values[key].text = str(roundi(value))

func _on_inventory_changed() -> void:
	_set_stat("suit", float(GameState.suit_durability))
	_refresh_hotbar()
	_refresh_objective()

# ==================================================
# SAAT
# ==================================================
func _refresh_clock() -> void:
	var hour := GameState.current_hour
	day_label.text = "GÜN %d" % GameState.current_day
	time_label.text = "%02d:00" % hour
	phase_label.text = "GECE" if SurvivalManager.is_night(hour) else "GÜNDÜZ"
	phase_label.add_theme_color_override("font_color",
		UIPalette.INFO if SurvivalManager.is_night(hour) else UIPalette.WARNING)
	storm_chip.visible = SurvivalManager.storm_active
	dark_chip.visible = SurvivalManager.is_dark()
	rescue_chip.visible = SurvivalManager.radio_called
	if SurvivalManager.radio_called:
		rescue_chip.text = "KURTARMA: %d GÜN" % max(SurvivalManager.rescue_day - GameState.current_day, 0)

# ==================================================
# HEDEF
# ==================================================
func _refresh_objective() -> void:
	objective_bar.max_value = SurvivalManager.RADIO_PARTS_REQUIRED
	objective_bar.value = SurvivalManager.radio_parts_installed
	objective_text.text = SurvivalManager.objective_text()
	_refresh_clock()

# ==================================================
# HIZLI ERİŞİM
# ==================================================
func _refresh_hotbar() -> void:
	for item in HOTBAR_ITEMS:
		var slot: Control = hotbar.get_node("Slot_" + item)
		var count := GameState.get_item_count(item)
		if item == "water":
			count += GameState.get_item_count("dirty_water")
		var count_label: Label = slot.get_node("Count")
		count_label.text = str(count)
		count_label.add_theme_color_override("font_color", UIPalette.TEXT if count > 0 else UIPalette.DANGER)
		slot.get_node("VBox").modulate.a = 1.0 if count > 0 else 0.4

func _on_slot_input(event: InputEvent, item: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("use_consumable") and item != "battery":
			var slot: Control = hotbar.get_node("Slot_" + item)
			slot.pivot_offset = slot.size / 2
			var tw := create_tween()
			tw.tween_property(slot, "scale", Vector2(0.92, 0.92), 0.05)
			tw.tween_property(slot, "scale", Vector2.ONE, 0.1)
			player.use_consumable(item)

func _apply_hint_setting() -> void:
	for item in HOTBAR_ITEMS:
		var key := hotbar.get_node_or_null("Slot_%s/Key" % item)
		if key:
			key.visible = GameSettings.show_hints

func _chip_style(color: Color) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(4)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 2
	sb.content_margin_bottom = 2
	return sb
