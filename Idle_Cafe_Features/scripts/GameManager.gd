extends Node

var player: PlayerData
var cafe: CafeData
var spawn_timer: Timer

# Signal untuk pembaruan UI
signal money_changed(new_amount: float)
signal capacity_changed(current: int, max_cap: int)
signal log_message(text: String)

func _ready() -> void:
	player = PlayerData.new()
	cafe = CafeData.new()
	
	_init_default_data()
	emit_signal("money_changed", player.money)
	emit_signal("capacity_changed", cafe.current_capacity, cafe.max_capacity)
	emit_signal("log_message", "Selamat datang di Rat's Muse Cafe!")
	
	# Setup Spawner menggunakan Node Timer agar tidak terjadi multiple-loop
	_setup_spawner_timer()
	
func _setup_spawner_timer() -> void:
	spawn_timer = Timer.new()
	spawn_timer.one_shot = true # Hanya jalan sekali tiap siklus agar jedanya bisa diacak
	add_child(spawn_timer)
	
	spawn_timer.timeout.connect(func():
		simulate_customer_visit()
		_trigger_next_spawn()
	)
	
	_trigger_next_spawn()
	
func _trigger_next_spawn() -> void:
	if cafe and spawn_timer:
		var interval = cafe.get_spawn_interval()
		var wait_time = randf_range(interval.x, interval.y)
		spawn_timer.start(wait_time)
	
func _start_customer_spawner() -> void:
	while true:
		# Ambil interval acak berdasarkan level promosi saat ini
		var interval = cafe.get_spawn_interval()
		var wait_time = randf_range(interval.x, interval.y)
		await get_tree().create_timer(wait_time).timeout
		simulate_customer_visit()

func _init_default_data() -> void:
	# --- 1. MENUS ---
	# Menu 1: Espresso Cheese (Bawaan awal sudah terbuka)
	var espresso = MenuData.new("Espresso Cheese", 20.0, 50.0)
	espresso.is_unlocked = true
	cafe.menu_list.append(espresso)
	
	# Menu 2: Rat Special Cake (Muncul untuk dibeli awal)
	var cheese_cake = MenuData.new("Rat Special Cake", 45.0, 100.0)
	cafe.menu_list.append(cheese_cake)
	
	# Menu 3: Mouse Boba Tea (Akan muncul jika Menu 2 sudah dibeli)
	var boba = MenuData.new("Mouse Boba Tea", 80.0, 250.0)
	cafe.menu_list.append(boba)
	
	# Menu 4: Golden Cheese Feast (Akan muncul jika Menu 3 sudah dibeli)
	var feast = MenuData.new("Golden Cheese Feast", 180.0, 600.0)
	cafe.menu_list.append(feast)

	# --- 2. STAFFS ---
	# Staff 1: Chef Remy (Muncul untuk disewa awal)
	var chef_remy = StaffData.new("Chef Remy", 80.0, 40.0)
	cafe.staff_list.append(chef_remy)

	# Staff 2: Waiter Emile (Akan muncul jika Staff 1 sudah disewa)
	var waiter_emile = StaffData.new("Waiter Emile", 200.0, 100.0)
	cafe.staff_list.append(waiter_emile)

	# Staff 3: Barista Colette (Akan muncul jika Staff 2 sudah disewa)
	var barista_colette = StaffData.new("Barista Colette", 500.0, 250.0)
	cafe.staff_list.append(barista_colette)

# --- 1. MENAMBAH & MENG-UPGRADE MENU ---
func unlock_or_upgrade_menu(index: int) -> void:
	if index < 0 or index >= cafe.menu_list.size(): return
	var menu = cafe.menu_list[index]
	
	if not menu.is_unlocked:
		if player.spend_money(menu.upgrade_cost):
			menu.is_unlocked = true
			emit_signal("money_changed", player.money)
			emit_signal("log_message", "Menu Baru Dibuka: " + menu.menu_name)
		else:
			emit_signal("log_message", "Uang tidak cukup untuk membuka menu!")
	else:
		if player.spend_money(menu.upgrade_cost):
			menu.upgrade()
			emit_signal("money_changed", player.money)
			emit_signal("log_message", "Menu " + menu.menu_name + " naik ke Lv. " + str(menu.level))
		else:
			emit_signal("log_message", "Uang tidak cukup untuk upgrade menu!")

# --- 2. MENAMBAH & MENG-UPGRADE STAFF ---
func hire_or_upgrade_staff(index: int) -> void:
	if index < 0 or index >= cafe.staff_list.size(): return
	var staff = cafe.staff_list[index]
	
	if not staff.is_hired:
		if player.spend_money(staff.hire_cost):
			staff.hire()
			emit_signal("money_changed", player.money)
			emit_signal("log_message", "Staff Disewa: " + staff.staff_name)
		else:
			emit_signal("log_message", "Uang tidak cukup untuk sewa staff!")
	else:
		if player.spend_money(staff.upgrade_cost):
			staff.level_up()
			emit_signal("money_changed", player.money)
			emit_signal("log_message", "Staff " + staff.staff_name + " naik ke Lv. " + str(staff.level))
		else:
			emit_signal("log_message", "Uang tidak cukup untuk upgrade staff!")

# --- 3. MENAMBAH FURNITURE (KAPASITAS CAFE) ---
func buy_furniture() -> void:
	var price = cafe.furniture_price
	if cafe.upgrade_capacity(player):
		emit_signal("money_changed", player.money)
		emit_signal("capacity_changed", cafe.current_capacity, cafe.max_capacity)
		emit_signal("log_message", "Kapasitas Meja Berhasil Ditambah!")
	else:
		emit_signal("log_message", "Uang tidak cukup untuk beli furniture ($" + str(price) + ")")

# --- 4. ALUR SIMULASI CUSTOMER (DUDUK -> MAKAN 3 DETIK -> BAYAR) ---
func simulate_customer_visit() -> void:
	# 1. Cek jika meja penuh
	if cafe.current_capacity >= cafe.max_capacity:
		emit_signal("log_message", "Pelanggan batal masuk: Cafe Penuh! (" + str(cafe.current_capacity) + "/" + str(cafe.max_capacity) + ")")
		return
	
	# 2. Ambil menu unlocked
	var available_menus: Array[MenuData] = []
	for m in cafe.menu_list:
		if m.is_unlocked:
			available_menus.append(m)
			
	if available_menus.size() == 0:
		return

	var chosen_menu = available_menus[randi() % available_menus.size()]
	var customer = CustomerData.new("Pelanggan Tikus #" + str(randi() % 1000), chosen_menu)
	
	# 3. Pelanggan DUDUK
	cafe.current_capacity += 1
	emit_signal("capacity_changed", cafe.current_capacity, cafe.max_capacity)
	emit_signal("log_message", customer.cust_name + " duduk & memesan " + chosen_menu.menu_name)

	# 4. Durasi Makan Acak (misal 5-10 detik)
	var eat_duration = randf_range(5.0, 10.0)
	await get_tree().create_timer(eat_duration).timeout

	# 5. BAYAR & KELUAR
	var payment = customer.pay_amount(cafe.get_active_staff_multiplier())
	player.earn_money(payment)
	
	cafe.current_capacity -= 1
	emit_signal("money_changed", player.money)
	emit_signal("capacity_changed", cafe.current_capacity, cafe.max_capacity)
	emit_signal("log_message", customer.cust_name + " selesai makan & membayar $" + str(snapped(payment, 0.01)))
func upgrade_promo() -> void:
	var cost = cafe.promo_cost
	if cafe.upgrade_promo(player):
		emit_signal("money_changed", player.money)
		emit_signal("log_message", "Promosi ditingkatkan ke Lv. " + str(cafe.promo_level) + "! Pelanggan datang lebih cepat.")
	else:
		emit_signal("log_message", "Uang tidak cukup untuk promosi ($" + str(snapped(cost, 0.01)) + ")")
