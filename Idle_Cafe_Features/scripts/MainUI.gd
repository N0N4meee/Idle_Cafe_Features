extends Control

# Variabel Komponen UI
var money_label: Label
var capacity_label: Label
var log_label: RichTextLabel
var log_history: Array[String] = []
var max_log_lines: int = 15 # Simpan 15 baris riwayat log terakhir

var furniture_btn: Button
var customer_btn: Button
var promo_btn: Button

var menu_container: VBoxContainer
var staff_container: VBoxContainer

func _ready() -> void:
	# 1. Bersihkan elemen visual lama jika ada
	for child in get_children():
		child.queue_free()

	# 2. Buat Layout UI Baru via Code
	_build_ui_layout()

	# 3. Hubungkan Sinyal dari GameManager
	if GameManager.has_signal("money_changed"):
		GameManager.money_changed.connect(_on_money_changed)
	if GameManager.has_signal("capacity_changed"):
		GameManager.capacity_changed.connect(_on_capacity_changed)
	if GameManager.has_signal("log_message"):
		GameManager.log_message.connect(_on_log_message)

	# 4. Hubungkan Event Tombol Utama
	furniture_btn.pressed.connect(func(): GameManager.buy_furniture())
	customer_btn.pressed.connect(func(): GameManager.simulate_customer_visit())
	promo_btn.pressed.connect(func(): GameManager.upgrade_promo())

	# 5. Render/Update Tampilan Awal
	_update_ui_buttons()

func _build_ui_layout() -> void:
	# Container Utama
	var vbox_main = VBoxContainer.new()
	vbox_main.anchor_right = 1.0
	vbox_main.anchor_bottom = 1.0
	vbox_main.offset_left = 20
	vbox_main.offset_top = 20
	vbox_main.offset_right = -20
	vbox_main.offset_bottom = -20
	vbox_main.add_theme_constant_override("separation", 15)
	add_child(vbox_main)

	# --- HEADER ATAS ---
	var top_header = HBoxContainer.new()
	vbox_main.add_child(top_header)

	money_label = Label.new()
	money_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	money_label.add_theme_font_size_override("font_size", 20)
	money_label.text = "Uang: $100.0"
	top_header.add_child(money_label)

	capacity_label = Label.new()
	capacity_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	capacity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	capacity_label.add_theme_font_size_override("font_size", 20)
	capacity_label.text = "Kapasitas Meja: 0/2"
	top_header.add_child(capacity_label)

	# --- AREA KONTEN TENGAH ---
	var content_area = HBoxContainer.new()
	content_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_area.add_theme_constant_override("separation", 20)
	vbox_main.add_child(content_area)

	# --- PANEL KIRI (MENU & STAF DINAMIS) ---
	var left_panel = VBoxContainer.new()
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.add_theme_constant_override("separation", 10)
	content_area.add_child(left_panel)

	var menu_hdr = Label.new()
	menu_hdr.text = "--- MENU MANAGEMENT ---"
	left_panel.add_child(menu_hdr)

	# Container khusus penampung tombol menu dinamis
	menu_container = VBoxContainer.new()
	menu_container.add_theme_constant_override("separation", 6)
	left_panel.add_child(menu_container)

	var staff_hdr = Label.new()
	staff_hdr.text = "--- STAF MANAGEMENT ---"
	left_panel.add_child(staff_hdr)

	# Container khusus penampung tombol staf dinamis
	staff_container = VBoxContainer.new()
	staff_container.add_theme_constant_override("separation", 6)
	left_panel.add_child(staff_container)

	# --- PANEL KANAN (AKSI CAFE) ---
	var right_panel = VBoxContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.add_theme_constant_override("separation", 10)
	content_area.add_child(right_panel)

	var action_hdr = Label.new()
	action_hdr.text = "--- CAFE ACTION ---"
	right_panel.add_child(action_hdr)

	furniture_btn = Button.new()
	furniture_btn.custom_minimum_size.y = 45
	right_panel.add_child(furniture_btn)

	promo_btn = Button.new()
	promo_btn.custom_minimum_size.y = 45
	right_panel.add_child(promo_btn)

	customer_btn = Button.new()
	customer_btn.custom_minimum_size.y = 45
	customer_btn.text = "Melayani Pelanggan (Manual)"
	right_panel.add_child(customer_btn)

	# --- PANEL LOG BAWAH ---
	var log_panel = PanelContainer.new()
	log_panel.custom_minimum_size.y = 120
	vbox_main.add_child(log_panel)

	log_label = RichTextLabel.new()
	log_label.scroll_following = true
	log_label.selection_enabled = true
	log_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	log_panel.add_child(log_label)

func _on_money_changed(_new_amount: float) -> void:
	_update_ui_buttons()

func _on_capacity_changed(current: int, max_cap: int) -> void:
	if capacity_label:
		capacity_label.text = "Kapasitas Meja: " + str(current) + "/" + str(max_cap)

func _on_log_message(text: String) -> void:
	if log_label:
		log_history.append("> " + text)
		if log_history.size() > max_log_lines:
			log_history.pop_front()

		log_label.text = "\n".join(log_history)

func _update_ui_buttons() -> void:
	if not GameManager.cafe or not GameManager.player:
		return

	# 1. Update Header & Tombol Statis Kanan
	if money_label:
		money_label.text = "Uang: $" + str(snapped(GameManager.player.money, 0.01))

	if capacity_label:
		capacity_label.text = "Kapasitas Meja: " + str(GameManager.cafe.current_capacity) + "/" + str(GameManager.cafe.max_capacity)

	if furniture_btn:
		furniture_btn.text = "Beli Kursi/Meja Baru ($" + str(snapped(GameManager.cafe.furniture_price, 0.01)) + ")"

	if promo_btn and GameManager.cafe:
		var interval = GameManager.cafe.get_spawn_interval()
		promo_btn.text = "Promosi Cafe (Lv. " + str(GameManager.cafe.promo_level) + ") - $" + str(snapped(GameManager.cafe.promo_cost, 0.01)) + " [" + str(interval.x) + "-" + str(interval.y) + "s]"

	# 2. Render Tombol Menu secara Dinamis (Tampilkan Unlocked + Max 1 Locked)
	if menu_container:
		for child in menu_container.get_children():
			child.queue_free()

		var shown_locked_menu = false
		for i in range(GameManager.cafe.menu_list.size()):
			var m = GameManager.cafe.menu_list[i]

			if m.is_unlocked or not shown_locked_menu:
				var btn = Button.new()
				btn.custom_minimum_size.y = 40

				if m.is_unlocked:
					btn.text = m.menu_name + " (Lv. " + str(m.level) + ") - Upgrade $" + str(snapped(m.upgrade_cost, 0.01))
				else:
					btn.text = "[LOCKED] Buka " + m.menu_name + " ($" + str(snapped(m.upgrade_cost, 0.01)) + ")"
					shown_locked_menu = true

				var index_capture = i
				btn.pressed.connect(func(): GameManager.unlock_or_upgrade_menu(index_capture))
				menu_container.add_child(btn)

	# 3. Render Tombol Staf secara Dinamis (Tampilkan Hired + Max 1 Locked/Unhired)
	if staff_container:
		for child in staff_container.get_children():
			child.queue_free()

		var shown_locked_staff = false
		for i in range(GameManager.cafe.staff_list.size()):
			var s = GameManager.cafe.staff_list[i]

			if s.is_hired or not shown_locked_staff:
				var btn = Button.new()
				btn.custom_minimum_size.y = 40

				if s.is_hired:
					btn.text = s.staff_name + " (Lv. " + str(s.level) + ") - Upgrade $" + str(snapped(s.upgrade_cost, 0.01))
				else:
					btn.text = "[LOCKED] Sewa " + s.staff_name + " ($" + str(snapped(s.hire_cost, 0.01)) + ")"
					shown_locked_staff = true

				var index_capture = i
				btn.pressed.connect(func(): GameManager.hire_or_upgrade_staff(index_capture))
				staff_container.add_child(btn)
