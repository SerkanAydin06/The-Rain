extends Node

# ==================================================
# SIGNALS
# ==================================================
signal crafting_completed(item_name: String, amount: int)
signal recipe_discovered(recipe_id: String)
signal crafting_failed(reason: String)
signal materials_updated()

# ==================================================
# RECIPE DATABASE - GÜNCELLENMİŞ
# ==================================================
var all_recipes: Dictionary = {
	# MEDKIT - Tıbbi malzemeler
	"medkit": {
		"name": "Medkit",
		"category": "medical",
		"tier": 1,
		"materials": {
			"cloth": 3,
			"scrap": 1,
			"chemical": 1
		},
		"result": "medkit",
		"result_amount": 1,
		"craft_time": 2.0,  # saat
		"unlocked": true,
		"skill": "medical",
		"skill_level": 1,
		"description": "Temel ilk yardım kiti"
	},
	
	# BATTERY - Elektronik
	"battery": {
		"name": "Pil",
		"category": "electronic",
		"tier": 1,
		"materials": {
			"scrap": 2,
			"metal": 1,
			"wire": 1
		},
		"result": "battery",
		"result_amount": 1,
		"craft_time": 1.5,
		"unlocked": true,
		"skill": "electronics",
		"skill_level": 1,
		"description": "Şarj edilebilir pil"
	},
	
	# TOOLKIT - Mekanik
	"toolkit": {
		"name": "Alet Çantası",
		"category": "mechanical",
		"tier": 2,
		"materials": {
			"scrap": 4,
			"metal": 2,
			"cloth": 2,
			"wood": 1
		},
		"result": "toolkit",
		"result_amount": 1,
		"craft_time": 3.0,
		"unlocked": false,
		"skill": "crafting",
		"skill_level": 1,
		"unlock_condition": "craft_3_items",
		"description": "Tamir ve inşaat aletleri"
	},
	
	# RADIO PART - İleri Elektronik
	"radio_part": {
		"name": "Radyo Parçası",
		"category": "electronic",
		"tier": 3,
		"materials": {
			"electronic": 1,
			"wire": 3,
			"scrap": 2,
			"metal": 1
		},
		"result": "radio_part",
		"result_amount": 1,
		"craft_time": 4.0,
		"unlocked": false,
		"skill": "electronics",
		"skill_level": 2,
		"unlock_condition": "find_blueprint_radio",
		"description": "Radyo onarım parçası (telsiz için 3 gerekir)"
	},
	
	# SU ARITMA - kimyasal ile
	"water_purify": {
		"name": "Su Arıt (Kimyasal)",
		"category": "medical",
		"tier": 1,
		"materials": {"dirty_water": 2, "chemical": 1},
		"result": "water",
		"result_amount": 2,
		"craft_time": 1.0,
		"unlocked": true,
		"skill": "medical",
		"skill_level": 1,
		"description": "Kirli suyu içilebilir hale getirir"
	},
	
	# SU KAYNATMA - odun ile
	"water_boil": {
		"name": "Su Kaynat",
		"category": "mechanical",
		"tier": 1,
		"materials": {"dirty_water": 1, "wood": 2},
		"result": "water",
		"result_amount": 1,
		"craft_time": 1.0,
		"unlocked": true,
		"skill": "survival",
		"skill_level": 1,
		"description": "Odun yakarak kirli suyu kaynat"
	},
	
	# GİYSİ YAMASI
	"suit_patch": {
		"name": "Koruyucu Giysi Yaması",
		"category": "mechanical",
		"tier": 1,
		"materials": {"cloth": 3, "plastic": 2, "chemical": 1},
		"result": "",
		"result_amount": 0,
		"effect": "repair_suit",
		"effect_amount": 30,
		"craft_time": 2.0,
		"unlocked": true,
		"skill": "crafting",
		"skill_level": 1,
		"description": "Koruyucu giysiyi %30 onarır"
	},
	
	# YAĞMUR TOPLAYICI
	"rain_collector": {
		"name": "Yağmur Toplayıcı",
		"category": "mechanical",
		"tier": 1,
		"materials": {"plastic": 3, "scrap": 3, "wood": 2},
		"result": "",
		"result_amount": 0,
		"effect": "build_rain_collector",
		"one_time": true,
		"craft_time": 3.0,
		"unlocked": true,
		"skill": "survival",
		"skill_level": 1,
		"description": "Her gün 2 kirli su toplar"
	},
	
	# ÇALIŞMA TEZGAHI YÜKSELTME
	"workbench_upgrade_2": {
		"name": "Tezgahı Geliştir (Tier 2)",
		"category": "mechanical",
		"tier": 1,
		"materials": {"scrap": 6, "metal": 3, "wood": 4},
		"requires_tool": "toolkit",
		"result": "",
		"result_amount": 0,
		"effect": "workbench_tier",
		"effect_amount": 2,
		"one_time": true,
		"craft_time": 4.0,
		"unlocked": true,
		"skill": "crafting",
		"skill_level": 1,
		"description": "Tier 2 tarifleri açar (alet çantası gerekir)"
	},
	"workbench_upgrade_3": {
		"name": "Tezgahı Geliştir (Tier 3)",
		"category": "mechanical",
		"tier": 2,
		"materials": {"metal": 4, "wire": 3, "component": 1, "electronic": 1},
		"requires_tool": "toolkit",
		"result": "",
		"result_amount": 0,
		"effect": "workbench_tier",
		"effect_amount": 3,
		"one_time": true,
		"craft_time": 5.0,
		"unlocked": true,
		"skill": "crafting",
		"skill_level": 1,
		"description": "Tier 3 tarifleri açar (radyo parçası)"
	}
}

const XP_PER_LEVEL := 20
const MAX_SKILL_LEVEL := 5

# ==================================================
# PLAYER STATS & UNLOCKS
# ==================================================
var player_stats: Dictionary = {
	"crafted_items": {},  # {"medkit": 5, "battery": 3}
	"skills": {
		"medical": 1,
		"electronics": 1,
		"crafting": 1,
		"survival": 1
	},
	"skill_xp": {},
	"discovered_recipes": [],  # _check_recipe_unlocks ile doldurulur
	"built": [],  # one_time tarifler
	"found_blueprints": [],
	"total_crafts": 0
}

# ==================================================
# CRAFTING STATE
# ==================================================
var current_crafting_item: String = ""
var crafting_progress: float = 0.0
var is_crafting: bool = false
var current_workbench_tier: int = 1
var workbench_level: int = 1  # Yükseltmelerle kalıcı olarak artar

# ==================================================
# LIFECYCLE
# ==================================================
func _ready() -> void:
	print("🛠️ CraftingManager hazır")
	print("   - Toplam recipe: ", all_recipes.size())
	print("   - Açık recipe: ", player_stats["discovered_recipes"].size())
	print("   - Başlangıç recipe'leri: ", player_stats["discovered_recipes"])
	
	# Oyun başında unlock kontrolleri
	_check_recipe_unlocks()
	
	# GameState bağlantısı
	if GameState:
		GameState.inventory_changed.connect(_on_inventory_changed)

# ==================================================
# PUBLIC API - YENİ DÜZEN
# ==================================================
func get_available_recipes() -> Array:
	"""Oyuncunun craft edebileceği tarifleri döndür"""
	var available: Array = []
	
	for recipe_id in player_stats["discovered_recipes"]:
		var recipe = all_recipes.get(recipe_id)
		if recipe:
			# Malzeme kontrolü
			if can_craft(recipe_id)["can_craft"]:
				available.append(recipe_id)
	
	return available

func get_recipe_info(recipe_id: String) -> Dictionary:
	"""Tarif detaylarını döndür"""
	var recipe = all_recipes.get(recipe_id, {})
	if recipe.is_empty():
		print("❌ Tarif bulunamadı: ", recipe_id)
		return {}
	
	return recipe.duplicate(true)

func can_craft(recipe_id: String) -> Dictionary:
	"""Tarif craft edilebilir mi?"""
	var result = {
		"can_craft": false,
		"missing_materials": {},
		"skill_ok": true,
		"has_workbench": true,
		"message": ""
	}
	
	var recipe = all_recipes.get(recipe_id)
	if not recipe:
		result["message"] = "Tarif bulunamadı"
		return result
	
	# 1. Workbench Tier kontrolü
	if recipe["tier"] > current_workbench_tier:
		result["has_workbench"] = false
		result["message"] = "Daha iyi bir workbench gerekiyor (Tier %d)" % recipe["tier"]
		return result
	
	# 2. Skill kontrolü
	var skill_name = recipe.get("skill", "")
	var required_level = recipe.get("skill_level", 1)
	var player_level = player_stats["skills"].get(skill_name, 1)
	
	if player_level < required_level:
		result["skill_ok"] = false
		result["message"] = "Yeterli %s skill'i yok (Gerekli: %d, Senin: %d)" % [
			skill_name, required_level, player_level
		]
		return result
	
	# 3. Alet kontrolü (harcanmaz)
	var tool: String = recipe.get("requires_tool", "")
	if not tool.is_empty() and not GameState.has_item(tool):
		result["message"] = "Gerekli alet: %s" % InventoryManager.get_item_display_name(tool)
		return result
	
	# 4. Malzeme kontrolü
	var all_materials_ok = true
	for material in recipe["materials"]:
		var required = recipe["materials"][material]
		var available = GameState.inventory.get(material, 0)
		
		if available < required:
			all_materials_ok = false
			result["missing_materials"][material] = required - available
	
	if not all_materials_ok:
		result["message"] = "Yetersiz malzeme"
	else:
		result["message"] = "Craft edilebilir"
	
	result["can_craft"] = all_materials_ok
	return result

func start_crafting(recipe_id: String, workbench_tier: int = 1) -> Dictionary:
	"""Craft işlemini başlat"""
	print("🛠️ Craft başlatılıyor: ", recipe_id, " (Workbench Tier: ", workbench_tier, ")")
	
	var result = {
		"success": false,
		"item": "",
		"amount": 0,
		"message": "",
		"quality": 1.0,
		"craft_time": 0.0
	}
	
	# Tarif kontrolü
	var recipe = all_recipes.get(recipe_id)
	if not recipe:
		result["message"] = "Tarif bulunamadı"
		crafting_failed.emit(result["message"])
		return result
	
	# Craft edilebilir mi kontrol et
	var craft_check = can_craft(recipe_id)
	if not craft_check["can_craft"]:
		result["message"] = craft_check["message"]
		crafting_failed.emit(result["message"])
		return result
	
	# Malzemeleri harca
	for material in recipe["materials"]:
		var required = recipe["materials"][material]
		if not GameState.remove_from_inventory(material, required):
			result["message"] = "Malzeme çıkarılamadı: " + material
			crafting_failed.emit(result["message"])
			return result
	
	# Crafting durumunu ayarla
	current_crafting_item = recipe_id
	current_workbench_tier = workbench_tier
	is_crafting = true
	crafting_progress = 0.0
	
	# Craft süresi (workbench tier'ına göre azalır)
	var base_time = recipe["craft_time"]
	var time_multiplier = 1.0 - (workbench_tier - 1) * 0.25  # Her tier %25 hızlanma
	var actual_time = base_time * time_multiplier
	result["craft_time"] = actual_time
	
	print("   ⏱️ Craft süresi: ", actual_time, " saat")
	print("   📦 Malzemeler harcandı")
	
	# Asenkron craft işlemi
	await _perform_crafting( actual_time, workbench_tier)
	
	# Crafting tamamlandı
	var craft_result = _complete_crafting(recipe_id, workbench_tier)
	
	result["success"] = craft_result["success"]
	result["item"] = craft_result["item"]
	result["amount"] = craft_result["amount"]
	result["message"] = craft_result["message"]
	result["quality"] = craft_result["quality"]
	
	return result

func _perform_crafting(craft_time: float, workbench_tier: int) -> void:
	print("   🔄 Crafting işlemi başladı...")
	
	# Her craft saati oyun saatini de ilerletir
	var total_hours: int = max(1, ceili(craft_time))
	var time_manager = get_tree().get_first_node_in_group("time_manager")
	var elapsed := 0
	while elapsed < total_hours and is_crafting:
		await get_tree().create_timer(0.6).timeout
		elapsed += 1
		if time_manager and time_manager.has_method("force_pass_hour"):
			time_manager.force_pass_hour()
		crafting_progress = float(elapsed) / total_hours
		
		# Progress event'i gönder (UI güncellemek için)
		materials_updated.emit()
		
		print("   📊 Progress: %d%%" % int(crafting_progress * 100))
	
	if not is_crafting:
		print("   ⚠️ Crafting iptal edildi")
		return
	
	print("   ✅ Crafting tamamlandı")

func _complete_crafting(recipe_id: String, workbench_tier: int) -> Dictionary:
	"""Craft işlemini tamamla"""
	var result = {
		"success": false,
		"item": "",
		"amount": 0,
		"message": "",
		"quality": 1.0
	}
	
	var recipe = all_recipes[recipe_id]
	
	# Kalite hesapla
	result["quality"] = _calculate_craft_quality(recipe, workbench_tier)
	
	# Başarı şansı (kaliteye göre)
	var success_chance = _calculate_success_chance(recipe, workbench_tier, result["quality"])
	var random_roll = randf()
	
	print("   🎲 Başarı şansı: %d%%, Zar: %.2f" % [int(success_chance * 100), random_roll])
	
	# İnşaat/yükseltme/onarım işleri başarısız olmaz
	if recipe.has("effect"):
		random_roll = 0.0
	
	if random_roll > success_chance:
		# BAŞARISIZ
		result["success"] = false
		result["message"] = "Craft başarısız oldu!"
		
		# Malzemelerin yarısı kayboldu
		for material in recipe["materials"]:
			var used = recipe["materials"][material]
			var lost = int(used * 0.5)
			if lost > 0:
				GameState.add_to_inventory(material, lost)
				print("   💔 Kayıp: %s ×%d iade edildi" % [material, lost])
		
		crafting_failed.emit(result["message"])
	else:
		# BAŞARILI
		var item_name = recipe["result"]
		var base_amount = recipe["result_amount"]
		
		# Kalite bonusu
		var final_amount = base_amount
		if result["quality"] > 1.1:  # %110'dan fazlaysa ekstra
			final_amount += 1
			result["message"] = "Mükemmel işçilik! +1 ekstra"
		elif result["quality"] > 1.0:
			result["message"] = "İyi işçilik!"
		else:
			result["message"] = "Craft başarılı"
		
		# Efekt veya envantere ekle
		if recipe.has("effect"):
			final_amount = 1
			result["message"] = _apply_effect(recipe_id, recipe)
		else:
			GameState.add_to_inventory(item_name, final_amount)
		
		# İstatistikleri güncelle
		_increment_craft_count(recipe_id)
		_add_skill_xp(recipe["skill"], recipe["tier"])
		
		result["success"] = true
		if item_name.is_empty():
			item_name = recipe["name"]
		result["item"] = item_name
		result["amount"] = final_amount
		
		crafting_completed.emit(item_name, final_amount)
		
		print("   🎉 Craft başarılı: %s ×%d" % [item_name, final_amount])
	
	# Crafting durumunu sıfırla
	current_crafting_item = ""
	is_crafting = false
	crafting_progress = 0.0
	
	# Yeni recipe unlock kontrolü
	_check_recipe_unlocks()
	
	return result

# ==================================================
# HELPER FUNCTIONS - GÜNCELLENMİŞ
# ==================================================
func _calculate_craft_quality(recipe: Dictionary, workbench_tier: int) -> float:
	"""Craft kalitesini hesapla"""
	var base_quality = 1.0
	
	# Workbench bonusu (%10 her tier)
	var workbench_bonus = (workbench_tier - 1) * 0.1
	
	# Skill bonusu (%5 her level)
	var skill_name = recipe.get("skill", "")
	var skill_level = player_stats["skills"].get(skill_name, 1)
	var skill_bonus = (skill_level - 1) * 0.05
	
	# Rastgele varyasyon (-%5 ila +%10)
	var random_variation = randf_range(-0.05, 0.10)
	
	var quality = base_quality + workbench_bonus + skill_bonus + random_variation
	
	# Sınırla: %70 - %130 arası
	quality = clamp(quality, 0.7, 1.3)
	
	print("   📐 Kalite: %.2f (Workbench: +%.2f, Skill: +%.2f, Random: +%.2f)" % [
		quality, workbench_bonus, skill_bonus, random_variation
	])
	
	return quality

func _calculate_success_chance(recipe: Dictionary, workbench_tier: int, quality: float) -> float:
	"""Başarı şansını hesapla"""
	var base_chance = 0.9  # %90
	
	# Workbench bonusu (%5 her tier)
	var workbench_bonus = (workbench_tier - 1) * 0.05
	
	# Skill bonusu (%3 her level)
	var skill_name = recipe.get("skill", "")
	var skill_level = player_stats["skills"].get(skill_name, 1)
	var skill_bonus = (skill_level - 1) * 0.03
	
	# Kalite bonusu (%2 her %10 kalite)
	var quality_bonus = (quality - 1.0) * 0.2
	
	var total_chance = base_chance + workbench_bonus + skill_bonus + quality_bonus
	
	# Sınırla: %60 - %99
	total_chance = clamp(total_chance, 0.6, 0.99)
	
	return total_chance

func _increment_craft_count(recipe_id: String) -> void:
	"""Craft sayısını arttır"""
	var current_count = player_stats["crafted_items"].get(recipe_id, 0)
	player_stats["crafted_items"][recipe_id] = current_count + 1
	player_stats["total_crafts"] += 1
	
	print("📊 Craft sayısı [%s]: %d (Toplam: %d)" % [
		recipe_id, current_count + 1, player_stats["total_crafts"]
	])

func _add_skill_xp(skill_name: String, tier: int) -> void:
	"""Skill XP ekle"""
	if not player_stats["skills"].has(skill_name):
		player_stats["skills"][skill_name] = 1
	
	# Tier'a göre XP (T1: 10, T2: 20, T3: 30)
	var xp_gain = tier * 10
	var xp: int = player_stats["skill_xp"].get(skill_name, 0) + xp_gain
	var level: int = player_stats["skills"][skill_name]
	while xp >= level * XP_PER_LEVEL and level < MAX_SKILL_LEVEL:
		xp -= level * XP_PER_LEVEL
		level += 1
		SurvivalManager.notify("Yetenek gelişti: %s Seviye %d" % [skill_name, level])
	player_stats["skill_xp"][skill_name] = xp
	player_stats["skills"][skill_name] = level
	
	print("🎯 Skill XP: %s +%d (Mevcut: %d)" % [
		skill_name, xp_gain, player_stats["skills"][skill_name]
	])

# ==================================================
# RECIPE UNLOCK SYSTEM - GÜNCELLENMİŞ
# ==================================================
func _check_recipe_unlocks() -> void:
	"""Yeni tarifleri kontrol et"""
	var newly_unlocked: Array = []
	
	for recipe_id in all_recipes:
		# Zaten açık mı?
		if recipe_id in player_stats["discovered_recipes"]:
			continue
		
		var recipe = all_recipes[recipe_id]
		if recipe_id in player_stats["built"]:
			continue
		if _is_recipe_unlocked(recipe):
			player_stats["discovered_recipes"].append(recipe_id)
			newly_unlocked.append(recipe_id)
			
			print("🎉 YENİ TARİF AÇILDI: %s (%s)" % [recipe["name"], recipe["description"]])
			recipe_discovered.emit(recipe_id)

func _is_recipe_unlocked(recipe: Dictionary) -> bool:
	"""Tarifin unlock koşulu sağlanıyor mu?"""
	var unlock_condition = recipe.get("unlock_condition", "")
	
	if unlock_condition.is_empty():
		return recipe.get("unlocked", false)  # Varsayılan unlocked değeri
	
	# "craft_5_items" gibi koşullar
	if unlock_condition.begins_with("craft_"):
		var parts = unlock_condition.split("_")
		# "craft_3_items" -> toplam craft sayısı
		if parts.size() == 3 and parts[2] == "items":
			return player_stats["total_crafts"] >= int(parts[1])
		# "craft_medkit_5" -> belirli tarif sayısı
		if parts.size() >= 3:
			var required_count = int(parts[parts.size() - 1])
			var target_recipe = "_".join(parts.slice(1, parts.size() - 1))
			var crafted_count = player_stats["crafted_items"].get(target_recipe, 0)
			return crafted_count >= required_count
	
	# "find_blueprint_radio" gibi koşullar
	elif unlock_condition.begins_with("find_"):
		var blueprint_id = unlock_condition.replace("find_", "")
		return blueprint_id in player_stats["found_blueprints"]
	
	# "skill_crafting_2" gibi koşullar
	elif unlock_condition.begins_with("skill_"):
		var parts = unlock_condition.split("_")
		if parts.size() >= 3:
			var skill_name = parts[1]
			var required_level = int(parts[2])
			
			var current_level = player_stats["skills"].get(skill_name, 1)
			return current_level >= required_level
	
	return false

# ==================================================
# UTILITY FUNCTIONS
# ==================================================
func cancel_crafting() -> void:
	"""Craft işlemini iptal et"""
	if is_crafting:
		print("⚠️ Crafting iptal ediliyor...")
		is_crafting = false
		current_crafting_item = ""
		crafting_progress = 0.0

func discover_blueprint(blueprint_id: String) -> void:
	"""Yeni blueprint keşfet"""
	if not blueprint_id in player_stats["found_blueprints"]:
		player_stats["found_blueprints"].append(blueprint_id)
		print("📜 Yeni blueprint keşfedildi: ", blueprint_id)
		_check_recipe_unlocks()

func set_workbench_tier(tier: int) -> void:
	"""Workbench tier'ını ayarla"""
	current_workbench_tier = max(tier, workbench_level)
	print("🛠️ Workbench Tier ayarlandı: ", current_workbench_tier)

func _apply_effect(recipe_id: String, recipe: Dictionary) -> String:
	if recipe.get("one_time", false):
		player_stats["built"].append(recipe_id)
		player_stats["discovered_recipes"].erase(recipe_id)
	match recipe["effect"]:
		"repair_suit":
			var amount: int = recipe.get("effect_amount", 30)
			GameState.suit_durability = min(GameState.suit_durability + amount, 100)
			GameState.inventory_changed.emit()
			return "Giysi onarıldı: %%%d" % GameState.suit_durability
		"build_rain_collector":
			SurvivalManager.rain_collector_built = true
			return "Yağmur toplayıcı kuruldu! Her gün kirli su toplayacak."
		"workbench_tier":
			workbench_level = max(workbench_level, int(recipe.get("effect_amount", 2)))
			current_workbench_tier = max(current_workbench_tier, workbench_level)
			return "Tezgah Tier %d oldu!" % workbench_level
	return "Tamamlandı"

# ==================================================
# KAYIT
# ==================================================
func get_save_data() -> Dictionary:
	return {"player_stats": player_stats.duplicate(true), "workbench_level": workbench_level}

func load_save_data(data: Dictionary) -> void:
	reset()
	if data.has("player_stats"):
		for key in data["player_stats"]:
			player_stats[key] = data["player_stats"][key]
		# JSON sayıları float döner
		for skill in player_stats["skills"]:
			player_stats["skills"][skill] = int(player_stats["skills"][skill])
		player_stats["total_crafts"] = int(player_stats.get("total_crafts", 0))
	workbench_level = int(data.get("workbench_level", 1))
	_check_recipe_unlocks()

func reset() -> void:
	player_stats = {
		"crafted_items": {},
		"skills": {"medical": 1, "electronics": 1, "crafting": 1, "survival": 1},
		"skill_xp": {},
		"discovered_recipes": [],
		"found_blueprints": [],
		"built": [],
		"total_crafts": 0
	}
	workbench_level = 1
	current_workbench_tier = 1
	is_crafting = false
	_check_recipe_unlocks()

# ==================================================
# SIGNAL HANDLERS
# ==================================================
func _on_inventory_changed() -> void:
	"""Envanter değiştiğinde crafting kontrolü"""
	pass  # İleride crafting durdurma vs. eklenebilir

# ==================================================
# DEBUG FUNCTIONS
# ==================================================
func debug_unlock_all_recipes() -> void:
	"""Tüm tarifleri aç (debug için)"""
	print("🔓 DEBUG: Tüm tarifler açılıyor...")
	
	for recipe_id in all_recipes:
		if not recipe_id in player_stats["discovered_recipes"]:
			player_stats["discovered_recipes"].append(recipe_id)
			print("  ✅ ", all_recipes[recipe_id]["name"])

func debug_add_materials() -> void:
	"""Debug için malzeme ekle"""
	print("🛠️ DEBUG: Crafting malzemeleri ekleniyor...")
	
	var test_materials = {
		"cloth": 10,
		"scrap": 15,
		"chemical": 5,
		"metal": 8,
		"wire": 6,
		"wood": 5,
		"electronic": 3
	}
	
	for material in test_materials:
		GameState.add_to_inventory(material, test_materials[material])
	
	print("✅ Malzemeler eklendi")

func debug_print_status() -> void:
	"""Debug için durumu yazdır"""
	print("\n=== CRAFTING MANAGER DEBUG ===")
	print("Açık tarifler (%d):" % player_stats["discovered_recipes"].size())
	for recipe_id in player_stats["discovered_recipes"]:
		var recipe = all_recipes[recipe_id]
		print("  - %s (Tier %d)" % [recipe["name"], recipe["tier"]])
	
	print("Crafted items:")
	for item_id in player_stats["crafted_items"]:
		print("  - %s: %d" % [item_id, player_stats["crafted_items"][item_id]])
	
	print("Skills:")
	for skill in player_stats["skills"]:
		print("  - %s: %d" % [skill, player_stats["skills"][skill]])
	
	print("Toplam craft: %d" % player_stats["total_crafts"])
	print("Workbench Tier: %d" % current_workbench_tier)
	print("Crafting durumu: %s" % ("Aktif" if is_crafting else "Pasif"))
	if is_crafting:
		print("  - Item: %s" % current_crafting_item)
		print("  - Progress: %d%%" % int(crafting_progress * 100))
	print("==============================")
