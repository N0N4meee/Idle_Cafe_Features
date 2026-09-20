extends Control

var money_label: Label
var income_label: Label
var capacity_label: Label
var log_label: RichTextLabel
var log_history: Array[String] = []
var max_log_lines: int = 15

var furniture_btn: Button
var customer_btn: Button
var promo_btn: Button

var menu_container: VBoxContainer
var staff_container: VBoxContainer

func _ready() -> void:
	for child in get_children():
		child.queue_free()

	_build_ui_layout()

	if GameManager.has_signal("money_changed"):
		GameManager.money_changed.connect(_on_money_changed)
	if GameManager.has_signal("capacity_changed"):
		GameManager.capacity_changed.connect(_on_capacity_changed)
	if GameManager.has_signal("log_message"):
		GameManager.log_message.connect(_on_log_message)
	if GameManager.has_signal("offline_earnings_ready"):
		GameManager.offline_earnings_ready.connect(_show_welcome_back_popup)

	furniture_btn.pressed.connect(func(): GameManager.buy_furniture())
	customer_btn.pressed.connect(func(): GameManager.simulate_customer_visit())
	promo_btn.pressed.connect(func(): GameManager.upgrade_promo())

	_update_ui_buttons()

func _build_ui_layout() -> void:
	var vbox_main = VBoxContainer.new()
	vbox_main.anchor_right = 1.0
	vbox_main.anchor_bottom = 1.0
	vbox_main.offset_left = 20
	vbox_main.offset_top = 20
	vbox_main.offset_right = -20
	vbox_main.offset_bottom = -20
	vbox_main.add_theme_constant_override("separation", 15)
	add_child(vbox_main)

	var top_header = HBoxContainer.new()
	vbox_main.add_child(top_header)

	var money_info_vbox = VBoxContainer.new()
	money_info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_header.add_child(money_info_vbox)

	money_label = Label.new()
	money_label.add_theme_font_size_override("font_size", 20)
	money_label.text = "Uang: $0"
	money_info_vbox.add_child(money_label)

	income_label = Label.new()
	income_label.add_theme_font_size_override("font_size", 14)
	income_label.add_theme_color_override("font_color", Color(0.3, 0.85, 0.4))
	income_label.text = "+$0 / menit"
	money_info_vbox.add_child(income_label)

	capacity_label = Label.new()
	capacity_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	capacity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	capacity_label.add_theme_font_size_override("font_size", 20)
	capacity_label.text = "Kapasitas Meja: 0/2"
	top_header.add_child(capacity_label)

	var content_area = HBoxContainer.new()
	content_area.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content_area.add_theme_constant_override("separation", 20)
	vbox_main.add_child(content_area)

	var left_panel = VBoxContainer.new()
	left_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_panel.add_theme_constant_override("separation", 10)
	content_area.add_child(left_panel)

	var menu_hdr = Label.new()
	menu_hdr.text = "--- MANAJEMEN MENU ---"
	left_panel.add_child(menu_hdr)

	menu_container = VBoxContainer.new()
	menu_container.add_theme_constant_override("separation", 6)
	left_panel.add_child(menu_container)

	var staff_hdr = Label.new()
	staff_hdr.text = "--- MANAJEMEN STAF ---"
	left_panel.add_child(staff_hdr)

	staff_container = VBoxContainer.new()
	staff_container.add_theme_constant_override("separation", 6)
	left_panel.add_child(staff_container)

	var right_panel = VBoxContainer.new()
	right_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right_panel.add_theme_constant_override("separation", 10)
	content_area.add_child(right_panel)

	var action_hdr = Label.new()
	action_hdr.text = "--- AKSI CAFE ---"
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

	if money_label:
		money_label.text = "Uang: $" + format_number(GameManager.player.money)

	if income_label:
		var inc = GameManager.cafe.calculate_income_per_minute()
		income_label.text = "+$" + format_number(inc) + " / menit"

	if capacity_label:
		capacity_label.text = "Kapasitas Meja: " + str(GameManager.active_customers_count) + "/" + str(GameManager.cafe.max_capacity)

	# Update Tombol Beli Furniture/Meja Baru
	if furniture_btn:
		if GameManager.cafe.is_max_capacity():
			furniture_btn.text = "Kapasitas Meja Maksimal (" + str(GameManager.cafe.absolute_max_capacity) + "/" + str(GameManager.cafe.absolute_max_capacity) + ")"
			furniture_btn.disabled = true
		else:
			var next_price = GameManager.cafe.get_next_furniture_price()
			furniture_btn.text = "Beli Kursi/Meja Baru ($" + format_number(next_price) + ")"
			furniture_btn.disabled = false

	# Update Tombol Promosi Cafe (Level 1 - 25)
	if promo_btn:
		var interval = GameManager.cafe.get_spawn_interval()
		if GameManager.cafe.promo_level >= GameManager.cafe.max_promo_level:
			promo_btn.text = "Promosi Cafe (MAX Lv. " + str(GameManager.cafe.max_promo_level) + ") [" + str(snapped(interval.x, 0.1)) + "-" + str(snapped(interval.y, 0.1)) + "s]"
			promo_btn.disabled = true
		else:
			promo_btn.text = "Promosi Cafe (Lv. " + str(GameManager.cafe.promo_level) + ") - $" + format_number(GameManager.cafe.get_promo_cost()) + " [" + str(snapped(interval.x, 0.1)) + "-" + str(snapped(interval.y, 0.1)) + "s]"
			promo_btn.disabled = false

	_update_menu_list_ui()
	_update_staff_list_ui()

func _show_welcome_back_popup(amount: float, minutes: int) -> void:
	var dialog = AcceptDialog.new()
	dialog.title = "Selamat Datang Kembali!"

	var hrs = minutes / 60
	var mins = minutes % 60
	var time_str = ""
	if hrs > 0:
		time_str += str(hrs) + " jam "
	time_str += str(mins) + " menit"

	dialog.dialog_text = "Kafe kamu tetap beroperasi selagi kamu pergi (" + time_str + ")!\n\nHasil Pendapatan Offline: $" + format_number(amount)
	add_child(dialog)
	dialog.popup_centered(Vector2i(350, 150))
	dialog.confirmed.connect(func(): dialog.queue_free())

func _update_menu_list_ui() -> void:
	if not menu_container: return

	for child in menu_container.get_children():
		child.queue_free()

	var shown_locked = false
	for i in range(GameManager.cafe.menu_list.size()):
		var menu = GameManager.cafe.menu_list[i]

		if menu.is_unlocked or not shown_locked:
			var hbox = HBoxContainer.new()
			var label = Label.new()
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			if not menu.is_unlocked:
				label.text = menu.menu_name + " [Terkunci]"
				var unlock_btn = Button.new()
				unlock_btn.text = "Buka ($" + format_number(menu.base_cost) + ")"
				var idx = i
				unlock_btn.pressed.connect(func(): GameManager.unlock_or_upgrade_menu(idx))
				hbox.add_child(label)
				hbox.add_child(unlock_btn)
				shown_locked = true
			else:
				label.text = menu.menu_name + " (Lv. " + str(menu.level) + ") - $" + format_number(menu.get_current_income()) + "/porsi"
				hbox.add_child(label)

				if menu.level >= menu.max_level:
					var max_label = Label.new()
					max_label.text = "LEVEL MAX"
					max_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
					hbox.add_child(max_label)
				else:
					var idx = i
					var up_1_btn = Button.new()
					up_1_btn.text = "+1 Lv ($" + format_number(menu.get_next_upgrade_cost()) + ")"
					up_1_btn.pressed.connect(func(): GameManager.unlock_or_upgrade_menu(idx, false))
					hbox.add_child(up_1_btn)

					var up_10_btn = Button.new()
					up_10_btn.text = "+10 Lv ($" + format_number(menu.get_10_level_upgrade_cost()) + ")"
					up_10_btn.pressed.connect(func(): GameManager.unlock_or_upgrade_menu(idx, true))
					hbox.add_child(up_10_btn)

			menu_container.add_child(hbox)

func _update_staff_list_ui() -> void:
	if not staff_container: return

	for child in staff_container.get_children():
		child.queue_free()

	var shown_locked = false
	for i in range(GameManager.cafe.staff_list.size()):
		var staff = GameManager.cafe.staff_list[i]

		if staff.is_hired or not shown_locked:
			var hbox = HBoxContainer.new()
			var label = Label.new()
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

			if not staff.is_hired:
				label.text = staff.staff_name + " [Belum Disewa]"
				var hire_btn = Button.new()
				hire_btn.text = "Sewa ($" + format_number(staff.hire_cost) + ")"
				var idx = i
				hire_btn.pressed.connect(func(): GameManager.hire_or_upgrade_staff(idx))
				hbox.add_child(label)
				hbox.add_child(hire_btn)
				shown_locked = true
			else:
				label.text = staff.staff_name + " (Lv. " + str(staff.level) + ") - Mult: " + str(snapped(staff.get_current_multiplier(), 0.01)) + "x"
				hbox.add_child(label)

				if staff.level >= staff.max_level:
					var max_label = Label.new()
					max_label.text = "LEVEL MAX"
					max_label.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
					hbox.add_child(max_label)
				else:
					var idx = i
					var up_1_btn = Button.new()
					up_1_btn.text = "+1 Lv ($" + format_number(staff.get_next_upgrade_cost()) + ")"
					up_1_btn.pressed.connect(func(): GameManager.hire_or_upgrade_staff(idx, false))
					hbox.add_child(up_1_btn)

					var up_10_btn = Button.new()
					up_10_btn.text = "+10 Lv ($" + format_number(staff.get_10_level_upgrade_cost()) + ")"
					up_10_btn.pressed.connect(func(): GameManager.hire_or_upgrade_staff(idx, true))
					hbox.add_child(up_10_btn)

			staff_container.add_child(hbox)

func format_number(value: float) -> String:
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
