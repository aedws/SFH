class_name EquipmentWeaponDefinition
extends Resource

@export var weapon_id: StringName
@export var display_name: String
@export var tags: WeaponTagProfile
@export_multiline var description: String
@export var extension_data: Dictionary = {}


func is_valid() -> bool:
	return weapon_id != &"" and not display_name.is_empty() and tags != null and tags.is_complete()
