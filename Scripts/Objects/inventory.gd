extends Resource

class_name Inventory

@export var items: Array[InventoryItem]

func has_available_space() -> bool:
	for item in items:
		if item == null:
			return true
	return false

func get_first_empty_slot_index() -> int:
	for i in range(items.size()):
		if items[i] == null:
			return i
	return -1

func add_item(item: InventoryItem) -> bool:
	if item == null:
		print("[Inventory] add_item failed: item is null")
		return false

	var slot_index := get_first_empty_slot_index()
	if slot_index == -1:
		print("[Inventory] add_item failed: no empty slots")
		return false

	items[slot_index] = item
	print("[Inventory] add_item success: inserted '", item.name, "' into slot ", slot_index)
	return true
	
func can_add_item(item: InventoryItem) -> bool:
	return item != null and get_first_empty_slot_index() != -1
