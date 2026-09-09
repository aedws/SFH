class_name FieldLootSkillEquipService
extends RefCounted

var skill_system: Node
var binding_provider: Node
var catalog: FieldLootEquipCatalog
var swap_history: Array[Dictionary] = []
var total_equipped := 0
var total_restored := 0


func configure(
	new_skill_system: Node,
	new_binding_provider: Node,
	new_catalog: FieldLootEquipCatalog
) -> bool:
	if new_catalog == null or not new_catalog.validation_errors().is_empty():
		return false
	for method_name in [
		&"preview_skill_replacement", &"replace_skill", &"restore_skill_replacement",
		&"get_skill_states",
	]:
		if not is_instance_valid(new_skill_system) or not new_skill_system.has_method(method_name):
			return false
	for method_name in [
		&"action_for_skill", &"replace_runtime_skill", &"restore_runtime_skill",
		&"input_label_for_skill",
	]:
		if not is_instance_valid(new_binding_provider) or not new_binding_provider.has_method(method_name):
			return false
	skill_system = new_skill_system
	binding_provider = new_binding_provider
	catalog = new_catalog
	swap_history.clear()
	total_equipped = 0
	total_restored = 0
	return true


func preview(item_id: StringName) -> Dictionary:
	if catalog == null:
		return {&"available": false}
	var entry := catalog.get_skill_entry(item_id)
	if entry == null:
		return {&"available": false}
	var runtime_preview: Dictionary = skill_system.call(
		&"preview_skill_replacement", entry.target_slot_index, entry.definition
	)
	var previous_skill_id := StringName(runtime_preview.get(&"previous_skill_id", &""))
	var action_id := StringName(binding_provider.call(&"action_for_skill", previous_skill_id))
	runtime_preview.merge({
		&"item_id": item_id,
		&"equip_kind": &"skill",
		&"grade": entry.grade,
		&"input_action": action_id,
		&"input_label": String(binding_provider.call(&"input_label_for_skill", previous_skill_id)),
		&"energy_cost": entry.definition.energy_cost,
		&"maximum_charges": entry.definition.maximum_charges,
		&"cooldown_seconds": entry.definition.cooldown_seconds,
		&"previous_destination": StringName(catalog.replaced_item_destination),
		&"previous_destination_label": catalog.destination_label(),
		&"policy_status": StringName(catalog.policy_status),
	}, true)
	return runtime_preview


func equip(item_id: StringName) -> Dictionary:
	var preview_result := preview(item_id)
	if not bool(preview_result.get(&"available", false)):
		return {
			&"success": false,
			&"reason": preview_result.get(&"reason", &"not_equipable"),
		}
	var entry := catalog.get_skill_entry(item_id)
	var previous_skill_id := StringName(preview_result.get(&"previous_skill_id", &""))
	var action_id := StringName(preview_result.get(&"input_action", &""))
	var replacement: Dictionary = skill_system.call(
		&"replace_skill", entry.target_slot_index, entry.definition
	)
	if not bool(replacement.get(&"success", false)):
		return replacement
	if not bool(binding_provider.call(
		&"replace_runtime_skill", previous_skill_id, entry.definition.skill_id, action_id, entry.definition
	)):
		skill_system.call(
			&"restore_skill_replacement",
			entry.target_slot_index,
			replacement.get(&"previous_definition"),
			float(replacement.get(&"previous_cooldown", 0.0)),
			replacement.get(&"previous_resource_state", {})
		)
		return {&"success": false, &"reason": &"binding_rejected"}
	swap_history.append({
		&"slot_index": entry.target_slot_index,
		&"previous_skill_id": previous_skill_id,
		&"current_skill_id": entry.definition.skill_id,
		&"action_id": action_id,
		&"previous_definition": replacement.get(&"previous_definition"),
		&"previous_cooldown": replacement.get(&"previous_cooldown", 0.0),
		&"previous_resource_state": replacement.get(&"previous_resource_state", {}),
	})
	total_equipped += 1
	var result := preview_result.duplicate(true)
	result[&"success"] = true
	result[&"active_skill_id"] = entry.definition.skill_id
	return result


func restore_swaps() -> int:
	var restored := 0
	for index in range(swap_history.size() - 1, -1, -1):
		var swap: Dictionary = swap_history[index]
		var restored_runtime := bool(skill_system.call(
			&"restore_skill_replacement",
			int(swap.get(&"slot_index", -1)),
			swap.get(&"previous_definition"),
			float(swap.get(&"previous_cooldown", 0.0)),
			swap.get(&"previous_resource_state", {})
		))
		var restored_binding := false
		if restored_runtime:
			restored_binding = bool(binding_provider.call(
				&"restore_runtime_skill",
				StringName(swap.get(&"current_skill_id", &"")),
				StringName(swap.get(&"previous_skill_id", &"")),
				StringName(swap.get(&"action_id", &""))
			))
		if restored_runtime and restored_binding:
			restored += 1
	swap_history.clear()
	total_restored += restored
	return restored


func get_snapshot() -> Dictionary:
	return {
		&"configured": catalog != null,
		&"total_equipped": total_equipped,
		&"pending_swap_count": swap_history.size(),
		&"total_restored": total_restored,
		&"settlement_deferred": true,
		&"bindings_persisted": false,
	}
