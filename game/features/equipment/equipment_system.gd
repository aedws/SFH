class_name CharacterEquipmentSystem
extends Node

signal equipment_changed(summary: Dictionary)
signal skill_activation_changed(active_skill_ids: PackedStringArray, inactive_skill_ids: PackedStringArray)
signal stat_modifiers_changed(modifiers: Dictionary)
signal customization_changed(snapshot: Dictionary)
signal active_weapon_changed(slot_id: StringName, weapon_definition: EquipmentWeaponDefinition)
signal weapon_upgrade_modifiers_changed(modifiers: Dictionary)

const TARGET_METHOD := &"apply_equipment_modifiers"

var loadout: EquipmentLoadout
var stats_target: Node
var weapons_enabled: bool = true
var skills_enabled: bool = true
var armor_enabled: bool = true
var active_skill_ids := PackedStringArray()
var inactive_skill_ids := PackedStringArray()
var aggregated_stat_modifiers: Dictionary = {}
var equipment_states: Dictionary = {}
var active_weapon_slot: StringName = &"main"
var external_armor_level: int = 1
var upgrade_balance_provider: Node


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

	loadout = new_loadout.duplicate(true) as EquipmentLoadout
	stats_target = new_stats_target
	weapons_enabled = enable_weapons
	skills_enabled = enable_skills
	armor_enabled = enable_armor
	active_weapon_slot = &"main"
	_build_equipment_states()
	_resolve_skills()
	_resolve_stat_modifiers()
	if armor_enabled:
		stats_target.call(TARGET_METHOD, aggregated_stat_modifiers)
	equipment_changed.emit(get_summary())
	customization_changed.emit(get_customization_snapshot())
	active_weapon_changed.emit(active_weapon_slot, get_active_weapon())
	return true


func get_weapon(slot_id: StringName) -> EquipmentWeaponDefinition:
	if not weapons_enabled or loadout == null:
		return null
	if slot_id == &"main":
		return loadout.main_weapon
	if slot_id == &"secondary":
		return loadout.secondary_weapon
	return null


func get_active_weapon_slot() -> StringName:
	return active_weapon_slot


func get_active_weapon() -> EquipmentWeaponDefinition:
	return get_weapon(active_weapon_slot)


func switch_active_weapon() -> bool:
	var next_slot := &"secondary" if active_weapon_slot == &"main" else &"main"
	return set_active_weapon_slot(next_slot)


func set_active_weapon_slot(slot_id: StringName) -> bool:
	if slot_id not in [&"main", &"secondary"] or get_weapon(slot_id) == null:
		return false
	if active_weapon_slot == slot_id:
		return true
	active_weapon_slot = slot_id
	active_weapon_changed.emit(active_weapon_slot, get_active_weapon())
	weapon_upgrade_modifiers_changed.emit(get_active_weapon_upgrade_modifiers())
	equipment_changed.emit(get_summary())
	return true


func get_active_skill_ids() -> PackedStringArray:
	return active_skill_ids.duplicate()


func get_inactive_skill_ids() -> PackedStringArray:
	return inactive_skill_ids.duplicate()


func get_stat_modifiers() -> Dictionary:
	return aggregated_stat_modifiers.duplicate(true)


func get_equipment_state(slot_id: StringName) -> EquipmentItemState:
	return equipment_states.get(slot_id) as EquipmentItemState


func get_customization_snapshot() -> Dictionary:
	var result: Dictionary = {}
	for slot_id in equipment_states:
		result[slot_id] = (equipment_states[slot_id] as EquipmentItemState).snapshot()
	return result


func set_upgrade_balance_provider(provider: Node) -> bool:
	if provider != null:
		for method_name in [
			&"get_maximum_level", &"get_module_capacity_cost",
			&"get_player_modifiers", &"get_weapon_modifiers",
		]:
			if not provider.has_method(method_name):
				return false
	upgrade_balance_provider = provider
	for state in equipment_states.values():
		(state as EquipmentItemState).set_upgrade_balance_provider(provider)
	_refresh_after_customization()
	return true


func get_active_weapon_upgrade_modifiers() -> Dictionary:
	var state := get_equipment_state(active_weapon_slot)
	if state == null or not state.is_weapon() or upgrade_balance_provider == null:
		return {}
	var result: Dictionary = upgrade_balance_provider.call(
		&"get_weapon_modifiers", &"weapon", state.definition_id(), state.level
	)
	for module_instance in state.installed_modules:
		_accumulate_weapon_modifier_dictionary(
			result,
			upgrade_balance_provider.call(
				&"get_weapon_modifiers",
				&"module",
				module_instance.definition.module_id,
				module_instance.upgrade_level
			)
		)
	return result


func can_equip_definition(slot_id: StringName, definition: Resource) -> bool:
	if loadout == null:
		return false
	var rule := loadout.get_slot_rule(slot_id)
	if rule == null or not rule.accepts(definition):
		return false
	if rule.item_kind == "weapon":
		return weapons_enabled
	return armor_enabled


func equip_definition(slot_id: StringName, definition: Resource) -> bool:
	if not can_equip_definition(slot_id, definition):
		return false
	var state := EquipmentItemState.new()
	state.configure(slot_id, definition)
	state.set_upgrade_balance_provider(upgrade_balance_provider)
	equipment_states[slot_id] = state
	if definition is EquipmentWeaponDefinition:
		if slot_id == &"main":
			loadout.main_weapon = definition
		elif slot_id == &"secondary":
			loadout.secondary_weapon = definition
	else:
		var replaced := false
		for index in range(loadout.armor.size()):
			if loadout.armor[index].slot_id == slot_id:
				loadout.armor[index] = definition
				replaced = true
				break
		if not replaced:
			loadout.armor.append(definition)
	_refresh_after_customization()
	if slot_id == active_weapon_slot and definition is EquipmentWeaponDefinition:
		active_weapon_changed.emit(active_weapon_slot, definition)
	return true


func install_part(slot_id: StringName, part: EquipmentPartDefinition) -> bool:
	var state := get_equipment_state(slot_id)
	if state == null or not state.install_part(part):
		return false
	_refresh_after_customization()
	return true


func install_module(
	slot_id: StringName,
	instance_id: StringName,
	module_definition: EquipmentModuleDefinition
) -> bool:
	var state := get_equipment_state(slot_id)
	if state == null or not state.install_module(instance_id, module_definition):
		return false
	_refresh_after_customization()
	return true


func upgrade_module(slot_id: StringName, instance_id: StringName) -> bool:
	var state := get_equipment_state(slot_id)
	if state == null or not state.upgrade_module(instance_id):
		return false
	_refresh_after_customization()
	return true


func upgrade_part(slot_id: StringName, part_id: StringName) -> bool:
	var state := get_equipment_state(slot_id)
	if state == null or not state.upgrade_part(part_id):
		return false
	_refresh_after_customization()
	return true


func get_upgrade_context(
	target_kind: StringName,
	slot_id: StringName,
	target_id: StringName
) -> Dictionary:
	var state := get_equipment_state(slot_id)
	return state.get_upgrade_context(target_kind, target_id) if state != null else {}


func set_external_armor_level(level: int) -> bool:
	external_armor_level = maxi(1, level)
	if stats_target == null or not stats_target.has_method(&"set_runtime_modifier_source"):
		return external_armor_level == 1
	stats_target.call(&"set_runtime_modifier_source", &"meta_armor", {
		&"defense": {
			&"add": float(external_armor_level - 1) * 0.5,
			&"multiply": 1.0,
		},
	})
	equipment_changed.emit(get_summary())
	return true


func level_up_equipment(slot_id: StringName) -> bool:
	var state := get_equipment_state(slot_id)
	if state == null or not state.level_up():
		return false
	_refresh_after_customization()
	return true


func grant_module_tag(slot_id: StringName, module_tag: StringName) -> bool:
	var state := get_equipment_state(slot_id)
	if state == null or not state.grant_module_tag(module_tag):
		return false
	_refresh_after_customization()
	return true


func get_summary() -> Dictionary:
	var main_weapon := get_weapon(&"main")
	var secondary_weapon := get_weapon(&"secondary")
	return {
		&"loadout_name": loadout.display_name if loadout != null else "",
		&"main_weapon_name": main_weapon.display_name if main_weapon != null else "없음",
		&"main_weapon_tags": main_weapon.tags.display_text() if main_weapon != null else "-",
		&"secondary_weapon_name": secondary_weapon.display_name if secondary_weapon != null else "없음",
		&"secondary_weapon_tags": secondary_weapon.tags.display_text() if secondary_weapon != null else "-",
		&"active_weapon_slot": active_weapon_slot,
		&"active_weapon_id": get_active_weapon().weapon_id if get_active_weapon() != null else &"",
		&"active_weapon_name": get_active_weapon().display_name if get_active_weapon() != null else "없음",
		&"equipped_skill_count": loadout.skills.size() if loadout != null and skills_enabled else 0,
		&"active_skill_count": active_skill_ids.size(),
		&"active_skill_ids": get_active_skill_ids(),
		&"inactive_skill_ids": get_inactive_skill_ids(),
		&"armor_count": loadout.armor.size() if loadout != null and armor_enabled else 0,
		&"external_armor_level": external_armor_level,
	}


func _build_equipment_states() -> void:
	equipment_states.clear()
	if weapons_enabled:
		_add_equipment_state(&"main", loadout.main_weapon)
		_add_equipment_state(&"secondary", loadout.secondary_weapon)
	if armor_enabled:
		for armor_item in loadout.armor:
			_add_equipment_state(armor_item.slot_id, armor_item)


func _add_equipment_state(slot_id: StringName, definition: Resource) -> void:
	if definition == null:
		return
	var state := EquipmentItemState.new()
	state.configure(slot_id, definition)
	state.set_upgrade_balance_provider(upgrade_balance_provider)
	equipment_states[slot_id] = state


func _refresh_after_customization() -> void:
	_resolve_skills()
	_resolve_stat_modifiers()
	if armor_enabled:
		stats_target.call(TARGET_METHOD, aggregated_stat_modifiers)
	equipment_changed.emit(get_summary())
	customization_changed.emit(get_customization_snapshot())
	weapon_upgrade_modifiers_changed.emit(get_active_weapon_upgrade_modifiers())


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
		_accumulate_modifiers(armor_item.stat_modifiers)
	for slot_id in equipment_states:
		var state := equipment_states[slot_id] as EquipmentItemState
		if upgrade_balance_provider != null and state.is_armor():
			_accumulate_modifier_dictionary(upgrade_balance_provider.call(
				&"get_player_modifiers", &"armor", state.definition_id(), state.level
			))
		for part in state.installed_parts:
			_accumulate_modifiers(part.stat_modifiers)
		for module_instance in state.installed_modules:
			_accumulate_modifiers(module_instance.definition.stat_modifiers)
			if upgrade_balance_provider != null:
				_accumulate_modifier_dictionary(upgrade_balance_provider.call(
					&"get_player_modifiers",
					&"module",
					module_instance.definition.module_id,
					module_instance.upgrade_level
				))
	stat_modifiers_changed.emit(get_stat_modifiers())


func _accumulate_modifiers(modifiers: Array[EquipmentStatModifier]) -> void:
	for modifier in modifiers:
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


func _accumulate_modifier_dictionary(modifiers: Dictionary) -> void:
	for stat_id in modifiers:
		var source: Dictionary = modifiers[stat_id]
		var entry: Dictionary = aggregated_stat_modifiers.get(
			stat_id, {&"add": 0.0, &"multiply": 1.0}
		)
		entry[&"add"] = float(entry[&"add"]) + float(source.get(&"add", 0.0))
		entry[&"multiply"] = (
			float(entry[&"multiply"]) * float(source.get(&"multiply", 1.0))
		)
		aggregated_stat_modifiers[stat_id] = entry


func _accumulate_weapon_modifier_dictionary(target: Dictionary, source: Dictionary) -> void:
	for modifier_id in source:
		var neutral := 0.0 if modifier_id == &"damage_add" else 1.0
		var current := float(target.get(modifier_id, neutral))
		if modifier_id == &"damage_add":
			target[modifier_id] = current + float(source[modifier_id])
		else:
			target[modifier_id] = current * float(source[modifier_id])
