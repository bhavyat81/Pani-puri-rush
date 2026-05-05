# main_scene.gd — Main gameplay controller
extends Node2D

const CUSTOMER_SCENE: PackedScene = preload("res://scenes/Customer.tscn")
const LEVEL_COMPLETE_SCENE: PackedScene = preload("res://scenes/LevelComplete.tscn")
const GAME_OVER_SCENE: PackedScene = preload("res://scenes/GameOver.tscn")

const MAX_QUEUE_SIZE: int = 3
const QUEUE_POSITIONS: Array = [
	Vector2(810, 0),
	Vector2(540, 0),
	Vector2(270, 0),
]

var current_level_id: int = 1
var level_data: Dictionary = {}
var available_flavors: Array = []
var customers_active: Array = []
var customers_spawned: int = 0
var level_timer_remaining: float = 0.0
var is_paused: bool = false
var level_running: bool = false

# Puri assembly state
var puri_state: int = 0  # 0=none, 1=empty, 2=masala, 3=ready
var puri_flavor: int = -1
var plate_puris: Array = []  # list of {flavor: int} ready to serve

@onready var hud: CanvasLayer = $HUD
@onready var customer_area: Node2D = $CustomerArea
@onready var stall_area: Node2D = $StallArea
@onready var jug_row: HBoxContainer = $StallArea/Counter/VBoxContainer/JugRow
@onready var puri_tray_btn: Button = $StallArea/Counter/VBoxContainer/ActionRow/PuriTrayBtn
@onready var masala_btn: Button = $StallArea/Counter/VBoxContainer/ActionRow/MasalaBowlBtn
@onready var trash_btn: Button = $StallArea/Counter/VBoxContainer/ActionRow/TrashBtn
@onready var puri_container: HBoxContainer = $AssemblyArea/PuriContainer
@onready var pause_menu: CanvasLayer = $PauseMenu
@onready var resume_btn: Button = $PauseMenu/PausePanel/VBoxContainer/ResumeButton
@onready var restart_btn: Button = $PauseMenu/PausePanel/VBoxContainer/RestartButton
@onready var menu_btn: Button = $PauseMenu/PausePanel/VBoxContainer/MenuButton
@onready var level_complete_layer: CanvasLayer = $LevelCompleteLayer
@onready var game_over_layer: CanvasLayer = $GameOverLayer
@onready var spawn_timer: Timer = $SpawnTimer
@onready var level_timer: Timer = $LevelTimer

func _ready() -> void:
	current_level_id = GameManager.current_level if GameManager.current_level > 0 else 1
	_load_level(current_level_id)
	_connect_signals()
	_start_level()

func _load_level(level_id: int) -> void:
	var file = FileAccess.open("res://data/levels.json", FileAccess.READ)
	if file == null:
		push_error("Cannot open levels.json")
		_use_fallback_level()
		return
	var json_text = file.get_as_text()
	file.close()
	var json = JSON.new()
	if json.parse(json_text) != OK:
		_use_fallback_level()
		return
	var data = json.get_data()
	if not data is Dictionary:
		_use_fallback_level()
		return
	for lv in data.get("levels", []):
		if lv["id"] == level_id:
			level_data = lv
			break
	if level_data.is_empty():
		_use_fallback_level()

func _use_fallback_level() -> void:
	level_data = {
		"id": 1,
		"name": "Day 1 — First Customers",
		"duration_seconds": 60,
		"available_flavors": ["TEEKHA", "MEETHA"],
		"customer_count": 5,
		"spawn_interval": [4, 7],
		"customer_pool": [{"type": "NORMAL", "weight": 100}],
		"stars_thresholds": {"1": 30, "2": 60, "3": 100}
	}

func _connect_signals() -> void:
	if puri_tray_btn:
		puri_tray_btn.pressed.connect(_on_puri_tray_pressed)
	if masala_btn:
		masala_btn.pressed.connect(_on_masala_pressed)
	if trash_btn:
		trash_btn.pressed.connect(_on_trash_pressed)
	if resume_btn:
		resume_btn.pressed.connect(_on_resume)
	if restart_btn:
		restart_btn.pressed.connect(_on_restart)
	if menu_btn:
		menu_btn.pressed.connect(_on_menu)
	if hud:
		hud.pause_requested.connect(_on_pause_requested)
	if spawn_timer:
		spawn_timer.timeout.connect(_on_spawn_timer)
	if level_timer:
		level_timer.timeout.connect(_on_level_timer_done)
	GameManager.game_over.connect(_on_game_over)
	GameManager.level_complete.connect(_on_level_complete)

func _start_level() -> void:
	available_flavors = level_data.get("available_flavors", ["TEEKHA", "MEETHA"])
	customers_spawned = 0
	customers_active.clear()
	puri_state = 0
	puri_flavor = -1
	plate_puris.clear()
	level_running = true

	GameManager.start_level(current_level_id)

	if hud:
		hud.update_level(current_level_id, level_data.get("name", "Day 1"))
		hud.update_score(0)
		hud.update_coins(0)
		hud.update_timer(level_data.get("duration_seconds", 60))
		hud.update_reputation(GameManager.MAX_REPUTATION)
		hud.connect_to_game_manager()

	_build_jug_buttons()

	level_timer_remaining = float(level_data.get("duration_seconds", 60))
	if level_timer:
		level_timer.start(level_timer_remaining)

	var spawn_range = level_data.get("spawn_interval", [4, 7])
	var first_spawn_delay = randf_range(float(spawn_range[0]), float(spawn_range[1]))
	if spawn_timer:
		spawn_timer.start(first_spawn_delay)

	_update_puri_display()

func _build_jug_buttons() -> void:
	if not jug_row:
		return
	for child in jug_row.get_children():
		child.queue_free()

	for flavor_name in available_flavors:
		var flavor_idx = _flavor_from_string(flavor_name)
		if flavor_idx < 0:
			continue
		var btn = Button.new()
		btn.custom_minimum_size = Vector2(160, 160)
		btn.text = flavor_name.left(1) + "\n" + flavor_name.left(4)
		btn.add_theme_font_size_override("font_size", 28)

		var flavor_color = _get_flavor_color(flavor_idx)
		var style = StyleBoxFlat.new()
		style.bg_color = flavor_color
		style.corner_radius_top_left = 16
		style.corner_radius_top_right = 16
		style.corner_radius_bottom_left = 16
		style.corner_radius_bottom_right = 16
		btn.add_theme_stylebox_override("normal", style)
		btn.add_theme_color_override("font_color", Color.WHITE if flavor_color.get_luminance() < 0.5 else Color.BLACK)

		var captured_flavor = flavor_idx
		btn.pressed.connect(func(): _on_flavor_pressed(captured_flavor))
		jug_row.add_child(btn)

func _process(delta: float) -> void:
	if not level_running or is_paused:
		return
	level_timer_remaining -= delta
	if level_timer_remaining < 0.0:
		level_timer_remaining = 0.0
	if hud:
		hud.update_timer(level_timer_remaining)

func _on_spawn_timer() -> void:
	if not level_running:
		return
	var max_customers = level_data.get("customer_count", 5)
	if customers_spawned < max_customers and customers_active.size() < MAX_QUEUE_SIZE:
		_spawn_customer()

	var spawn_range = level_data.get("spawn_interval", [4, 7])
	var next_delay = randf_range(float(spawn_range[0]), float(spawn_range[1]))
	if spawn_timer:
		spawn_timer.start(next_delay)

func _spawn_customer() -> void:
	var ctype = _pick_customer_type()
	var customer = CUSTOMER_SCENE.instantiate()
	customer_area.add_child(customer)

	var queue_slot = customers_active.size()
	var queue_pos = QUEUE_POSITIONS[min(queue_slot, QUEUE_POSITIONS.size() - 1)]
	customer.queue_position = queue_pos
	customer.position = Vector2(1200, queue_pos.y)
	customer.setup(ctype, available_flavors, level_data)

	customer.served.connect(func(tip): _on_customer_served(customer, tip))
	customer.left_angry.connect(func(): _on_customer_left_angry(customer))

	customers_active.append(customer)
	customers_spawned += 1

	# Overlay tappable button on the customer
	var btn = Button.new()
	btn.flat = true
	btn.custom_minimum_size = Vector2(80, 120)
	customer.add_child(btn)
	btn.position = Vector2(-40, -60)
	btn.pressed.connect(func(): _on_customer_tapped(customer))

func _pick_customer_type() -> int:
	var pool = level_data.get("customer_pool", [{"type": "NORMAL", "weight": 100}])
	var total_weight = 0
	for entry in pool:
		total_weight += entry["weight"]
	var roll = randi() % total_weight
	var cumulative = 0
	for entry in pool:
		cumulative += entry["weight"]
		if roll < cumulative:
			return _customer_type_from_string(entry["type"])
	return 0  # NORMAL

func _customer_type_from_string(s: String) -> int:
	match s:
		"NORMAL": return 0
		"VIP": return 1
		"KID": return 2
		"FOODIE": return 3
	return 0

func _on_customer_served(customer: Node2D, tip: int) -> void:
	customers_active.erase(customer)
	GameManager.complete_order(tip)
	_requeue_customers()

func _on_customer_left_angry(customer: Node2D) -> void:
	customers_active.erase(customer)
	GameManager.customer_left_angry()
	_requeue_customers()

func _requeue_customers() -> void:
	for i in range(customers_active.size()):
		var c = customers_active[i]
		if is_instance_valid(c):
			var target_pos = QUEUE_POSITIONS[min(i, QUEUE_POSITIONS.size() - 1)]
			var tween = create_tween()
			tween.tween_property(c, "position", target_pos, 0.3)

func _on_level_timer_done() -> void:
	if not level_running:
		return
	level_running = false
	if spawn_timer:
		spawn_timer.stop()
	for customer in customers_active:
		if is_instance_valid(customer):
			customer.force_leave_angry()
	GameManager.finish_level(level_data)

func _on_game_over() -> void:
	level_running = false
	if spawn_timer:
		spawn_timer.stop()
	if level_timer:
		level_timer.stop()
	_show_game_over()

func _on_level_complete(stars: int, final_score: int, final_coins: int) -> void:
	_show_level_complete(stars, final_score, final_coins)

# ── Puri Assembly ─────────────────────────────────────────────────────────

func _on_puri_tray_pressed() -> void:
	if not level_running:
		return
	if puri_state == 0:
		puri_state = 1
		AudioManager.play_tap()
		_update_puri_display()
	elif puri_state == 3:
		# Move ready puri to plate
		_add_to_plate(puri_flavor)
		puri_state = 0
		puri_flavor = -1
		_update_puri_display()

func _on_masala_pressed() -> void:
	if not level_running:
		return
	if puri_state == 1:
		puri_state = 2
		AudioManager.play_tap()
		_update_puri_display()

func _on_flavor_pressed(flavor: int) -> void:
	if not level_running:
		return
	if puri_state == 2:
		puri_state = 3
		puri_flavor = flavor
		AudioManager.play_tap()
		GameManager.add_puri_score()
		_update_puri_display()
	elif puri_state == 3:
		# Tapping a different flavor discards the in-progress puri
		AudioManager.play_serve_wrong()
		puri_state = 0
		puri_flavor = -1
		_update_puri_display()

func _on_trash_pressed() -> void:
	if puri_state > 0:
		AudioManager.play_serve_wrong()
		puri_state = 0
		puri_flavor = -1
		_update_puri_display()

func _add_to_plate(flavor: int) -> void:
	if plate_puris.size() < 3:
		plate_puris.append({"flavor": flavor})
		AudioManager.play_tap()
		_update_plate_display()

func _on_customer_tapped(customer: Node2D) -> void:
	if not level_running:
		return
	if plate_puris.is_empty():
		return

	var next_puri = plate_puris[0]
	var flavor = next_puri["flavor"]

	if is_instance_valid(customer) and customer.has_method("try_serve"):
		var success = customer.try_serve(flavor)
		plate_puris.remove_at(0)
		if success:
			AudioManager.play_serve_correct()
		else:
			AudioManager.play_serve_wrong()
		_update_plate_display()

func _update_puri_display() -> void:
	if not puri_container:
		return
	for child in puri_container.get_children():
		if child.name.begins_with("AssemblyPuri"):
			child.queue_free()

	if puri_state > 0:
		var puri_rect = ColorRect.new()
		puri_rect.name = "AssemblyPuri"
		puri_rect.custom_minimum_size = Vector2(60, 60)
		match puri_state:
			1:
				puri_rect.color = Color("#f4a261")
			2:
				puri_rect.color = Color("#c57020")
			3:
				puri_rect.color = _get_flavor_color(puri_flavor)
		puri_container.add_child(puri_rect)

func _update_plate_display() -> void:
	if not puri_container:
		return
	for child in puri_container.get_children():
		if child.name.begins_with("PlatePuri"):
			child.queue_free()

	for i in range(plate_puris.size()):
		var puri_rect = ColorRect.new()
		puri_rect.name = "PlatePuri" + str(i)
		puri_rect.custom_minimum_size = Vector2(50, 50)
		puri_rect.color = _get_flavor_color(plate_puris[i]["flavor"])
		puri_container.add_child(puri_rect)

# ── Pause ─────────────────────────────────────────────────────────────────

func _on_pause_requested() -> void:
	_toggle_pause()

func _toggle_pause() -> void:
	is_paused = !is_paused
	get_tree().paused = is_paused
	if pause_menu:
		pause_menu.visible = is_paused

func _on_resume() -> void:
	_toggle_pause()

func _on_restart() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/Main.tscn")

func _on_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

# ── Level Complete / Game Over overlays ───────────────────────────────────

func _show_level_complete(stars: int, final_score: int, final_coins: int) -> void:
	if level_complete_layer == null:
		return
	var lc = LEVEL_COMPLETE_SCENE.instantiate()
	level_complete_layer.add_child(lc)
	level_complete_layer.visible = true
	if lc.has_method("show_results"):
		lc.show_results(stars, final_score, final_coins, current_level_id)

func _show_game_over() -> void:
	if game_over_layer == null:
		return
	var go_node = GAME_OVER_SCENE.instantiate()
	game_over_layer.add_child(go_node)
	game_over_layer.visible = true
	if go_node.has_method("show_game_over"):
		go_node.show_game_over(GameManager.score)

# ── Flavor helpers ────────────────────────────────────────────────────────

func _flavor_from_string(s: String) -> int:
	match s:
		"TEEKHA": return 0
		"MEETHA": return 1
		"HING": return 2
		"LEHSUN": return 3
		"JALJEERA": return 4
	return -1

func _get_flavor_color(flavor: int) -> Color:
	match flavor:
		0: return Color("#2ecc71")
		1: return Color("#6e3b1f")
		2: return Color("#f4d35e")
		3: return Color("#6b8e5a")
		4: return Color("#d4e157")
	return Color.WHITE
