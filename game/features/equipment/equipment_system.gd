class_name CharacterEquipmentSystem
extends Node

signal equipment_changed(summary: Dictionary)
signal skill_activation_changed(active_skill_ids: PackedStringArray, inactive_skill_ids: PackedStringArray)
signal stat_modifiers_changed(modifiers: Dictionary)

const TARGET_METHOD := &"apply_equipment_modifiers"

var loadout: EquipmentLoadout
var stats_target: Node
var weapons_enabled: bool = true
var skills_enabled: bool = true
var armor_enabled: bool = true
var active_skill_ids := PackedStringArray()
var inactive_skill_ids := PackedStringArray()
var aggregated_stat_modifiers: Dictionary = {}


func configure(
	new_loadout: EquipmentLoadout,
	new_stats_target: Node,
	enable_weapons: bool = true,
	enable_skills: bool = true,
	enable_armor: bool = true
) -> bool:
	if new_loadout == null:
		push_error("EquipmentLoadout이 필요합니다.")
		return false
	var errors := new_loadout.validation_errors()
	if not errors.is_empty():
		for message in errors:
			push_error(message)
		return false
	if enable_armor and (new_stats_target == null or not new_stats_target.has_method(TARGET_METHOD)):
		push_error("방어구 스탯 대상이 apply_equipment_modifiers 계약을 구현하지 않았습니다.")
		return false

	loadout = new_loadout
	stats_target = new_stats_target
	weapons_enabled = enable_weapons
	skills_enabled = enable_skills
	armor_enabled = enable_armor
	_resolve_skills()
	_resolve_stat_modifiers()
	if armor_enabled:
		stats_target.call(TARGET_METHOD, aggregated_stat_modifiers)
	equipment_changed.emit(get_summary())
	return true


func get_weapon(slot_id: StringName) -> EquipmentWeaponDefinition:
	if not weapons_enabled or loadout == null:
		return null
	if slot_id == &"main":
		return loadout.main_weapon
	if slot_id == &"secondary":
		return loadout.secondary_weapon
	return null


func get_active_skill_ids() -> PackedStringArray:
	return active_skill_ids.duplicate()


func get_inactive_skill_ids() -> PackedStringArray:
	return inactive_skill_ids.duplicate()


func get_stat_modifiers() -> Dictionary:
	return aggregated_stat_modifiers.duplicate(true)


func get_summary() -> Dictionary:
	var main_weapon := get_weapon(&"main")
	var secondary_weapon := get_weapon(&"secondary")
	return {
		&"loadout_name": loadout.display_name if loadout != null else "",
		&"main_weapon_name": main_weapon.display_name if main_weapon != null else "없음",
		&"main_weapon_tags": main_weapon.tags.display_text() if main_weapon != null else "-",
		&"secondary_weapon_name": secondary_weapon.display_name if secondary_weapon != null else "없음",
		&"secondary_weapon_tags": secondary_weapon.tags.display_text() if secondary_weapon != null else "-",
		&"equipped_skill_count": loadout.skills.size() if loadout != null and skills_enabled else 0,
		&"active_skill_count": active_skill_ids.size(),
		&"active_skill_ids": get_active_skill_ids(),
		&"inactive_skill_ids": get_inactive_skill_ids(),
		&"armor_count": loadout.armor.size() if loadout != null and armor_enabled else 0,
	}


func _resolve_skills() -> void:
	active_skill_ids.clear()
	inactive_skill_ids.clear()
	if loadout == null or not skills_enabled:
		skill_activation_changed.emit(active_skill_ids, inactive_skill_ids)
		return

	for skill in loadout.skills:
		var is_active := weapons_enabled and _skill_matches_equipped_weapon(skill)
		if is_active:
			active_skill_ids.append(String(skill.skill_id))
		else:
			inactive_skill_ids.append(String(skill.skill_id))
	skill_activation_changed.emit(active_skill_ids, inactive_skill_ids)


func _skill_matches_equipped_weapon(skill: EquipmentSkillDefinition) -> bool:
	if skill == null:
		return false
	match skill.required_weapon_slot:
		EquipmentSkillDefinition.WeaponSlotRequirement.MAIN:
			return skill.matches_weapon(loadout.main_weapon)
		EquipmentSkillDefinition.WeaponSlotRequirement.SECONDARY:
			return skill.matches_weapon(loadout.secondary_weapon)
		_:
			return (
				skill.matches_weapon(loadout.main_weapon)
				or skill.matches_weapon(loadout.secondary_weapon)
			)


func _resolve_stat_modifiers() -> void:
	aggregated_stat_modifiers.clear()
	if loadout == null or not armor_enabled:
		stat_modifiers_changed.emit(get_stat_modifiers())
		return

	for armor_item in loadout.armor:
		for modifier in armor_item.stat_modifiers:
			var stat_id := modifier.stat_id
			var entry: Dictionary = aggregated_stat_modifiers.get(
				stat_id,
				{&"add": 0.0, &"multiply": 1.0}
			)
			if modifier.operation == EquipmentStatModifier.Operation.ADD:
				entry[&"add"] = float(entry[&"add"]) + modifier.amount
			else:
				entry[&"multiply"] = float(entry[&"multiply"]) * modifier.amount
			aggregated_stat_modifiers[stat_id] = entry
	stat_modifiers_changed.emit(get_stat_modifiers())
