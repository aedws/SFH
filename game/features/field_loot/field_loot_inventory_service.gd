class_name FieldLootInventoryService
extends RefCounted
## Temporary run bag adapter. Settlement owns permanent warehouse quantities.
var bag: Node
var gear: Node
var catalog: FieldLootEquipCatalog
var bag_before: Dictionary = {}
var gear_before: Dictionary = {}
var restored := false


func configure(inventory: Node, equipment: Node, definitions: FieldLootEquipCatalog) -> void:
	bag = inventory
	gear = equipment
	catalog = definitions
	bag_before = bag.call(&"export_runtime_state") if bag.has_method(&"export_runtime_state") else {}
	gear_before = gear.call(&"export_runtime_state") if gear.has_method(&"export_runtime_state") else {}
	restored = false


func acquire(item_id: StringName, quantity: int) -> Dictionary:
	var item := catalog.get_inventory_definition(item_id) if catalog != null else null
	if item == null:
		return {&"success": true, &"stored_in_bag": false}
	if quantity < 1 or not bag.has_method(&"add_item"):
		return {&"success": false, &"reason": "가방 획득 계약이 준비되지 않았습니다."}
	var before: Dictionary = bag.call(&"export_runtime_state")
	var ids: Array[StringName] = []
	for _index in quantity:
		var id := StringName(bag.call(&"add_item", item))
		if id == &"":
			bag.call(&"restore_runtime_state", before)
			return {&"success": false, &"reason": "가방 공간 부족 · 전리품은 바닥에 유지됩니다."}
		ids.append(id)
	return {&"success": true, &"stored_in_bag": true, &"instance_ids": ids}


func restore_run_baseline() -> void:
	if restored:
		return
	if not bag_before.is_empty():
		bag.call(&"restore_runtime_state", bag_before)
	if not gear_before.is_empty():
		gear.call(&"restore_runtime_state", gear_before)
	restored = true
