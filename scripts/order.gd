# order.gd — Order data class: list of (flavor, quantity) pairs
class_name Order
extends RefCounted

# items is an Array of {flavor: int, quantity: int}
var items: Array = []
var current_index: int = 0

func _init(order_items: Array = []):
	items = order_items
	current_index = 0

func get_current_item() -> Dictionary:
	if current_index < items.size():
		return items[current_index]
	return {}

func is_complete() -> bool:
	return current_index >= items.size()

func try_serve(flavor: int) -> bool:
	if is_complete():
		return false
	var item = items[current_index]
	if item["flavor"] == flavor:
		item["served"] = item.get("served", 0) + 1
		if item["served"] >= item["quantity"]:
			current_index += 1
		return true
	return false

func total_puris() -> int:
	var total: int = 0
	for item in items:
		total += item["quantity"]
	return total

func remaining_puris() -> int:
	var remaining: int = 0
	for i in range(current_index, items.size()):
		var item = items[i]
		remaining += item["quantity"] - item.get("served", 0)
	return remaining
