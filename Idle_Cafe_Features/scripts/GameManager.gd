extends Node

var player: PlayerData
var cafe: CafeData
var spawn_timer: Timer

const SAVE_PATH = "user://savegame.json"

# Pencatat pelanggan yang sedang berada di kafe
var active_customers_count: int = 0

signal money_changed(new_amount: float)
signal capacity_changed(current: int, max_cap: int)
signal log_message(text: String)
signal offline_earnings_ready(amount: float, minutes: int)

func _ready() -> void:
	player = PlayerData.new()
	cafe = CafeData.new()

	_init_default_data()
	_load_game()

	emit_signal("money_changed", player.money)
	emit_signal("capacity_changed", active_customers_count, cafe.max_capacity)
	emit_signal("log_message", "Selamat datang kembali di Rat's Muse Cafe!")

	_setup_spawner_timer()
	_check_offline_earnings()

func _setup_spawner_timer() -> void:
	spawn_timer = Timer.new()
	spawn_timer.one_shot = true
	add_child(spawn_timer)

	spawn_timer.timeout.connect(func():
		# Panggil kedatangan pelanggan
		simulate_customer_visit()
		# Atur jadwal spawner berikutnya
		_trigger_next_spawn()
	)

	_trigger_next_spawn()

func _trigger_next_spawn() -> void:
	if cafe and spawn_timer:
		var interval = cafe.get_spawn_interval()
		var wait_time = randf_range(interval.x, interval.y)
		spawn_timer.start(wait_time)

# --- SISTEM SAVE & LOAD GAME ---
func save_game() -> void:
	if not player or not cafe:
		return

	player.save_timestamp()

	var save_data = {
		"player": {
			"money": player.money,
			"last_save_time": player.last_save_time
		},
		"cafe": {
			"max_capacity": cafe.max_capacity,
			"furniture_price": cafe.furniture_price,
			"promo_level": cafe.promo_level
		},
		"menus": [],
		"staffs": []
	}

	for m in cafe.menu_list:
		save_data["menus"].append({
			"name": m.menu_name,
			"level": m.level,
			"is_unlocked": m.is_unlocked
		})

	for s in cafe.staff_list:
		save_data["staffs"].append({
			"name": s.staff_name,
			"level": s.level,
			"is_hired": s.is_hired
		})

	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		var json_string = JSON.stringify(save_data)
		file.store_string(json_string)
		file.close()

func _load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		return

	var data = json.get_data()

	if data.has("player"):
		player.money = data["player"].get("money", 100.0)
		player.last_save_time = data["player"].get("last_save_time", 0)

	if data.has("cafe"):
		cafe.max_capacity = min(data["cafe"].get("max_capacity", 2), cafe.absolute_max_capacity)
		cafe.promo_level = min(data["cafe"].get("promo_level", 1), cafe.max_promo_level)
		cafe.furniture_price = cafe.get_next_furniture_price()

	if data.has("menus"):
		var menu_data_list = data["menus"]
		for m_saved in menu_data_list:
			for m in cafe.menu_list:
				if m.menu_name == m_saved["name"]:
					m.level = m_saved["level"]
					m.is_unlocked = m_saved["is_unlocked"]

	if data.has("staffs"):
		var staff_data_list = data["staffs"]
		for s_saved in staff_data_list:
			for s in cafe.staff_list:
				if s.staff_name == s_saved["name"]:
					s.level = s_saved["level"]
					s.is_hired = s_saved["is_hired"]

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_APPLICATION_PAUSED:
		save_game()

func _check_offline_earnings() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return

	var last_time = player.load_timestamp()
	if last_time == 0:
		return

	var current_time = Time.get_unix_time_from_system()
	var time_passed_seconds = current_time - last_time

	if time_passed_seconds >= 60:
		var minutes_offline = float(time_passed_seconds) / 60.0
		var capped_minutes = minf(minutes_offline, 480.0)

		var income_per_min = cafe.calculate_income_per_minute()
		var offline_earnings = capped_minutes * (income_per_min * 0.1)

		if offline_earnings > 0:
			player.earn_money(offline_earnings)
			save_game()
			emit_signal("money_changed", player.money)
			call_deferred("_trigger_offline_popup", offline_earnings, int(capped_minutes))

func _trigger_offline_popup(earnings: float, minutes: int) -> void:
	emit_signal("offline_earnings_ready", earnings, minutes)

func _init_default_data() -> void:
	var espresso = MenuData.new("Espresso Cheese", 50.0, 20.0)
	espresso.is_unlocked = true
	cafe.menu_list.append(espresso)

	var cheese_cake = MenuData.new("Rat Special Cake", 150.0, 45.0)
	cafe.menu_list.append(cheese_cake)

	var boba = MenuData.new("Mouse Boba Tea", 350.0, 80.0)
	cafe.menu_list.append(boba)

	var feast = MenuData.new("Golden Cheese Feast", 850.0, 180.0)
	cafe.menu_list.append(feast)

	var chef_remy = StaffData.new("Chef Remy", 80.0, 1.2)
	cafe.staff_list.append(chef_remy)

	var waiter_emile = StaffData.new("Waiter Emile", 200.0, 1.3)
	cafe.staff_list.append(waiter_emile)

	var barista_colette = StaffData.new("Barista Colette", 500.0, 1.5)
	cafe.staff_list.append(barista_colette)

func unlock_or_upgrade_menu(index: int, buy_10: bool = false) -> void:
	if index < 0 or index >= cafe.menu_list.size(): return
	var menu = cafe.menu_list[index]

	if not menu.is_unlocked:
		var cost = menu.base_cost
		if player.spend_money(cost):
			menu.is_unlocked = true
			save_game()
			emit_signal("money_changed", player.money)
			emit_signal("log_message", "Menu Baru Dibuka: " + menu.menu_name)
		else:
			emit_signal("log_message", "Uang tidak cukup ($" + format_number(cost) + ")")
	else:
		if menu.level >= menu.max_level:
			emit_signal("log_message", "Menu " + menu.menu_name + " sudah LEVEL MAX!")
			return

		var count = 10 if buy_10 else 1
		var cost = menu.get_10_level_upgrade_cost() if buy_10 else menu.get_next_upgrade_cost()

		if player.spend_money(cost):
			menu.upgrade(count)
			save_game()
			emit_signal("money_changed", player.money)
			emit_signal("log_message", "Menu " + menu.menu_name + " naik ke Lv. " + str(menu.level))
		else:
			emit_signal("log_message", "Uang tidak cukup ($" + format_number(cost) + ")")

func hire_or_upgrade_staff(index: int, buy_10: bool = false) -> void:
	if index < 0 or index >= cafe.staff_list.size(): return
	var staff = cafe.staff_list[index]

	if not staff.is_hired:
		if player.spend_money(staff.hire_cost):
			staff.hire()
			save_game()
			emit_signal("money_changed", player.money)
			emit_signal("log_message", "Staff Disewa: " + staff.staff_name)
		else:
			emit_signal("log_message", "Uang tidak cukup ($" + format_number(staff.hire_cost) + ")")
	else:
		if staff.level >= staff.max_level:
			emit_signal("log_message", "Staff " + staff.staff_name + " sudah LEVEL MAX!")
			return

		var count = 10 if buy_10 else 1
		var cost = staff.get_10_level_upgrade_cost() if buy_10 else staff.get_next_upgrade_cost()

		if player.spend_money(cost):
			staff.level_up(count)
			save_game()
			emit_signal("money_changed", player.money)
			emit_signal("log_message", "Staff " + staff.staff_name + " naik ke Lv. " + str(staff.level))
		else:
			emit_signal("log_message", "Uang tidak cukup ($" + format_number(cost) + ")")

func buy_furniture() -> void:
	if not cafe or not player:
		return

	if cafe.is_max_capacity():
		emit_signal("log_message", "Kapasitas meja sudah maksimal (" + str(cafe.absolute_max_capacity) + ")!")
		return

	var price = cafe.get_next_furniture_price()
	if player.spend_money(price):
		if cafe.buy_furniture():
			save_game()
			emit_signal("money_changed", player.money)
			emit_signal("capacity_changed", active_customers_count, cafe.max_capacity)
			emit_signal("log_message", "Kapasitas Meja Ditambah ke " + str(cafe.max_capacity) + "!")
	else:
		emit_signal("log_message", "Uang tidak cukup ($" + format_number(price) + ")")

func upgrade_promo() -> void:
	if not cafe or not player:
		return

	if cafe.promo_level >= cafe.max_promo_level:
		emit_signal("log_message", "Promosi sudah mencapai LEVEL MAX!")
		return

	var cost = cafe.get_promo_cost()
	if player.spend_money(cost):
		if cafe.upgrade_promo():
			save_game()
			emit_signal("money_changed", player.money)
			emit_signal("log_message", "Promosi berhasil ditingkatkan ke Lv. " + str(cafe.promo_level))
	else:
		emit_signal("log_message", "Uang tidak cukup ($" + format_number(cost) + ")")

# --- PROSES KEDATANGAN & SERVIS PELANGGAN ---
func simulate_customer_visit() -> void:
	# Jika jumlah pelanggan aktif sudah sama atau melebihi kapasitas meja saat ini, tolak
	if active_customers_count >= cafe.max_capacity:
		return

	var available_menus: Array[MenuData] = []
	for m in cafe.menu_list:
		if m.is_unlocked:
			available_menus.append(m)

	if available_menus.size() == 0:
		return

	# Dudukkan pelanggan
	active_customers_count += 1
	emit_signal("capacity_changed", active_customers_count, cafe.max_capacity)

	var chosen_menu = available_menus[randi() % available_menus.size()]
	var customer_name = "Pelanggan Tikus #" + str(randi() % 1000)
	emit_signal("log_message", customer_name + " duduk & memesan " + chosen_menu.menu_name)

	# Jalankan proses makan secara mandiri menggunakan Coroutine terisolasi
	_process_customer_eating(customer_name, chosen_menu)

func _process_customer_eating(customer_name: String, menu: MenuData) -> void:
	var eat_duration = randf_range(3.0, 6.0)
	await get_tree().create_timer(eat_duration).timeout

	# Kalkulasi Pembayaran setelah makan selesai
	var payment = menu.get_current_income() * cafe.get_active_staff_multiplier()
	player.earn_money(payment)
	
	# Kosongkan meja
	active_customers_count = max(0, active_customers_count - 1)
	
	save_game()

	emit_signal("money_changed", player.money)
	emit_signal("capacity_changed", active_customers_count, cafe.max_capacity)
	emit_signal("log_message", customer_name + " bayar $" + format_number(payment))

static func format_number(value: float) -> String:
	var abs_val = abs(value)
	var sign = "-" if value < 0 else ""

	if abs_val < 1000.0:
		return sign + str(snapped(abs_val, 0.01))
	elif abs_val < 1000000.0:
		return sign + str(snapped(abs_val / 1000.0, 0.01)) + "K"
	elif abs_val < 1000000000.0:
		return sign + str(snapped(abs_val / 1000000.0, 0.01)) + "M"
	elif abs_val < 1000000000000.0:
		return sign + str(snapped(abs_val / 1000000000.0, 0.01)) + "B"
	elif abs_val < 1000000000000000.0:
		return sign + str(snapped(abs_val / 1000000000000.0, 0.01)) + "T"
	else:
		return sign + str(snapped(abs_val / 1000000000000000.0, 0.01)) + "Q"
