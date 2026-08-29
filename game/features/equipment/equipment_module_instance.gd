class_name EquipmentModuleInstance
extends Resource

@export var instance_id: StringName
@export var definition: EquipmentModuleDefinition
@export_range(1, 100, 1) var upgrade_level: int = 1


func configure(new_instance_id: StringName, new_definition: EquipmentModuleDefinition) -> void:
	instance_id = new_instance_id
	definition = new_definition
	upgrade_level = 1


func can_upgrade() -> bool:
	return definition != null and upgrade_level < definition.maximum_upgrade_level()


func upgrade() -> bool:
	if not can_upgrade():
		return false
	upgrade_level += 1
	return true


func base_cost() -> int:
	return definition.cost_at_level(upgrade_level) if definition != null else 0
