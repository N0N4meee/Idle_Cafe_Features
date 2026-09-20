class_name CafeData
extends RefCounted

var cafe_name: String = "Rat's Muse Cafe"

# --- KAPASITAS & FURNITURE ---
var max_capacity: int = 2
var absolute_max_capacity: int = 10
var base_furniture_price: float = 150.0
var furniture_price: float = 150.0

# --- STATUS PROMOSI ---
var promo_level: int = 1
var max_promo_level: int = 25
var base_promo_cost: float = 100.0

var staff_list: Array = []
var menu_list: Array = []

# Mendapatkan interval spawn pelanggan berdasarkan promo_level (1 - 25)
func get_spawn_interval() -> Vector2:
	var t = float(promo_level - 1) / float(max_promo_level - 1)
	var min_spawn = lerp(10.0, 0.4, t)
	var max_spawn = lerp(15.0, 0.6, t)
	return Vector2(min_spawn, max_spawn)

func get_promo_cost() -> float:
	return base_promo_cost * pow(1.35, promo_level - 1)

func upgrade_promo(_dummy: Variant = null) -> bool:
	if promo_level >= max_promo_level:
		return false
	promo_level += 1
	return true

func get_next_furniture_price() -> float:
	return base_furniture_price * pow(3, max_capacity - 2)

func is_max_capacity() -> bool:
	return max_capacity >= absolute_max_capacity

func buy_furniture() -> bool:
	if is_max_capacity():
		return false
	max_capacity += 1
	furniture_price = get_next_furniture_price()
	return true

func upgrade_capacity(player: PlayerData) -> bool:
	if is_max_capacity():
		return false
	var cost = get_next_furniture_price()
	if player.spend_money(cost):
		max_capacity += 1
		furniture_price = get_next_furniture_price()
		return true
	return false

func get_active_staff_multiplier() -> float:
	var total_mult: float = 1.0
	for staff in staff_list:
		if staff.is_hired:
			total_mult *= staff.get_current_multiplier()
	return total_mult

# --- Pendapatkan per menit(harusnya udh bener rumusnya hehe) ---
func calculate_income_per_minute() -> float:
	# 1. Hitung rata-rata pendapatan per pelanggan dari menu yang sudah terbuka
	var unlocked_menus: Array = []
	for menu in menu_list:
		if menu.is_unlocked:
			unlocked_menus.append(menu)

	if unlocked_menus.size() == 0:
		return 0.0

	var total_menu_income = 0.0
	for menu in unlocked_menus:
		total_menu_income += menu.get_current_income()
	
	var avg_income_per_customer = (total_menu_income / float(unlocked_menus.size())) * get_active_staff_multiplier()

	# 2. Hitung tingkat kedatangan (Kedatangan per menit berdasarkan Promosi)
	var avg_spawn_interval = (get_spawn_interval().x + get_spawn_interval().y) / 2.0
	var arrival_rate_per_min = (1.0 / avg_spawn_interval) * 60.0 if avg_spawn_interval > 0 else 0.0

	# 3. Hitung batas throughput maksimal berdasarkan Meja yang dimiliki
	var avg_eat_duration = 4.5 # Rata-rata durasi makan adalah 4.5 detik (antara 3.0s - 6.0s)
	var max_table_throughput_per_min = (float(max_capacity) / avg_eat_duration) * 60.0

	# Pendapatan sebenarnya dibatasi oleh mana yang lebih kecil: Tingkat Kedatangan ATAU Batas Meja (Bottleneck)
	var actual_customers_per_min = minf(arrival_rate_per_min, max_table_throughput_per_min)

	return avg_income_per_customer * actual_customers_per_min
