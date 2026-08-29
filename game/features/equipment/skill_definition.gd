class_name EquipmentSkillDefinition
extends Resource

enum WeaponSlotRequirement {
	ANY,
	MAIN,
	SECONDARY,
}

@export var skill_id: StringName
@export var display_name: String
@export var required_weapon_slot: WeaponSlotRequirement = WeaponSlotRequirement.ANY
@export var required_tags: WeaponTagProfile
@export_multiline var description: String
@export var activation_payload: Dictionary = {}


func is_valid() -> bool:
	return (
		skill_id != &""
		and not display_name.is_empty()
		and required_tags != null
		and required_tags.is_complete()
	)


func matches_weapon(weapon: EquipmentWeaponDefinition) -> bool:
	return weapon != null and weapon.is_valid() and required_tags.matches(weapon.tags)
