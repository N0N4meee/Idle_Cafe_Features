class_name CustomerData
extends RefCounted

var cust_name: String
var order: MenuData

func _init(p_name: String, p_order: MenuData):
	cust_name = p_name
	order = p_order

func pay_amount(staff_multiplier: float) -> float:
	if order:
		return order.get_income() * staff_multiplier
	return 0.0
