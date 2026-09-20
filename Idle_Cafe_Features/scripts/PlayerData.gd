class_name PlayerData
extends RefCounted

var money: float = 100.0
var last_save_time: int = 0

func earn_money(amount: float) -> void:
	money += amount

func spend_money(amount: float) -> bool:
	if money >= amount:
		money -= amount
		return true
	return false

func save_timestamp() -> void:
	last_save_time = Time.get_unix_time_from_system()

func load_timestamp() -> int:
	return last_save_time
