class_name EquipmentWeaponDefinition
extends Resource

@export var weapon_id: StringName
@export var display_name: String
@export var tags: WeaponTagProfile
@export var combat_tags: Array[StringName] = []
@export_range(1, 5, 1) var grade: int = 1
@export var skill_mechanic_overrides: Dictionary = {}
@export_range(1, 100, 1) var maximum_level: int = 3
@export_range(0, 20, 1) var module_slot_limit: int = 3
@export_range(0, 100, 1) var module_cost_limit: int = 8
@export var part_socket_ids: Array[StringName] = []
@export_multiline var description: String
@export var extension_data: Dictionary = {}


func is_valid() -> bool:
	return (
		weapon_id != &""
		and not display_name.is_empty()
		and tags != null
		and tags.is_complete()
		and not combat_tags.is_empty()
		and grade > 0
		and maximum_level > 0
		and module_slot_limit >= 0
		and module_cost_limit >= 0
	)
