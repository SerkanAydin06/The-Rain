# HUD.gd
extends Control

@onready var health_bar: ProgressBar = $MainMargin/BarsVBox/HealthRow/HealthBar
@onready var hunger_bar: ProgressBar = $MainMargin/BarsVBox/HungerRow/HungerBar
@onready var energy_bar: ProgressBar = $MainMargin/BarsVBox/EnergyRow/EnergyBar
@onready var suit_bar: ProgressBar = $MainMargin/BarsVBox/SuitRow/SuitBar
@onready var thirst_bar: ProgressBar = $MainMargin/BarsVBox/ThirstRow/ThirstBar

func _ready() -> void:
	# İlk yüklemede değerleri güncelle
	_on_player_stats_changed(100, 100, 100, GameState.suit_durability, 100)
	
	# GameState değiştiğinde suit bar'ı güncelle
	GameState.inventory_changed.connect(_on_game_state_changed)

func _on_player_stats_changed(h: float, n: float, e: float, s: float, t: float = 100.0) -> void:
	if thirst_bar:
		thirst_bar.value = t

	if health_bar: 
		health_bar.value = h
		print_debug("HUD - HP güncellendi: ", h)
	
	if hunger_bar: 
		hunger_bar.value = n
		print_debug("HUD - Açlık güncellendi: ", n)
	
	if energy_bar: 
		energy_bar.value = e
		print_debug("HUD - Enerji güncellendi: ", e)
	
	if suit_bar: 
		suit_bar.value = GameState.suit_durability  # ⭐ GameState'ten al
		print_debug("HUD - Suit güncellendi: ", GameState.suit_durability)

func _on_game_state_changed() -> void:
	# GameState değiştiğinde suit bar'ı güncelle
	if suit_bar:
		suit_bar.value = GameState.suit_durability
		print_debug("HUD - GameState değişti, suit güncellendi: ", GameState.suit_durability)
