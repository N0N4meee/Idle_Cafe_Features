class_name Cafe
extends Resource

@export var max_capacity: int = 2
@export var current_capacity: int = 0
@export var furniture_price: float = 150.0

@export var menu_list: Array[Menu] = []
@export var staff_list: Array[Staff] = []

# Sinyal untuk update UI log
signal cafe_logged(message: String)

func serve_customer(player: Player, tree: SceneTree) -> void:
	# 1. Cek apakah meja penuh
	if current_capacity >= max_capacity:
		cafe_logged.emit("Pelanggan batal masuk: Cafe Penuh! (" + str(current_capacity) + "/" + str(max_capacity) + ")")
		return

	# 2. Pelanggan masuk & menduduki meja
	current_capacity += 1
	GameManager.capacity_changed.emit(current_capacity, max_capacity)
	
	# Pilih menu acak dari yang sudah di-unlock
	var unlocked_menus = menu_list.filter(func(m): return m.is_unlocked)
	if unlocked_menus.is_empty():
		cafe_logged.emit("Pelanggan pergi: Belum ada menu yang dijual!")
		current_capacity -= 1
		GameManager.capacity_changed.emit(current_capacity, max_capacity)
		return

	var ordered_menu = unlocked_menus.pick_random()
	cafe_logged.emit("Pelanggan memesan " + ordered_menu.menu_name + ". Sedang makan...")

	# 3. Pelanggan makan selama 3 detik (Timer Non-blocking)
	await tree.create_timer(3.0).timeout

	# 4. Selesai makan, Bayar, dan Tinggalkan Meja
	var earnings = ordered_menu.price * ordered_menu.level
	player.add_money(earnings)
	
	current_capacity -= 1
	GameManager.capacity_changed.emit(current_capacity, max_capacity)
	cafe_logged.emit("Pelanggan selesai makan! Membayar $" + str(earnings))
