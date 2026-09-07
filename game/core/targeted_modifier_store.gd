class_name TargetedModifierStore
extends RefCounted
## Value-only modifier source registry; consumers supply their stable target key.
var sources: Dictionary = {}


func replace(source_id: StringName, targets: Dictionary) -> void:
	if source_id == &"":
		return
	if targets.is_empty():
		sources.erase(source_id)
	else:
		sources[source_id] = targets.duplicate(true)


func remove(source_id: StringName) -> bool:
	return sources.erase(source_id)


func values_for(target_id: StringName) -> Array:
	var result: Array = []
	for targets: Dictionary in sources.values():
		if targets.has(target_id):
			result.append(targets[target_id])
	return result
