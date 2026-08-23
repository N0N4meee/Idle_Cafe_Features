class_name StaffData
extends RefCounted

var staff_name: String
var hire_cost: float
var upgrade_cost: float
var multiplier: float = 1.0
var level: int = 1
var is_hired: bool = false

func _init(p_name: String, p_cost: float, p_upgrade_cost: float):
	staff_name = p_name
	hire_cost = p_cost
	upgrade_cost = p_upgrade_cost

func hire() -> bool:
	is_hired = true
	return true

func level_up() -> bool:
	level += 1
	multiplier += 0.25
	upgrade_cost *= 1.6
	return true
