class_name EquipmentModuleDefinition
extends Resource

@export var module_id: StringName
@export var display_name: String
@export var module_tags: Array[StringName] = []
@export var cost_by_upgrade_level := PackedInt32Array([4, 3, 2])
@export var stat_modifiers: Array[EquipmentStatModifier] = []
@export var special_feature_ids: Array[StringName] = []


func is_valid() -> bool:
	if module_id == &"" or display_name.is_empty() or cost_by_upgrade_level.is_empty():
		return false
	for cost in cost_by_upgrade_level:
		if cost < 0:
			return false
	return true


func maximum_upgrade_level() -> int:
	return maxi(1, cost_by_upgrade_level.size())


func cost_at_level(level: int) -> int:
	if cost_by_upgrade_level.is_empty():
		return 0
	var index := clampi(level - 1, 0, cost_by_upgrade_level.size() - 1)
	return cost_by_upgrade_level[index]
