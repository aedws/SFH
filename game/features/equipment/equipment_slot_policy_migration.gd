class_name EquipmentSlotPolicyMigration
extends RefCounted
## Upgrade only the shipped legacy policy. Never mutate the saved snapshot or custom rules.

const VERSION_KEY := &"weapon_slot_policy"
const VERSION := &"arsenal_v1"


static func copy_current(source: EquipmentLoadout) -> EquipmentLoadout:
	if source == null:
		return null
	var result := source.duplicate(true) as EquipmentLoadout
	if result.loadout_id != &"default_operator" or result.extension_data.has(VERSION_KEY):
		return result
	var rule := result.get_slot_rule(&"main")
	if rule == null or rule.item_kind != "weapon":
		return result
	if rule.allowed_major_tags != [&"ranged"] or rule.allowed_middle_tags != [&"firearm"] or rule.allowed_minor_tags != [&"rifle"]:
		return result
	rule.allowed_major_tags.assign([&"ranged", &"melee"])
	rule.allowed_middle_tags.clear()
	rule.allowed_minor_tags.clear()
	result.extension_data[VERSION_KEY] = VERSION
	return result
