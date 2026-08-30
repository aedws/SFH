class_name PenaltyConfig
extends Resource

@export var modifiers: Array[Dictionary] = []
@export_range(0, 5, 1) var maximum_selected: int = 3


func is_valid() -> bool:
	var ids := {}
	for modifier in modifiers:
		var modifier_id := StringName(modifier.get(&"modifier_id", &""))
		if modifier_id == &"" or ids.has(modifier_id):
			return false
		ids[modifier_id] = true
	return maximum_selected >= 0 and not modifiers.is_empty()


func get_modifier(modifier_id: StringName) -> Dictionary:
	for modifier in modifiers:
		if StringName(modifier.get(&"modifier_id", &"")) == modifier_id:
			return modifier.duplicate(true)
	return {}
