class_name CafeData
extends RefCounted

var cafe_name: String = "Rat's Muse Cafe"
var max_capacity: int = 2
var current_capacity: int = 0
var furniture_price: float = 150.0

var staff_list: Array[StaffData] = []
var menu_list: Array[MenuData] = []

func upgrade_capacity(player: PlayerData) -> bool:
	if player.spend_money(furniture_price):
		max_capacity += 1
		furniture_price *= 1.8
		return true
	return false

func get_active_staff_multiplier() -> float:
	var total_mult: float = 1.0
	for staff in staff_list:
		if staff.is_hired:
			total_mult += (staff.multiplier - 1.0) + (staff.level * 0.1)
	return total_mult

var promo_level: int = 1
var promo_cost: float = 30.0

# Mendapatkan interval spawn pelanggan berdasarkan level promosi
func get_spawn_interval() -> Vector2:
	match promo_level:
		1: return Vector2(5.0, 6.0)
		2: return Vector2(4.5, 5.5)
		3: return Vector2(3.0, 4.0)
		4: return Vector2(2.5, 3.5)
		5: return Vector2(1.0, 2.0)
		6: return Vector2(0.5, 1.5)
		_: return Vector2(0.25, 0.75) 

# Fungsi upgrade promosi
func upgrade_promo(player: PlayerData) -> bool:
	if player.spend_money(promo_cost):
		promo_level += 1
		promo_cost *= 2.2
		return true
	return false
