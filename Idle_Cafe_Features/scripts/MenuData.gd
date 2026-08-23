class_name MenuData
extends RefCounted

var menu_name: String
var base_price: float
var upgrade_cost: float
var level: int = 1
var is_unlocked: bool = false

func _init(p_name: String, p_price: float, p_cost: float):
	menu_name = p_name
	base_price = p_price
	upgrade_cost = p_cost

func get_income() -> float:
	return base_price * level

func upgrade() -> bool:
	level += 1
	upgrade_cost *= 1.5
	return true
