# FoodShelf.gd - Erzak rafı: açken konserve yer
extends Interactable

func get_hint() -> String:
	var food := GameState.get_item_count("food")
	if food <= 0:
		return "[E] Raf boş"
	return "[E] Ye (%d konserve)" % food

func interact() -> void:
	if GameState.get_item_count("food") <= 0:
		show_message("Rafta yiyecek kalmadı. Dışarıda erzak ara.")
	elif player_ref.hunger >= 100.0:
		show_message("Tokken yemek israf olur.")
	elif player_ref.use_consumable("food"):
		show_message("Bir konserve yedin. Açlık +35")
	refresh_hint()
