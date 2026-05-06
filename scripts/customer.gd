# customer.gd — Customer behavior: walks in, shows order, patience drains, walks out
class_name CustomerScript
extends Node2D

signal served(tip_amount: int)
signal left_angry()

enum CustomerState {
	WALKING_IN,
	WAITING,
	EATING,
	LEAVING_HAPPY,
	LEAVING_ANGRY,
}

enum CustomerType {
	NORMAL,
	VIP,
	KID,
	FOODIE,
}

const CUSTOMER_DATA: Dictionary = {
	CustomerType.NORMAL: {
		"patience_seconds": 25.0,
		"tip": 10,
		"min_puris": 1,
		"max_puris": 2,
		"body_color": Color("#4a9eff"),
	},
	CustomerType.VIP: {
		"patience_seconds": 15.0,
		"tip": 30,
		"min_puris": 2,
		"max_puris": 3,
		"body_color": Color("#ffd700"),
	},
	CustomerType.KID: {
		"patience_seconds": 30.0,
		"tip": 5,
		"min_puris": 1,
		"max_puris": 1,
		"body_color": Color("#ff69b4"),
	},
	CustomerType.FOODIE: {
		"patience_seconds": 20.0,
		"tip": 25,
		"min_puris": 3,
		"max_puris": 4,
		"body_color": Color("#9b59b6"),
	},
}

const TEXTURE_NEUTRAL = preload("res://assets/sprites/customer_neutral.svg")
const TEXTURE_HAPPY   = preload("res://assets/sprites/customer_happy.svg")
const TEXTURE_ANGRY   = preload("res://assets/sprites/customer_angry.svg")

var customer_type: int = CustomerType.NORMAL
var order: Order = null
var patience: float = 1.0  # 0.0 to 1.0
var patience_seconds: float = 25.0
var tip_amount: int = 10
var state: int = CustomerState.WALKING_IN
var queue_position: Vector2 = Vector2.ZERO
var is_vip: bool = false
var _patience_timer: float = 0.0

@onready var body_sprite: Sprite2D = $BodySprite
@onready var patience_bar: ProgressBar = $PatienceBar
@onready var order_bubble: PanelContainer = $OrderBubble
@onready var order_container: HBoxContainer = $OrderBubble/MarginContainer/HBoxContainer

func setup(ctype: int, available_flavors: Array, level_data: Dictionary = {}) -> void:
	customer_type = ctype
	var data = CUSTOMER_DATA[ctype]
	patience_seconds = data["patience_seconds"]
	tip_amount = data["tip"]
	is_vip = (ctype == CustomerType.VIP)

	# Generate order based on type and available flavors
	order = _generate_order(ctype, available_flavors)

	if is_vip and order_bubble:
		order_bubble.add_theme_stylebox_override("panel", _make_gold_style())
	# Update patience timer with correct value
	_patience_timer = patience_seconds
	# UI is ready because setup() is called after add_child() → _ready()
	_update_visuals()
	_build_order_display()
	_walk_to_queue()

func _generate_order(ctype: int, available_flavors: Array) -> Order:
	var data = CUSTOMER_DATA[ctype]
	var num_puris = randi_range(data["min_puris"], data["max_puris"])
	var items: Array = []

	if ctype == CustomerType.KID:
		# Kids only order MEETHA if available, else first available
		var kid_flavor = FlavorHelper.Flavor.MEETHA
		if not available_flavors.has("MEETHA"):
			kid_flavor = FlavorHelper.from_string(available_flavors[0])
		items.append({"flavor": kid_flavor, "quantity": num_puris, "served": 0})
	elif ctype == CustomerType.FOODIE and available_flavors.size() >= 3:
		# Foodies want at least 3 different flavors.
		# Distribute num_puris across 3 randomly chosen flavors, ensuring
		# each flavor gets ≥1 puri and the last flavor absorbs any remainder.
		var shuffled = available_flavors.duplicate()
		shuffled.shuffle()
		var num_flavors = min(3, shuffled.size())
		var remaining = num_puris
		for i in range(num_flavors):
			# Each flavor gets at least 1 puri; reserve 1 per remaining flavor
			# so we never leave a later slot with 0.
			var qty = 1
			if i == num_flavors - 1:
				qty = remaining
			else:
				qty = max(1, remaining - (num_flavors - i - 1))
			remaining -= qty
			items.append({
				"flavor": FlavorHelper.from_string(shuffled[i]),
				"quantity": qty,
				"served": 0
			})
	else:
		# Normal/VIP: random selection from available flavors
		var shuffled = available_flavors.duplicate()
		shuffled.shuffle()
		var num_different = min(randi_range(1, 2), shuffled.size())
		var remaining = num_puris
		for i in range(num_different):
			var qty: int
			if i == num_different - 1:
				qty = remaining
			else:
				qty = randi_range(1, max(1, remaining - (num_different - i - 1)))
			remaining -= qty
			items.append({
				"flavor": FlavorHelper.from_string(shuffled[i]),
				"quantity": qty,
				"served": 0
			})

	return Order.new(items)

func _ready() -> void:
	# Minimal init — real setup happens in setup() which is called after add_child()
	patience = 1.0
	_patience_timer = patience_seconds

func _process(delta: float) -> void:
	if state == CustomerState.WAITING:
		_patience_timer -= delta
		patience = clamp(_patience_timer / patience_seconds, 0.0, 1.0)
		_update_patience_bar()
		_update_mood()
		if _patience_timer <= 0.0:
			_leave_angry()

func _walk_to_queue() -> void:
	state = CustomerState.WALKING_IN
	var tween = create_tween()
	tween.tween_property(self, "position", queue_position, 0.8)
	tween.tween_callback(_on_arrived)

func _on_arrived() -> void:
	state = CustomerState.WAITING

func try_serve(flavor: int) -> bool:
	if state != CustomerState.WAITING:
		return false
	if order == null or order.is_complete():
		return false
	var success = order.try_serve(flavor)
	if success:
		if order.is_complete():
			_leave_happy()
	return success

func _leave_happy() -> void:
	state = CustomerState.LEAVING_HAPPY
	AudioManager.play_customer_happy()
	_update_visuals()
	var tween = create_tween()
	var exit_pos = Vector2(get_viewport().get_visible_rect().size.x + 100, position.y)
	tween.tween_property(self, "position", exit_pos, 0.8)
	tween.tween_callback(_emit_served_and_free)

func _leave_angry() -> void:
	if state == CustomerState.LEAVING_ANGRY or state == CustomerState.LEAVING_HAPPY:
		return
	state = CustomerState.LEAVING_ANGRY
	AudioManager.play_customer_angry()
	_update_visuals()
	var tween = create_tween()
	var exit_pos = Vector2(get_viewport().get_visible_rect().size.x + 100, position.y)
	tween.tween_property(self, "position", exit_pos, 0.8)
	tween.tween_callback(_emit_angry_and_free)

func force_leave_angry() -> void:
	_leave_angry()

func _emit_served_and_free() -> void:
	emit_signal("served", tip_amount)
	queue_free()

func _emit_angry_and_free() -> void:
	emit_signal("left_angry")
	queue_free()

func _update_visuals() -> void:
	if not is_inside_tree():
		return
	_update_mood()

func _update_mood() -> void:
	if not body_sprite:
		return
	if state == CustomerState.LEAVING_HAPPY:
		body_sprite.texture = TEXTURE_HAPPY
	elif state == CustomerState.LEAVING_ANGRY or patience <= 0.45:
		body_sprite.texture = TEXTURE_ANGRY
	else:
		body_sprite.texture = TEXTURE_NEUTRAL

func _update_patience_bar() -> void:
	if not patience_bar:
		return
	patience_bar.value = patience * 100.0
	if patience > 0.6:
		patience_bar.modulate = Color("#2ecc71")
	elif patience > 0.3:
		patience_bar.modulate = Color("#f39c12")
	else:
		patience_bar.modulate = Color("#e74c3c")

func _build_order_display() -> void:
	if not order_container or order == null:
		return
	for child in order_container.get_children():
		child.queue_free()
	for item in order.items:
		for i in range(item["quantity"]):
			var dot = ColorRect.new()
			dot.custom_minimum_size = Vector2(20, 20)
			dot.color = FlavorHelper.get_color(item["flavor"])
			order_container.add_child(dot)

func _make_gold_style() -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = Color("#1a1a2e")
	style.border_color = Color("#ffd700")
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	return style
