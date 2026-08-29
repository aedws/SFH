class_name EquipmentSlotRule
extends Resource

@export var slot_id: StringName
@export_enum("weapon", "armor") var item_kind: String = "weapon"
@export var allowed_major_tags: Array[StringName] = []
@export var allowed_middle_tags: Array[StringName] = []
@export var allowed_minor_tags: Array[StringName] = []
@export var required_armor_slot: StringName


func accepts(definition: Resource) -> bool:
	if item_kind == "weapon":
		if not definition is EquipmentWeaponDefinition:
			return false
		var weapon := definition as EquipmentWeaponDefinition
		return (
			_tag_allowed(weapon.tags.major_tag, allowed_major_tags)
			and _tag_allowed(weapon.tags.middle_tag, allowed_middle_tags)
			and _tag_allowed(weapon.tags.minor_tag, allowed_minor_tags)
		)
	if not definition is EquipmentArmorDefinition:
		return false
	var armor := definition as EquipmentArmorDefinition
	return required_armor_slot == &"" or armor.slot_id == required_armor_slot


func _tag_allowed(tag: StringName, allowed_tags: Array[StringName]) -> bool:
	return allowed_tags.is_empty() or tag in allowed_tags
