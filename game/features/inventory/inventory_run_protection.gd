class_name InventoryRunProtection
extends RefCounted
## Projects one run back to its hub checkpoint. Never pays credits or unlocks.
const Records = preload("res://game/features/inventory/inventory_reserve_policy.gd")

static func returning(baseline: Dictionary, current: Dictionary, extracted: bool) -> Dictionary:
	var result: Dictionary = Records.copy_value(baseline)
	if result.is_empty(): return result
	# Anything brought in the pouch now participates in the run, not the safe baseline.
	result[&"pouch"] = {}
	result[&"pouch_size"] = current.get(&"pouch_size", Vector2i(2, 2))
	for id in current.get(&"pouch", {}):
		for key in [&"items", &"placements", &"rotations", &"runtime_payloads"]: result.get(key, {}).erase(id)
		if not extracted:
			result[&"reserve"][id] = Records.copy_value(current.pouch[id])
	# Never reuse IDs created during this run, including items restored from sockets.
	for id in current.get(&"serials", {}): result.serials[id] = maxi(int(result.serials.get(id, 0)), int(current.serials[id]))
	return result

static func settlement_items(acquired: Dictionary, baseline: Dictionary, current: Dictionary, extracted: bool) -> Dictionary:
	var result: Dictionary = acquired.duplicate(true)
	for entry in baseline.get(&"pouch", {}).values(): _add(result, entry.definition, 1)
	for id in current.get(&"pouch", {}):
		var definition: InventoryItemDefinition = current.pouch[id].definition
		var was_safe_bag: bool = baseline.get(&"items", {}).has(id)
		if extracted:
			if was_safe_bag: _add(result, definition, 1)
		elif not was_safe_bag and result.has(definition.item_id):
			var entry: Dictionary = result[definition.item_id]
			entry.quantity = maxi(0, int(entry.get(&"quantity", 0)) - 1)
			if entry.quantity == 0: result.erase(definition.item_id)
	return result

static func _add(result: Dictionary, definition: InventoryItemDefinition, quantity: int) -> void:
	var entry: Dictionary = result.get(definition.item_id, {&"quantity": 0, &"item_id": definition.item_id, &"display_name": definition.display_name})
	entry.quantity = int(entry.quantity) + quantity
	result[definition.item_id] = entry
