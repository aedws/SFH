class_name EquipmentArmorDefinition
extends Resource

@export var armor_id: StringName
@export var display_name: String
@export var slot_id: StringName = &"body"
@export_range(1, 100, 1) var maximum_level: int = 3
@export_range(0, 20, 1) var module_slot_limit: int = 2
@export_range(0, 100, 1) var module_cost_limit: int = 6
@export var stat_modifiers: Array[EquipmentStatModifier] = []
@export var fixed_options: Array[EquipmentFixedOption] = []
@export var armor_set: ArmorSetDefinition
@export_multiline var description: String
@export var extension_data: Dictionary = {}


func is_valid() -> bool:
	if armor_set != null and not armor_set.is_valid(): return false
	if armor_id == &"" or display_name.is_empty() or slot_id == &"":
		return false
	for modifier in stat_modifiers:
		if modifier == null or not modifier.is_valid():
			return false
	for option in fixed_options:
		if option == null or not option.is_valid() or option.target_kind != EquipmentFixedOption.TargetKind.PLAYER:
			return false
	return true
