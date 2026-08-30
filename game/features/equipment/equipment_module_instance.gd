class_name EquipmentModuleInstance
extends Resource

@export var instance_id: StringName
@export var definition: EquipmentModuleDefinition
@export_range(1, 100, 1) var upgrade_level: int = 1


func configure(new_instance_id: StringName, new_definition: EquipmentModuleDefinition) -> void:
	instance_id = new_instance_id
	definition = new_definition
	upgrade_level = 1


func can_upgrade(maximum_level_override: int = -1) -> bool:
	var maximum_level := (
		maximum_level_override
		if maximum_level_override > 0
		else definition.maximum_upgrade_level() if definition != null else 0
	)
	return definition != null and upgrade_level < maximum_level


func upgrade(maximum_level_override: int = -1) -> bool:
	if not can_upgrade(maximum_level_override):
		return false
	upgrade_level += 1
	return true


func base_cost(balance_provider: Node = null) -> int:
	var fallback := definition.cost_at_level(upgrade_level) if definition != null else 0
	if (
		balance_provider != null
		and definition != null
		and balance_provider.has_method(&"get_module_capacity_cost")
	):
		return int(balance_provider.call(
			&"get_module_capacity_cost", definition.module_id, upgrade_level, fallback
		))
	return fallback
