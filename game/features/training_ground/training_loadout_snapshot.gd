class_name TrainingLoadoutSnapshot
extends Resource

@export var equipment_state: Dictionary = {}
@export var inventory_state: Dictionary = {}
@export var captured := false
var participant_states: Dictionary = {}
var rollback_succeeded := true


func capture(equipment_provider: Node, inventory_provider: Node, additional: Dictionary = {}) -> bool:
	if (
		not is_instance_valid(equipment_provider)
		or not equipment_provider.has_method(&"export_runtime_state")
		or not equipment_provider.has_method(&"restore_runtime_state")
		or not is_instance_valid(inventory_provider)
		or not inventory_provider.has_method(&"export_runtime_state")
		or not inventory_provider.has_method(&"restore_runtime_state")
	):
		return false
	equipment_state = equipment_provider.call(&"export_runtime_state")
	inventory_state = inventory_provider.call(&"export_runtime_state")
	captured = not equipment_state.is_empty() and not inventory_state.is_empty()
	participant_states = {&"inventory": inventory_state, &"equipment": equipment_state}
	for id in additional:
		var provider: Node = additional[id]
		if not is_instance_valid(provider) or not provider.has_method(&"export_runtime_state") or not provider.has_method(&"restore_runtime_state"):
			captured = false
			return false
		var state: Dictionary = provider.call(&"export_runtime_state")
		if state.is_empty():
			captured = false
			return false
		participant_states[id] = state
	return captured


func restore(equipment_provider: Node, inventory_provider: Node, additional: Dictionary = {}) -> bool:
	if not captured or not is_instance_valid(equipment_provider) or not is_instance_valid(inventory_provider):
		return false
	var providers := {&"inventory": inventory_provider, &"equipment": equipment_provider}
	providers.merge(additional)
	var before := {}
	# Validate every participant before changing the first one.
	for id in participant_states:
		var provider: Node = providers.get(id)
		if not is_instance_valid(provider):
			return false
		if provider.has_method(&"validate_runtime_state") and not provider.call(&"validate_runtime_state", participant_states[id]).is_empty():
			return false
		before[id] = provider.call(&"export_runtime_state")
	rollback_succeeded = true
	# Bag first: equipment round trips use original ownership, then runtime effects.
	for id in participant_states:
		if not bool(providers[id].call(&"restore_runtime_state", participant_states[id])):
			for rollback_id in before:
				if not bool(providers[rollback_id].call(&"restore_runtime_state", before[rollback_id])):
					rollback_succeeded = false
			return false
	return true


func get_snapshot() -> Dictionary:
	return {
		&"participants": PackedStringArray(participant_states.keys()),
		&"rollback_succeeded": rollback_succeeded,
		&"captured": captured,
		&"equipment_slots": (
			(equipment_state.get(&"equipment_states", {}) as Dictionary).size()
			if captured else 0
		),
		&"inventory_items": (
			(inventory_state.get(&"items", {}) as Dictionary).size() if captured else 0
		),
	}
