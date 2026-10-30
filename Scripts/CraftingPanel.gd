# CraftingPanel.gd - Üretim tezgahı arayüzü (tarif listesi + ayrıntı paneli)
extends CanvasLayer

signal panel_closed

const B := "Control/Center/MainPanel/VBox/"
const D := B + "Body/Detail/VBox/"

const CATEGORY_NAMES := {"medical": "Medikal", "electronic": "Elektronik", "mechanical": "Mekanik"}
const SKILL_NAMES := {"medical": "Tıp", "electronics": "Elektronik", "crafting": "Zanaat", "survival": "Hayatta Kalma"}

@onready var root: Control = $Control
@onready var tier_label: Label = get_node(B + "Header/TierLabel")
@onready var skills_label: Label = get_node(B + "Header/SkillsLabel")
@onready var recipes_container: VBoxContainer = get_node(B + "Body/Left/RecipesScroll/RecipesVBox")
@onready var category_buttons := {
	"all": get_node(B + "Body/Left/CategoryTabs/AllBtn"),
	"medical": get_node(B + "Body/Left/CategoryTabs/MedicalBtn"),
	"electronic": get_node(B + "Body/Left/CategoryTabs/ElectronicBtn"),
	"mechanical": get_node(B + "Body/Left/CategoryTabs/MechanicalBtn"),
}
@onready var icon_label: Label = get_node(D + "TopRow/Icon")
@onready var name_label: Label = get_node(D + "TopRow/Titles/NameLabel")
@onready var meta_label: Label = get_node(D + "TopRow/Titles/MetaLabel")
@onready var desc_label: Label = get_node(D + "DescLabel")
@onready var materials_box: VBoxContainer = get_node(D + "Materials")
@onready var result_label: Label = get_node(D + "ResultLabel")
@onready var status_label: Label = get_node(D + "StatusLabel")
@onready var progress_container: Control = get_node(D + "ProgressContainer")
@onready var progress_label: Label = get_node(D + "ProgressContainer/ProgressLabel")
@onready var progress_bar: ProgressBar = get_node(D + "ProgressContainer/ProgressBar")
@onready var craft_btn: Button = get_node(D + "CraftBtn")
@onready var close_btn: Button = get_node(B + "Footer/CloseBtn")

var workbench_tier := 1
var selected_category := "all"
var selected_recipe := ""
var panel_visible := false
var is_crafting_in_progress := false

func _ready() -> void:
	root.hide()
	for key in category_buttons:
		category_buttons[key].pressed.connect(_select_category.bind(key))
	craft_btn.pressed.connect(_on_craft_pressed)
	close_btn.pressed.connect(hide_panel)
	CraftingManager.materials_updated.connect(_on_materials_updated)
	CraftingManager.recipe_discovered.connect(func(_id): if panel_visible: _refresh())
	GameState.inventory_changed.connect(func(): if panel_visible and not is_crafting_in_progress: _refresh())

# ==================================================
# PUBLIC API
# ==================================================
func show_panel(tier: int = 1) -> void:
	if panel_visible:
		return
	workbench_tier = max(tier, CraftingManager.workbench_level)
	CraftingManager.set_workbench_tier(workbench_tier)
	panel_visible = true
	GameState.game_paused = true
	root.show()
	root.modulate.a = 0.0
	create_tween().tween_property(root, "modulate:a", 1.0, 0.18)
	_select_category("all")

func hide_panel() -> void:
	if not panel_visible or is_crafting_in_progress:
		return
	panel_visible = false
	var tw := create_tween()
	tw.tween_property(root, "modulate:a", 0.0, 0.14)
	await tw.finished
	root.hide()
	GameState.game_paused = false
	panel_closed.emit()

func hide_panel_immediately() -> void:
	panel_visible = false
	root.hide()

# ==================================================
# LİSTE
# ==================================================
func _select_category(category: String) -> void:
	selected_category = category
	for key in category_buttons:
		category_buttons[key].set_pressed_no_signal(key == category)
	_refresh()

func _visible_recipes() -> Array:
	var list := []
	for recipe_id in CraftingManager.all_recipes:
		if recipe_id in CraftingManager.player_stats["built"]:
			continue
		var recipe: Dictionary = CraftingManager.all_recipes[recipe_id]
		if selected_category != "all" and recipe["category"] != selected_category:
			continue
		list.append(recipe_id)
	# Önce üretilebilenler, sonra tier sırası
	list.sort_custom(func(a, b):
		var sa := _state(a)
		var sb := _state(b)
		if sa != sb:
			return sa < sb
		return CraftingManager.all_recipes[a]["tier"] < CraftingManager.all_recipes[b]["tier"])
	return list

func _state(recipe_id: String) -> int:
	"""0: üretilebilir, 1: malzeme eksik, 2: kilitli"""
	if not recipe_id in CraftingManager.player_stats["discovered_recipes"]:
		return 2
	if CraftingManager.all_recipes[recipe_id]["tier"] > workbench_tier:
		return 2
	return 0 if CraftingManager.can_craft(recipe_id)["can_craft"] else 1

func _refresh() -> void:
	tier_label.text = "TIER %d" % workbench_tier
	var skills := []
	for key in CraftingManager.player_stats["skills"]:
		skills.append("%s %d" % [SKILL_NAMES.get(key, key), CraftingManager.player_stats["skills"][key]])
	skills_label.text = "  ·  ".join(skills)

	for child in recipes_container.get_children():
		child.queue_free()
	var recipes := _visible_recipes()
	if not selected_recipe in recipes:
		selected_recipe = recipes[0] if recipes.size() > 0 else ""
	for recipe_id in recipes:
		recipes_container.add_child(_create_row(recipe_id))
	_show_detail(selected_recipe)

func _create_row(recipe_id: String) -> Control:
	var recipe: Dictionary = CraftingManager.all_recipes[recipe_id]
	var state := _state(recipe_id)
	var btn := Button.new()
	btn.theme_type_variation = &"TabButton"
	btn.toggle_mode = true
	btn.button_pressed = recipe_id == selected_recipe
	btn.custom_minimum_size = Vector2(0, 56)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.add_theme_font_size_override("font_size", 18)
	var title: String = recipe["name"] if recipe_id in CraftingManager.player_stats["discovered_recipes"] else "???"
	btn.text = "  %s   %s" % [_recipe_emoji(recipe_id), title]
	if state == 0:
		btn.add_theme_color_override("font_color", UIPalette.TEXT)
	elif state == 2:
		btn.add_theme_color_override("font_color", UIPalette.TEXT_DIM)
	var tag := Label.new()
	tag.theme_type_variation = &"SmallLabel"
	tag.text = ["HAZIR", "EKSİK", "KİLİTLİ"][state]
	tag.add_theme_color_override("font_color", [UIPalette.ACCENT, UIPalette.WARNING, UIPalette.TEXT_DIM][state])
	tag.set_anchors_and_offsets_preset(Control.PRESET_CENTER_RIGHT)
	tag.offset_left = -90
	tag.offset_right = -14
	tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(tag)
	btn.pressed.connect(func():
		selected_recipe = recipe_id
		for c in recipes_container.get_children():
			c.set_pressed_no_signal(c == btn)
		_show_detail(recipe_id))
	return btn

func _recipe_emoji(recipe_id: String) -> String:
	var result: String = CraftingManager.all_recipes[recipe_id].get("result", "")
	if not result.is_empty():
		return InventoryManager.get_item_emoji(result)
	match CraftingManager.all_recipes[recipe_id].get("effect", ""):
		"repair_suit": return "🦺"
		"build_rain_collector": return "🌧"
		"workbench_tier": return "🔧"
	return "🛠"

# ==================================================
# AYRINTI
# ==================================================
func _show_detail(recipe_id: String) -> void:
	for child in materials_box.get_children():
		child.queue_free()
	if recipe_id.is_empty():
		name_label.text = "Tarif yok"
		meta_label.text = ""
		desc_label.text = "Bu kategoride tarif bulunmuyor."
		result_label.text = ""
		status_label.text = ""
		craft_btn.disabled = true
		return

	var recipe: Dictionary = CraftingManager.all_recipes[recipe_id]
	var discovered: bool = recipe_id in CraftingManager.player_stats["discovered_recipes"]
	icon_label.text = _recipe_emoji(recipe_id)
	name_label.text = recipe["name"] if discovered else "Bilinmeyen tarif"
	meta_label.text = "%s  ·  Tier %d  ·  %d saat  ·  %s %d" % [
		CATEGORY_NAMES.get(recipe["category"], recipe["category"]), recipe["tier"], max(1, ceili(recipe["craft_time"])),
		SKILL_NAMES.get(recipe.get("skill", ""), ""), recipe.get("skill_level", 1)]
	desc_label.text = recipe.get("description", "")

	for material in recipe["materials"]:
		var need: int = recipe["materials"][material]
		var have := GameState.get_item_count(material)
		materials_box.add_child(_material_row(InventoryManager.get_item_display_name(material), have, need))
	var tool: String = recipe.get("requires_tool", "")
	if not tool.is_empty():
		materials_box.add_child(_material_row(InventoryManager.get_item_display_name(tool) + "  (harcanmaz)",
			GameState.get_item_count(tool), 1))

	var result: String = recipe.get("result", "")
	result_label.text = ("SONUÇ:  %s ×%d" % [InventoryManager.get_item_display_name(result), recipe["result_amount"]]) \
		if not result.is_empty() else ("SONUÇ:  " + recipe.get("description", ""))

	var state := _state(recipe_id)
	var reason := ""
	if not discovered:
		reason = _unlock_hint(recipe)
	elif recipe["tier"] > workbench_tier:
		reason = "Tier %d tezgah gerekir. Tezgahı geliştir." % recipe["tier"]
	elif state == 1:
		reason = CraftingManager.can_craft(recipe_id)["message"]
	status_label.text = reason
	status_label.add_theme_color_override("font_color", UIPalette.WARNING if state == 1 else UIPalette.TEXT_MUTED)
	craft_btn.disabled = state != 0 or is_crafting_in_progress

func _material_row(text: String, have: int, need: int) -> Control:
	var row := HBoxContainer.new()
	var name_lbl := Label.new()
	name_lbl.text = text
	name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_lbl.add_theme_font_size_override("font_size", 18)
	var count := Label.new()
	count.theme_type_variation = &"ValueLabel"
	count.text = "%d / %d" % [have, need]
	count.add_theme_color_override("font_color", UIPalette.ACCENT if have >= need else UIPalette.DANGER)
	row.add_child(name_lbl)
	row.add_child(count)
	return row

func _unlock_hint(recipe: Dictionary) -> String:
	var cond: String = recipe.get("unlock_condition", "")
	if cond.begins_with("find_"):
		return "Kilitli: Planı dışarıda bulunur."
	if cond.begins_with("craft_") and cond.ends_with("_items"):
		return "Kilitli: %s üretim yaptıktan sonra açılır." % cond.split("_")[1]
	return "Kilitli."

# ==================================================
# ÜRETİM
# ==================================================
func _on_craft_pressed() -> void:
	if selected_recipe.is_empty() or is_crafting_in_progress:
		return
	is_crafting_in_progress = true
	craft_btn.disabled = true
	close_btn.disabled = true
	progress_container.visible = true
	progress_bar.value = 0
	progress_label.text = "Üretiliyor..."
	var result: Dictionary = await CraftingManager.start_crafting(selected_recipe, workbench_tier)
	is_crafting_in_progress = false
	close_btn.disabled = false
	progress_container.visible = false
	_refresh()
	status_label.text = result.get("message", "")
	status_label.add_theme_color_override("font_color", UIPalette.ACCENT if result.get("success", false) else UIPalette.DANGER)

func _on_materials_updated() -> void:
	if is_crafting_in_progress:
		progress_bar.value = CraftingManager.crafting_progress * 100.0
		progress_label.text = "Üretiliyor...  %d%%" % int(progress_bar.value)

func _unhandled_input(event: InputEvent) -> void:
	if panel_visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		hide_panel()
