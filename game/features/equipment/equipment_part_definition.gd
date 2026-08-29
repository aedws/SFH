class_name EquipmentPartDefinition
extends Resource

@export var part_id: StringName
@export var display_name: String
@export var socket_id: StringName
@export var compatible_minor_tags: Array[StringName] = []
@export var stat_modifiers: Array[EquipmentStatModifier] = []
@export var special_feature_ids: Array[StringName] = []
@export_range(1, 20, 1) var maximum_upgrade_level: int = 3


func is_valid() -> bool:
	return (
		part_id != &""
		and not display_name.is_empty()
		and socket_id != &""
		and not compatible_minor_tags.is_empty()
		and maximum_upgrade_level > 0
	)


func supports_weapon(weapon: EquipmentWeaponDefinition) -> bool:
	return (
		is_valid()
		and weapon != null
		and weapon.tags.minor_tag in compatible_minor_tags
		and socket_id in weapon.part_socket_ids
	)
