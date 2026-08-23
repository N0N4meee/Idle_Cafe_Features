class_name PlayerData
extends RefCounted

var money: float = 100.0
var total_progress: float = 0.0

func earn_money(amount: float) -> void:
	money += amount
	total_progress += amount

func spend_money(amount: float) -> bool:
	if money >= amount:
		money -= amount
		return true
	return false
