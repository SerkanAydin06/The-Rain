# DeathScreen.gd - Ölüm ve kurtarılma (oyun sonu) ekranı
extends CanvasLayer

const P := "Control/CenterContainer/MainPanel/VBox/"

@onready var background: ColorRect = $Control/Background
@onready var main_panel: Control = $Control/CenterContainer/MainPanel
@onready var title_label: Label = get_node(P + "TitleLabel")
@onready var reason_label: RichTextLabel = get_node(P + "ReasonLabel")
@onready var stats_vbox: VBoxContainer = get_node(P + "StatsPanel/StatsVBox")
@onready var restart_btn: Button = get_node(P + "ButtonsHBox/RestartBtn")
@onready var menu_btn: Button = get_node(P + "ButtonsHBox/MenuBtn")

# Ölüm nedeni -> [başlık, açıklama, renk]
const REASONS := {
	"starvation": ["AÇLIKTAN ÖLDÜN", "Erzakın tükendi ve vücudun daha fazla dayanamadı.", UIPalette.HUNGER],
	"dehydration": ["SUSUZLUKTAN ÖLDÜN", "Temiz su bulamadın. Yağmur her yerdeydi ama içilemezdi.", UIPalette.THIRST],
	"exhaustion": ["BİTKİN DÜŞTÜN", "Enerjin tükendi ve bir daha uyanamadın.", UIPalette.ENERGY],
	"outside": ["YAĞMURDA KAYBOLDUN", "Zehirli yağmur giysini ve seni yedi bitirdi.", UIPalette.SUIT],
	"injury": ["AĞIR YARALANDIN", "Yaraların fazla ağırdı.", UIPalette.HEALTH],
}

func _ready() -> void:
	hide()
	restart_btn.pressed.connect(_on_restart_pressed)
	menu_btn.pressed.connect(_on_menu_pressed)

# ==================================================
# PUBLIC API
# ==================================================
func show_death_screen(reason: String, stats: Dictionary = {}) -> void:
	var info: Array = REASONS.get(reason, ["ÖLDÜN", "Sığınak sessizliğe gömüldü.", UIPalette.DANGER])
	_present(info[0], info[1], info[2], stats)

func show_victory_screen(stats: Dictionary = {}) -> void:
	_present("KURTULDUN", "Kurtarma ekibi seni yağmurun ortasından çıkardı.", UIPalette.ACCENT, stats)

func _present(title: String, text: String, color: Color, stats: Dictionary) -> void:
	GameState.game_paused = true
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.ui_blocked = true
	title_label.text = title
	title_label.add_theme_color_override("font_color", color)
	reason_label.text = "[center][color=#%s]%s[/color][/center]" % [UIPalette.TEXT_MUTED.to_html(false), text]
	_fill_stats(stats)
	show()
	background.modulate.a = 0.0
	main_panel.modulate.a = 0.0
	var tw := create_tween()
	tw.tween_property(background, "modulate:a", 1.0, 1.2)
	tw.tween_property(main_panel, "modulate:a", 1.0, 0.6)
	restart_btn.grab_focus()

func _fill_stats(stats: Dictionary) -> void:
	for child in stats_vbox.get_children():
		child.queue_free()
	if stats.has("days_survived"):
		_add_stat_line("Hayatta kalınan gün", str(stats["days_survived"]))
	if stats.has("total_loot"):
		_add_stat_line("Toplanan eşya", str(stats["total_loot"]))
	if stats.has("longest_outside"):
		_add_stat_line("En uzun keşif", "%d saat" % stats["longest_outside"])
	if stats.has("total_hours_outside"):
		_add_stat_line("Toplam dışarıda", "%d saat" % stats["total_hours_outside"])

func _add_stat_line(label_text: String, value_text: String) -> void:
	var row := HBoxContainer.new()
	var label := Label.new()
	label.text = label_text
	label.theme_type_variation = &"SubLabel"
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var value := Label.new()
	value.text = value_text
	value.theme_type_variation = &"ValueLabel"
	row.add_child(label)
	row.add_child(value)
	stats_vbox.add_child(row)

# ==================================================
# BUTONLAR
# ==================================================
func _on_restart_pressed() -> void:
	await _fade_out()
	GameState.reset_game()
	get_tree().reload_current_scene()

func _on_menu_pressed() -> void:
	await _fade_out()
	GameState.game_paused = false
	get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")

func _fade_out() -> void:
	restart_btn.disabled = true
	menu_btn.disabled = true
	var tw := create_tween()
	tw.tween_property($Control, "modulate", Color.BLACK, 0.5)
	await tw.finished
