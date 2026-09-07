class_name CharacterEquipmentSystem
extends Node

const ITEM_QUALITY := preload("res://game/core/item_quality_descriptor.gd")
const FIXED_OPTION_FACTORY := preload("res://game/features/equipment/equipment_fixed_option_factory.gd")

signal equipment_changed(summary: Dictionary)
signal skill_activation_changed(active_skill_ids: PackedStringArray, inactive_skill_ids: PackedStringArray)
signal stat_modifiers_changed(modifiers: Dictionary)
signal customization_changed(snapshot: Dictionary)
signal active_weapon_changed(slot_id: StringName, weapon_definition: EquipmentWeaponDefinition)
signal weapon_upgrade_modifiers_changed(modifiers: Dictionary)
signal weapon_fixed_identity_changed(snapshot: Dictionary)

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
var character_module_state: EquipmentItemState


func _ensure_character_modules() -> void:
	if character_module_state != null: return
	character_module_state = EquipmentItemState.new()
	character_module_state.configure(&"character", CharacterModuleDefinition.new())
	character_module_state.set_upgrade_balance_provider(upgrade_balance_provider)


func set_external_character_level(value: int) -> void:
	_ensure_character_modules()
	character_module_state.level = clampi(value, 1, character_module_state.maximum_level())
	_refresh_after_customization()


func get_module_target_descriptors() -> Array[Dictionary]:
	var result := get_slot_descriptors()
	if armor_enabled:
		_ensure_character_modules()
		result.append({&"slot_id": &"character", &"kind": "character"})
	return result


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
	weapon_fixed_identity_changed.emit(get_active_weapon_identity_snapshot())
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


func active_weapon_has_combat_tags(required_tags: Array) -> bool:
	var weapon := get_active_weapon()
	if weapon == null:
		return false
	for required_tag in required_tags:
		if StringName(required_tag) not in weapon.combat_tags:
			return false
	return true


func get_active_skill_mechanic_override(skill_id: StringName) -> Dictionary:
	var weapon := get_active_weapon()
	if weapon == null:
		return {}
	return (weapon.skill_mechanic_overrides.get(skill_id, {}) as Dictionary).duplicate(true)


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
	weapon_fixed_identity_changed.emit(get_active_weapon_identity_snapshot())
	equipment_changed.emit(get_summary())
	return true


func get_active_skill_ids() -> PackedStringArray:
	return active_skill_ids.duplicate()


func get_inactive_skill_ids() -> PackedStringArray:
	return inactive_skill_ids.duplicate()


func get_stat_modifiers() -> Dictionary:
	return aggregated_stat_modifiers.duplicate(true)


## A disconnected editor copy: previews must never mutate the live player.
func create_edit_copy(preview_stats_target: Node) -> Node:
	var draft = get_script().new()
	draft.stats_target = preview_stats_target
	draft.weapons_enabled = weapons_enabled
	draft.skills_enabled = skills_enabled
	draft.armor_enabled = armor_enabled
	draft.upgrade_balance_provider = upgrade_balance_provider
	if not draft.restore_runtime_state(export_runtime_state()):
		draft.free()
		return null
	return draft


func get_slot_descriptors() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if loadout == null:
		return result
	for rule in loadout.slot_rules:
		result.append({&"slot_id": rule.slot_id, &"kind": rule.item_kind})
	return result


func get_player_stat_preview(modifiers: Dictionary) -> Dictionary:
	if is_instance_valid(stats_target) and stats_target.has_method(&"preview_modifier_source"):
		return stats_target.call(&"preview_modifier_source", &"equipment", modifiers)
	return {}


func get_equipment_state(slot_id: StringName) -> EquipmentItemState:
	if slot_id == &"character" and armor_enabled:
		_ensure_character_modules()
		return character_module_state
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
	if character_module_state != null: character_module_state.set_upgrade_balance_provider(provider)
	_refresh_after_customization()
	return true


func get_active_weapon_upgrade_modifiers() -> Dictionary:
	var state := get_equipment_state(active_weapon_slot)
	if state == null or not state.is_weapon():
		return {}
	var result: Dictionary = (
		upgrade_balance_provider.call(
			&"get_weapon_modifiers", &"weapon", state.definition_id(), state.level
		)
		if upgrade_balance_provider != null else {}
	)
	result[&"damage_multiply"] = float(result.get(&"damage_multiply", 1.0)) * state.quality_multiplier()
	for module_instance in state.installed_modules:
		if upgrade_balance_provider != null:
			_accumulate_weapon_modifier_dictionary(
				result,
				_scaled_modifier_dictionary(upgrade_balance_provider.call(
				&"get_weapon_modifiers",
				&"module",
				module_instance.definition.module_id,
				module_instance.upgrade_level
				), module_instance.item_quality_payload)
			)
	return result


func get_active_weapon_fixed_modifiers() -> Dictionary:
	var state := get_equipment_state(active_weapon_slot)
	if state == null or not state.is_weapon():
		return {}
	var result: Dictionary = {}
	for option in state.get_fixed_options():
		if option.target_kind != EquipmentFixedOption.TargetKind.WEAPON:
			continue
		var neutral := 0.0 if option.operation == EquipmentFixedOption.Operation.ADD else 1.0
		var current := float(result.get(option.modifier_id, neutral))
		result[option.modifier_id] = (
			current + option.amount
			if option.operation == EquipmentFixedOption.Operation.ADD
			else current * option.amount
		)
	return result


func get_active_weapon_identity_snapshot() -> Dictionary:
	var state := get_equipment_state(active_weapon_slot)
	if state == null or not state.is_weapon():
		return {}
	var result := state.get_fixed_identity_snapshot()
	result[&"slot_id"] = active_weapon_slot
	result[&"fixed_modifiers"] = get_active_weapon_fixed_modifiers()
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


func equip_definition(
	slot_id: StringName,
	definition: Resource,
	quality_payload: Dictionary = {}
) -> bool:
	if not can_equip_definition(slot_id, definition):
		return false
	var state := EquipmentItemState.new()
	state.configure(
		slot_id,
		definition,
		quality_payload,
		FIXED_OPTION_FACTORY.from_payload(definition, quality_payload)
	)
	return equip_state(slot_id, state)


func equip_state(slot_id: StringName, saved_state: EquipmentItemState) -> bool:
	if slot_id == &"character":
		if not armor_enabled or saved_state == null or not saved_state.definition is CharacterModuleDefinition: return false
		var checked_carrier := saved_state.duplicate(true) as EquipmentItemState
		checked_carrier.set_upgrade_balance_provider(upgrade_balance_provider)
		if not checked_carrier.validation_errors().is_empty(): return false
		character_module_state = checked_carrier
		_refresh_after_customization()
		return true
	if saved_state == null or not can_equip_definition(slot_id, saved_state.definition):
		return false
	var state := saved_state.duplicate(true) as EquipmentItemState
	state.state_id = slot_id
	state.set_upgrade_balance_provider(upgrade_balance_provider)
	equipment_states[slot_id] = state
	_assign_definition_to_loadout(slot_id, state.definition)
	_refresh_after_customization()
	if slot_id == active_weapon_slot and state.definition is EquipmentWeaponDefinition:
		active_weapon_changed.emit(active_weapon_slot, state.definition)
		weapon_fixed_identity_changed.emit(get_active_weapon_identity_snapshot())
	return true


func take_equipment_state(slot_id: StringName) -> EquipmentItemState:
	var state := get_equipment_state(slot_id)
	if state == null:
		return null
	equipment_states.erase(slot_id)
	if slot_id == &"main":
		loadout.main_weapon = null
	elif slot_id == &"secondary":
		loadout.secondary_weapon = null
	else:
		for index in range(loadout.armor.size() - 1, -1, -1):
			if loadout.armor[index].slot_id == slot_id:
				loadout.armor.remove_at(index)
	if slot_id == active_weapon_slot:
		var fallback := &"secondary" if slot_id == &"main" else &"main"
		active_weapon_slot = fallback if get_weapon(fallback) != null else slot_id
	_refresh_after_customization()
	active_weapon_changed.emit(active_weapon_slot, get_active_weapon())
	return state


func _assign_definition_to_loadout(slot_id: StringName, definition: Resource) -> void:
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


func install_part(
	slot_id: StringName,
	part: EquipmentPartDefinition,
	upgrade_level: int = 1
) -> bool:
	var state := get_equipment_state(slot_id)
	if state == null or not state.install_part(part, upgrade_level):
		return false
	_refresh_after_customization()
	return true


func install_module(
	slot_id: StringName,
	instance_id: StringName,
	module_definition: EquipmentModuleDefinition,
	upgrade_level: int = 1,
	quality_payload: Dictionary = {}
) -> bool:
	var state := get_equipment_state(slot_id)
	if state == null or not state.install_module(
		instance_id, module_definition, upgrade_level, quality_payload
	):
		return false
	_refresh_after_customization()
	return true


func uninstall_part(slot_id: StringName, part_id: StringName) -> Dictionary:
	var state := get_equipment_state(slot_id)
	var removed := state.remove_part(part_id) if state != null else {}
	if not removed.is_empty():
		_refresh_after_customization()
	return removed


func uninstall_module(slot_id: StringName, instance_id: StringName) -> Dictionary:
	var state := get_equipment_state(slot_id)
	var removed := state.remove_module(instance_id) if state != null else {}
	if not removed.is_empty():
		_refresh_after_customization()
	return removed


func export_runtime_state() -> Dictionary:
	var saved_states: Dictionary = {}
	for slot_id in equipment_states:
		saved_states[slot_id] = (equipment_states[slot_id] as EquipmentItemState).duplicate(true)
	return {
		&"loadout": loadout.duplicate(true) if loadout != null else null,
		&"equipment_states": saved_states,
		&"active_weapon_slot": active_weapon_slot,
		&"external_armor_level": external_armor_level,
		&"character_module_state": character_module_state.duplicate(true) if character_module_state != null else null,
	}


func validate_runtime_state(saved: Dictionary, weapon_paths: Dictionary = {}) -> PackedStringArray:
	var errors := PackedStringArray()
	var carrier: Resource = saved.get(&"character_module_state")
	if carrier != null:
		if not carrier is EquipmentItemState or not carrier.definition is CharacterModuleDefinition:
			errors.append("캐릭터 모듈 상태가 유효하지 않습니다.")
		else:
			var checked_carrier := carrier.duplicate(true) as EquipmentItemState
			checked_carrier.set_upgrade_balance_provider(upgrade_balance_provider)
			for message in checked_carrier.validation_errors(): errors.append(message)
	if saved.is_empty():
		return errors
	var saved_loadout := saved.get(&"loadout") as EquipmentLoadout
	var saved_states: Dictionary = saved.get(&"equipment_states", {})
	if saved_loadout == null:
		errors.append("저장된 장비 로드아웃이 없습니다.")
		return errors
	for message in saved_loadout.validation_errors():
		errors.append(message)
	for slot_id in saved_states:
		var state := saved_states[slot_id] as EquipmentItemState
		var rule := saved_loadout.get_slot_rule(StringName(slot_id))
		if state == null or rule == null or not rule.accepts(state.definition):
			errors.append("장비 슬롯 상태를 복원할 수 없습니다: %s" % slot_id)
			continue
		var checked_state := state.duplicate(true) as EquipmentItemState
		checked_state.set_upgrade_balance_provider(upgrade_balance_provider)
		for message in checked_state.validation_errors():
			errors.append("%s · %s" % [slot_id, message])
	for slot_id in weapon_paths:
		var path := String(weapon_paths[slot_id])
		if not ResourceLoader.exists(path):
			errors.append("작전 선택 무기를 찾을 수 없습니다: %s" % path)
			continue
		var definition: Resource = load(path)
		var rule := saved_loadout.get_slot_rule(StringName(slot_id))
		if rule == null or not rule.accepts(definition):
			errors.append("작전 선택 무기가 슬롯 규칙과 맞지 않습니다: %s" % slot_id)
	return errors


func validate_operation_launch(request: Dictionary) -> PackedStringArray:
	var runtime_context: Dictionary = request.get(&"runtime_context", {})
	var investment: Dictionary = request.get(&"investment_context", {}).get(&"loadout_investment", {})
	return validate_runtime_state(
		runtime_context.get(&"equipment_state", {}),
		investment.get(&"weapon_paths", {})
	)


func restore_runtime_state(saved: Dictionary) -> bool:
	if not validate_runtime_state(saved).is_empty():
		return false
	var saved_loadout := saved.get(&"loadout") as EquipmentLoadout
	var saved_states: Dictionary = saved.get(&"equipment_states", {})
	if saved_loadout == null:
		return false
	loadout = saved_loadout.duplicate(true) as EquipmentLoadout
	character_module_state = saved.get(&"character_module_state").duplicate(true) if saved.get(&"character_module_state") != null else null
	if character_module_state != null: character_module_state.set_upgrade_balance_provider(upgrade_balance_provider)
	equipment_states.clear()
	for slot_id in saved_states:
		var state := (saved_states[slot_id] as EquipmentItemState).duplicate(true) as EquipmentItemState
		if state == null or not can_equip_definition(slot_id, state.definition):
			return false
		state.state_id = slot_id
		state.set_upgrade_balance_provider(upgrade_balance_provider)
		equipment_states[slot_id] = state
	external_armor_level = maxi(1, int(saved.get(&"external_armor_level", 1)))
	active_weapon_slot = StringName(saved.get(&"active_weapon_slot", &"main"))
	if get_weapon(active_weapon_slot) == null:
		active_weapon_slot = &"main" if get_weapon(&"main") != null else &"secondary"
	_refresh_after_customization()
	active_weapon_changed.emit(active_weapon_slot, get_active_weapon())
	weapon_fixed_identity_changed.emit(get_active_weapon_identity_snapshot())
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
	if slot_id == &"character": return false # External XP, never a free UI level-up.
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
		&"active_weapon_grade": get_active_weapon().grade if get_active_weapon() != null else 0,
		&"active_weapon_combat_tags": get_active_weapon().combat_tags.duplicate() if get_active_weapon() != null else [],
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
	weapon_fixed_identity_changed.emit(get_active_weapon_identity_snapshot())


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

	var module_targets := equipment_states.values()
	if character_module_state != null: module_targets.append(character_module_state)
	for target in module_targets:
		var state := target as EquipmentItemState
		for option in state.get_fixed_options():
			if option.target_kind == EquipmentFixedOption.TargetKind.PLAYER:
				_accumulate_fixed_player_option(option)
		if state.is_armor():
			_accumulate_modifiers(
				(state.definition as EquipmentArmorDefinition).stat_modifiers,
				state.quality_multiplier()
			)
		if upgrade_balance_provider != null and state.is_armor():
			_accumulate_modifier_dictionary(upgrade_balance_provider.call(
				&"get_player_modifiers", &"armor", state.definition_id(), state.level
			))
		for part in state.installed_parts:
			_accumulate_modifiers(part.stat_modifiers)
		for module_instance in state.installed_modules:
			_accumulate_modifiers(
				module_instance.definition.stat_modifiers,
				module_instance.quality_multiplier()
			)
			if upgrade_balance_provider != null:
				_accumulate_modifier_dictionary(upgrade_balance_provider.call(
					&"get_player_modifiers",
					&"module",
					module_instance.definition.module_id,
					module_instance.upgrade_level
				), module_instance.item_quality_payload)
	stat_modifiers_changed.emit(get_stat_modifiers())


func _accumulate_fixed_player_option(option: EquipmentFixedOption) -> void:
	var entry: Dictionary = aggregated_stat_modifiers.get(
		option.modifier_id, {&"add": 0.0, &"multiply": 1.0}
	)
	if option.operation == EquipmentFixedOption.Operation.ADD:
		entry[&"add"] = float(entry[&"add"]) + option.amount
	else:
		entry[&"multiply"] = float(entry[&"multiply"]) * option.amount
	aggregated_stat_modifiers[option.modifier_id] = entry


func _accumulate_modifiers(
	modifiers: Array[EquipmentStatModifier],
	quality_multiplier: float = 1.0
) -> void:
	for modifier in modifiers:
		var stat_id := modifier.stat_id
		var entry: Dictionary = aggregated_stat_modifiers.get(
			stat_id,
			{&"add": 0.0, &"multiply": 1.0}
		)
		if modifier.operation == EquipmentStatModifier.Operation.ADD:
			entry[&"add"] = float(entry[&"add"]) + modifier.amount * quality_multiplier
		else:
			entry[&"multiply"] = float(entry[&"multiply"]) * (
				1.0 + (modifier.amount - 1.0) * quality_multiplier
			)
		aggregated_stat_modifiers[stat_id] = entry


func _accumulate_modifier_dictionary(
	modifiers: Dictionary,
	quality_payload: Dictionary = {}
) -> void:
	for stat_id in modifiers:
		var source: Dictionary = modifiers[stat_id]
		var entry: Dictionary = aggregated_stat_modifiers.get(
			stat_id, {&"add": 0.0, &"multiply": 1.0}
		)
		entry[&"add"] = (
			float(entry[&"add"])
			+ ITEM_QUALITY.scale_additive(float(source.get(&"add", 0.0)), quality_payload)
		)
		entry[&"multiply"] = (
			float(entry[&"multiply"])
			* ITEM_QUALITY.scale_multiplicative(
				float(source.get(&"multiply", 1.0)), quality_payload
			)
		)
		aggregated_stat_modifiers[stat_id] = entry


func _scaled_modifier_dictionary(modifiers: Dictionary, quality_payload: Dictionary) -> Dictionary:
	var result: Dictionary = {}
	for modifier_id in modifiers:
		var value := float(modifiers[modifier_id])
		result[modifier_id] = (
			ITEM_QUALITY.scale_additive(value, quality_payload)
			if modifier_id == &"damage_add"
			else ITEM_QUALITY.scale_multiplicative(value, quality_payload)
		)
	return result


func _accumulate_weapon_modifier_dictionary(target: Dictionary, source: Dictionary) -> void:
	for modifier_id in source:
		var neutral := 0.0 if modifier_id == &"damage_add" else 1.0
		var current := float(target.get(modifier_id, neutral))
		if modifier_id == &"damage_add":
			target[modifier_id] = current + float(source[modifier_id])
		else:
			target[modifier_id] = current * float(source[modifier_id])
