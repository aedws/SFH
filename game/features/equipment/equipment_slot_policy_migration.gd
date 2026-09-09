class_name EquipmentSlotPolicyMigration
extends RefCounted
## Upgrade only the shipped legacy policy. Never mutate the saved snapshot or custom rules.

const VERSION_KEY := &"weapon_slot_policy"
const VERSION := &"arsenal_v1"


static func copy_current(source: EquipmentLoadout) -> EquipmentLoadout:
	if source == null:
		return null
	var result := source.duplicate(true) as EquipmentLoadout
	if result.loadout_id != &"default_operator":
		return result
	# Only expand the shipped body/feet schema; custom armor policies are preserved.
	var armor_slots := []
	var shipped_armor_rules := true
	for existing in result.slot_rules:
		if existing.item_kind == "armor":
			armor_slots.append(existing.slot_id)
			shipped_armor_rules = shipped_armor_rules and existing.required_armor_slot == existing.slot_id
	if shipped_armor_rules and armor_slots.size() == 2 and &"body" in armor_slots and &"feet" in armor_slots:
		for slot: StringName in [&"head", &"hands"]:
			var added := EquipmentSlotRule.new()
			added.slot_id = slot
			added.item_kind = "armor"
			added.required_armor_slot = slot
			result.slot_rules.append(added)
		result.extension_data[&"armor_slot_policy"] = &"sets_v1"
	if result.extension_data.has(VERSION_KEY): return result
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
