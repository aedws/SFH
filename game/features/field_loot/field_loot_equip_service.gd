class_name FieldLootEquipService
extends RefCounted

var equipment_provider: Node
var catalog: FieldLootEquipCatalog
var swap_history: Array[Dictionary] = []
var total_equipped := 0
var total_restored := 0


func configure(new_equipment_provider: Node, new_catalog: FieldLootEquipCatalog) -> bool:
	if new_catalog == null or not new_catalog.validation_errors().is_empty():
		return false
	if StringName(new_catalog.replaced_item_destination) != &"run_storage":
		return false
	for method_name in [
		&"get_equipment_state", &"get_summary", &"get_active_weapon_slot",
		&"take_equipment_state", &"equip_definition", &"equip_state",
		&"set_active_weapon_slot",
	]:
		if not is_instance_valid(new_equipment_provider) or not new_equipment_provider.has_method(method_name):
			return false
	equipment_provider = new_equipment_provider
	catalog = new_catalog
	swap_history.clear()
	total_equipped = 0
	total_restored = 0
	return true


func preview(item_id: StringName) -> Dictionary:
	if catalog == null:
		return {&"available": false}
	var entry := catalog.get_entry(item_id)
	if entry == null:
		return {&"available": false}
	var current = equipment_provider.call(&"get_equipment_state", entry.target_slot)
	return {
		&"available": true,
		&"item_id": item_id,
		&"target_slot": entry.target_slot,
		&"candidate_name": entry.definition.display_name,
		&"candidate_weapon_id": entry.definition.get("weapon_id") if entry.definition is EquipmentWeaponDefinition else &"",
		&"previous_name": (
			String(current.definition.get("display_name"))
			if current != null and current.definition != null else "없음"
		),
		&"previous_destination": StringName(catalog.replaced_item_destination),
		&"previous_destination_label": catalog.destination_label(),
		&"policy_status": StringName(catalog.policy_status),
	}


func equip(item_id: StringName) -> Dictionary:
	var preview_result := preview(item_id)
	if not bool(preview_result.get(&"available", false)):
		return {&"success": false, &"reason": &"not_equipable"}
	var entry := catalog.get_entry(item_id)
	var slot_id := entry.target_slot
	if equipment_provider.has_method(&"can_equip_definition") and not equipment_provider.call(&"can_equip_definition", slot_id, entry.definition):
		return {&"success": false, &"reason": &"slot_rejected"}
	var active_before: StringName = equipment_provider.call(&"get_active_weapon_slot")
	var removed = equipment_provider.call(&"take_equipment_state", slot_id)
	if not bool(equipment_provider.call(&"equip_definition", slot_id, entry.definition)):
		if removed != null:
			equipment_provider.call(&"equip_state", slot_id, removed)
		if active_before != &"":
			equipment_provider.call(&"set_active_weapon_slot", active_before)
		return {&"success": false, &"reason": &"slot_rejected"}
	if entry.definition is EquipmentWeaponDefinition and not bool(equipment_provider.call(&"set_active_weapon_slot", slot_id)):
		equipment_provider.call(&"take_equipment_state", slot_id)
		if removed != null:
			equipment_provider.call(&"equip_state", slot_id, removed)
		if active_before != &"":
			equipment_provider.call(&"set_active_weapon_slot", active_before)
		return {&"success": false, &"reason": &"activation_rejected"}
	swap_history.append({
		&"slot_id": slot_id,
		&"previous_state": removed,
		&"equipped_item_id": item_id,
		&"active_slot_before": active_before,
	})
	total_equipped += 1
	var result := preview_result.duplicate(true)
	result[&"success"] = true
	result[&"active_weapon_id"] = equipment_provider.call(&"get_summary").get(&"active_weapon_id", &"")
	return result


func restore_swaps() -> int:
	var restored := 0
	for index in range(swap_history.size() - 1, -1, -1):
		var swap: Dictionary = swap_history[index]
		var slot_id: StringName = swap.get(&"slot_id", &"")
		equipment_provider.call(&"take_equipment_state", slot_id)
		var previous = swap.get(&"previous_state")
		if previous != null and bool(equipment_provider.call(&"equip_state", slot_id, previous)):
			restored += 1
		var active_slot_before := StringName(swap.get(&"active_slot_before", &""))
		if active_slot_before != &"":
			equipment_provider.call(&"set_active_weapon_slot", active_slot_before)
	swap_history.clear()
	total_restored += restored
	return restored


func get_snapshot() -> Dictionary:
	return {
		&"configured": catalog != null,
		&"total_equipped": total_equipped,
		&"pending_swap_count": swap_history.size(),
		&"total_restored": total_restored,
		&"policy": catalog.get_snapshot() if catalog != null else {},
		&"settlement_deferred": true,
	}
