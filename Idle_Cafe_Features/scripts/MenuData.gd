class_name MenuData
extends RefCounted

var menu_name: String
var level: int = 1
var max_level: int = 100
var is_unlocked: bool = false

var base_cost: float
var base_income: float

func _init(p_name: String, p_base_cost: float = 50.0, p_base_income: float = 20.0) -> void:
	menu_name = p_name
	base_cost = p_base_cost
	base_income = p_base_income

# Hitung pendapatan saat ini (Bonus Milestone Akumulatif)
func get_current_income() -> float:
	var base_growth = 1.0 + (level - 1) * 0.05
	var milestone_count = level / 10 # Pembagian integer (e.g. lvl 10-19 = 1)
	var milestone_multiplier = pow(1.5, milestone_count)
	
	return base_income * base_growth * milestone_multiplier

# Biaya naik 1 level
func get_next_upgrade_cost() -> float:
	if level >= max_level:
		return 0.0
	return base_cost * pow(1.15, level - 1)

# Biaya naik 10 level sekaligus
func get_10_level_upgrade_cost() -> float:
	if level >= max_level:
		return 0.0
	var target_levels = min(10, max_level - level)
	var current_single_cost = get_next_upgrade_cost()
	return current_single_cost * (pow(1.15, target_levels) - 1.0) / 0.15

func upgrade(levels_to_add: int = 1) -> void:
	level = min(level + levels_to_add, max_level)
