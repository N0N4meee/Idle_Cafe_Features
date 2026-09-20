class_name StaffData
extends RefCounted

var staff_name: String
var level: int = 1
var max_level: int = 100
var is_hired: bool = false

var hire_cost: float
var base_multiplier: float

func _init(p_name: String, p_hire_cost: float = 80.0, p_base_multiplier: float = 1.2) -> void:
	staff_name = p_name
	hire_cost = p_hire_cost
	base_multiplier = p_base_multiplier

# Hitung Multiplier Efek Staff saat ini (Bonus Milestone Akumulatif)
func get_current_multiplier() -> float:
	if not is_hired:
		return 1.0
	
	var base_growth = 1.0 + (level - 1) * 0.05
	var milestone_count = level / 10 # Pembagian integer (e.g. lvl 10-19 = 1)
	var milestone_multiplier = pow(1.5, milestone_count)
	
	return base_multiplier * base_growth * milestone_multiplier

# Biaya naik 1 level
func get_next_upgrade_cost() -> float:
	if level >= max_level:
		return 0.0
	return hire_cost * pow(1.15, level - 1)

# Biaya naik 10 level sekaligus
func get_10_level_upgrade_cost() -> float:
	if level >= max_level:
		return 0.0
	var target_levels = min(10, max_level - level)
	var current_single_cost = get_next_upgrade_cost()
	return current_single_cost * (pow(1.15, target_levels) - 1.0) / 0.15

func hire() -> void:
	is_hired = true
	level = 1

func level_up(levels_to_add: int = 1) -> void:
	level = min(level + levels_to_add, max_level)
