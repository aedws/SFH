class_name TrainingLoadoutSnapshot
extends Resource

@export var equipment_state: Dictionary = {}
@export var inventory_state: Dictionary = {}
@export var captured := false


func capture(equipment_provider: Node, inventory_provider: Node) -> bool:
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
	return captured


func restore(equipment_provider: Node, inventory_provider: Node) -> bool:
	if not captured or not is_instance_valid(equipment_provider) or not is_instance_valid(inventory_provider):
		return false
	# Restore the bag first so equipped-item round trips see the original ownership state.
	return (
		bool(inventory_provider.call(&"restore_runtime_state", inventory_state))
		and bool(equipment_provider.call(&"restore_runtime_state", equipment_state))
	)


func get_snapshot() -> Dictionary:
	return {
		&"captured": captured,
		&"equipment_slots": (
			(equipment_state.get(&"equipment_states", {}) as Dictionary).size()
			if captured else 0
		),
		&"inventory_items": (
			(inventory_state.get(&"items", {}) as Dictionary).size() if captured else 0
		),
	}
