class_name EquipmentItemState
extends Resource

const QUALITY := preload("res://game/core/item_quality_descriptor.gd")

@export var state_id: StringName
@export var definition: Resource
@export_range(1, 100, 1) var level: int = 1
@export var installed_parts: Array[EquipmentPartDefinition] = []
@export var part_upgrade_levels: Dictionary = {}
@export var installed_modules: Array[EquipmentModuleInstance] = []
@export var granted_module_tags: Array[StringName] = []
@export var module_socket_tags: Dictionary = {}
@export var socket_policy: ModuleSocketPolicy = ModuleSocketPolicy.new()
@export var item_quality_payload: Dictionary = {}
@export var assigned_fixed_options: Array[EquipmentFixedOption] = []
var upgrade_balance_provider: Node


func configure(
	new_state_id: StringName,
	new_definition: Resource,
	quality_payload: Dictionary = {},
	new_fixed_options: Array[EquipmentFixedOption] = []
) -> void:
	state_id = new_state_id
	definition = new_definition
	level = 1
	installed_parts.clear()
	part_upgrade_levels.clear()
	installed_modules.clear()
	granted_module_tags.clear()
	module_socket_tags.clear()
	item_quality_payload = quality_payload.duplicate(true)
	assigned_fixed_options = new_fixed_options.duplicate(true)


func get_fixed_options() -> Array[EquipmentFixedOption]:
	var result: Array[EquipmentFixedOption] = []
	var option_ids: Dictionary = {}
	var definition_options: Array = definition.get("fixed_options") if definition != null else []
	for option in definition_options + assigned_fixed_options:
		if option == null or option_ids.has(option.option_id):
			continue
		result.append(option)
		option_ids[option.option_id] = true
	return result


func get_fixed_identity_snapshot() -> Dictionary:
	var option_snapshots: Array[Dictionary] = []
	for option in get_fixed_options():
		option_snapshots.append(option.snapshot())
	var result := {
		&"definition_id": definition_id(),
		&"fixed_options": option_snapshots,
		&"scaling_policy": &"fixed_identity",
	}
	if is_weapon():
		var weapon := definition as EquipmentWeaponDefinition
		result[&"weapon_id"] = weapon.weapon_id
		result[&"innate_skill"] = (
			weapon.innate_skill.snapshot() if weapon.innate_skill != null else {}
		)
	return result


func quality_multiplier() -> float:
	return QUALITY.multiplier(item_quality_payload)


func is_weapon() -> bool:
	return definition is EquipmentWeaponDefinition


func is_armor() -> bool:
	return definition is EquipmentArmorDefinition


func set_upgrade_balance_provider(provider: Node) -> void:
	upgrade_balance_provider = provider


func maximum_level() -> int:
	if definition is CharacterModuleDefinition: return definition.maximum_level
	var target_kind := &"weapon" if is_weapon() else &"armor" if is_armor() else &""
	var target_id := definition_id()
	var fallback := 1
	if is_weapon():
		fallback = (definition as EquipmentWeaponDefinition).maximum_level
	elif is_armor():
		fallback = (definition as EquipmentArmorDefinition).maximum_level
	if (
		upgrade_balance_provider != null
		and target_kind != &""
		and upgrade_balance_provider.has_method(&"get_maximum_level")
	):
		return int(upgrade_balance_provider.call(
			&"get_maximum_level", target_kind, target_id, fallback
		))
	return fallback


func definition_id() -> StringName:
	if definition is CharacterModuleDefinition: return &"character"
	if is_weapon():
		return (definition as EquipmentWeaponDefinition).weapon_id
	if is_armor():
		return (definition as EquipmentArmorDefinition).armor_id
	return &""


func module_slot_limit() -> int:
	if definition is CharacterModuleDefinition: return definition.module_slot_limit
	if is_weapon():
		return (definition as EquipmentWeaponDefinition).module_slot_limit
	if is_armor():
		return (definition as EquipmentArmorDefinition).module_slot_limit
	return 0


func module_cost_limit() -> int:
	if definition is CharacterModuleDefinition: return definition.module_cost_limit
	if is_weapon():
		return (definition as EquipmentWeaponDefinition).module_cost_limit
	if is_armor():
		return (definition as EquipmentArmorDefinition).module_cost_limit
	return 0


func can_install_part(part: EquipmentPartDefinition) -> bool:
	if not is_weapon() or part == null or not part.supports_weapon(definition):
		return false
	for installed_part in installed_parts:
		if installed_part.socket_id == part.socket_id:
			return false
	return true


func install_part(part: EquipmentPartDefinition, upgrade_level: int = 1) -> bool:
	if not can_install_part(part):
		return false
	installed_parts.append(part)
	part_upgrade_levels[part.part_id] = clampi(upgrade_level, 1, part.maximum_upgrade_level)
	return true


func remove_part(part_id: StringName) -> Dictionary:
	for index in range(installed_parts.size()):
		var part := installed_parts[index]
		if part.part_id != part_id:
			continue
		var result := {
			&"definition": part,
			&"upgrade_level": int(part_upgrade_levels.get(part.part_id, 1)),
		}
		installed_parts.remove_at(index)
		part_upgrade_levels.erase(part.part_id)
		return result
	return {}


func get_part(part_id: StringName) -> EquipmentPartDefinition:
	for part in installed_parts:
		if part.part_id == part_id:
			return part
	return null


func upgrade_part(part_id: StringName) -> bool:
	var part := get_part(part_id)
	if part == null:
		return false
	var current_level := int(part_upgrade_levels.get(part_id, 1))
	if current_level >= part.maximum_upgrade_level:
		return false
	part_upgrade_levels[part_id] = current_level + 1
	return true


func effective_module_cost(module_instance: EquipmentModuleInstance) -> int:
	if module_instance == null or module_instance.definition == null:
		return 0
	var cost := module_instance.base_cost(upgrade_balance_provider)
	var socket: StringName = module_socket_tags.get(module_socket_index(module_instance), &"")
	if socket != &"" and socket_policy != null: return socket_policy.cost(cost, socket, module_instance.definition.module_tags)
	for module_tag in module_instance.definition.module_tags:
		if module_tag in granted_module_tags:
			return ceili(float(cost) * 0.5)
	return cost


func used_module_cost() -> int:
	var result := 0
	for module_instance in installed_modules:
		result += effective_module_cost(module_instance)
	return result


func can_install_module(module_definition: EquipmentModuleDefinition, upgrade_level: int = 1, target_socket: int = -1) -> bool:
	if module_definition == null or not module_definition.is_valid():
		return false
	if installed_modules.size() >= module_slot_limit():
		return false
	for module_instance in installed_modules:
		if module_instance.definition.module_id == module_definition.module_id:
			return false
	var candidate := EquipmentModuleInstance.new()
	candidate.configure(&"preview", module_definition)
	candidate.upgrade_level = clampi(upgrade_level, 1, maximum_module_level(module_definition))
	candidate.socket_index = first_empty_module_socket() if target_socket < 0 else target_socket
	if candidate.socket_index < 0 or candidate.socket_index >= module_slot_limit() or module_at_socket(candidate.socket_index) != null:
		return false
	return used_module_cost() + effective_module_cost(candidate) <= module_cost_limit()


func install_module(
	instance_id: StringName,
	module_definition: EquipmentModuleDefinition,
	upgrade_level: int = 1,
	quality_payload: Dictionary = {},
	target_socket: int = -1
) -> bool:
	if not can_install_module(module_definition, upgrade_level, target_socket):
		return false
	_normalize_module_sockets()
	var module_instance := EquipmentModuleInstance.new()
	module_instance.configure(instance_id, module_definition, quality_payload)
	module_instance.socket_index = first_empty_module_socket() if target_socket < 0 else target_socket
	module_instance.upgrade_level = clampi(
		upgrade_level, 1, maximum_module_level(module_definition)
	)
	installed_modules.append(module_instance)
	return true


func maximum_module_level(module_definition: EquipmentModuleDefinition) -> int:
	var fallback := module_definition.maximum_upgrade_level()
	if upgrade_balance_provider != null and upgrade_balance_provider.has_method(&"get_maximum_level"):
		return int(upgrade_balance_provider.call(&"get_maximum_level", &"module", module_definition.module_id, fallback))
	return fallback


func remove_module(instance_id: StringName) -> Dictionary:
	_normalize_module_sockets()
	for index in range(installed_modules.size()):
		var module_instance := installed_modules[index]
		if module_instance.instance_id != instance_id:
			continue
		var result := {
			&"definition": module_instance.definition,
			&"upgrade_level": module_instance.upgrade_level,
			&"item_quality_payload": module_instance.item_quality_payload.duplicate(true),
		}
		installed_modules.remove_at(index)
		return result
	return {}


func upgrade_module(instance_id: StringName) -> bool:
	for module_instance in installed_modules:
		if module_instance.instance_id == instance_id:
			var maximum_level := module_instance.definition.maximum_upgrade_level()
			if (
				upgrade_balance_provider != null
				and upgrade_balance_provider.has_method(&"get_maximum_level")
			):
				maximum_level = int(upgrade_balance_provider.call(
					&"get_maximum_level",
					&"module",
					module_instance.definition.module_id,
					maximum_level
				))
			return module_instance.upgrade(maximum_level)
	return false


func get_module_instance(instance_id: StringName) -> EquipmentModuleInstance:
	for module_instance in installed_modules:
		if module_instance.instance_id == instance_id:
			return module_instance
	return null


func get_upgrade_context(target_kind: StringName, target_id: StringName) -> Dictionary:
	if target_kind == &"part":
		var part := get_part(target_id)
		if part == null:
			return {}
		return {
			&"target_kind": &"part",
			&"target_id": part.part_id,
			&"current_level": int(part_upgrade_levels.get(part.part_id, 1)),
			&"maximum_level": part.maximum_upgrade_level,
			&"material_resource": part,
		}
	if target_kind == &"module":
		var module_instance := get_module_instance(target_id)
		if module_instance == null or module_instance.definition == null:
			return {}
		var maximum_level := module_instance.definition.maximum_upgrade_level()
		if (
			upgrade_balance_provider != null
			and upgrade_balance_provider.has_method(&"get_maximum_level")
		):
			maximum_level = int(upgrade_balance_provider.call(
				&"get_maximum_level",
				&"module",
				module_instance.definition.module_id,
				maximum_level
			))
		return {
			&"target_kind": &"module",
			&"target_id": module_instance.instance_id,
			&"balance_target_id": module_instance.definition.module_id,
			&"current_level": module_instance.upgrade_level,
			&"maximum_level": maximum_level,
			&"material_resource": module_instance.definition,
		}
	return {}


func level_up() -> bool:
	if level >= maximum_level():
		return false
	level += 1
	return true


func grant_module_tag(module_tag: StringName) -> bool:
	if level < maximum_level() or module_tag == &"" or module_tag in granted_module_tags:
		return false
	granted_module_tags.append(module_tag)
	return true


func module_socket_index(instance: EquipmentModuleInstance) -> int:
	return instance.socket_index if instance.socket_index >= 0 else installed_modules.find(instance)


func _normalize_module_sockets() -> void:
	for index in installed_modules.size():
		if installed_modules[index].socket_index < 0: installed_modules[index].socket_index = index


func module_at_socket(index: int) -> EquipmentModuleInstance:
	for instance in installed_modules:
		if module_socket_index(instance) == index: return instance
	return null


func first_empty_module_socket() -> int:
	for index in module_slot_limit():
		if module_at_socket(index) == null: return index
	return -1


func assign_module_socket(index: int, tag: StringName) -> bool:
	if level < maximum_level() or index < 0 or index >= module_slot_limit() or tag == &"": return false
	var previous := module_socket_tags.duplicate()
	module_socket_tags[index] = tag
	if used_module_cost() > module_cost_limit():
		module_socket_tags = previous
		return false
	return true


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if socket_policy == null or not socket_policy.is_valid(): errors.append("모듈 소켓 비용 정책이 유효하지 않습니다.")
	if definition == null or not (is_weapon() or is_armor() or definition is CharacterModuleDefinition) or not bool(definition.call(&"is_valid")):
		errors.append("장비 정의가 유효하지 않습니다.")
		return errors
	if level < 1 or level > maximum_level():
		errors.append("장비 레벨이 현재 강화 규칙 범위를 벗어났습니다.")
	var part_ids := PackedStringArray()
	var sockets := PackedStringArray()
	if not is_weapon() and not installed_parts.is_empty():
		errors.append("방어구에는 무기 파츠를 장착할 수 없습니다.")
	for part in installed_parts:
		if part == null or not part.is_valid() or not part.supports_weapon(definition):
			errors.append("현재 무기와 호환되지 않는 파츠가 있습니다.")
			continue
		if String(part.part_id) in part_ids or String(part.socket_id) in sockets:
			errors.append("파츠 ID 또는 소켓이 중복됩니다: %s" % part.display_name)
		part_ids.append(String(part.part_id))
		sockets.append(String(part.socket_id))
		var part_level := int(part_upgrade_levels.get(part.part_id, 0))
		if part_level < 1 or part_level > part.maximum_upgrade_level:
			errors.append("파츠 강화 단계가 범위를 벗어났습니다: %s" % part.display_name)
	for part_id in part_upgrade_levels:
		var installed := false
		for equipped_part in installed_parts:
			if equipped_part != null and String(equipped_part.part_id) == String(part_id):
				installed = true
				break
		if not installed:
			errors.append("장착되지 않은 파츠의 강화 상태가 남아 있습니다: %s" % part_id)
	var instance_ids := PackedStringArray()
	var occupied_sockets: Array[int] = []
	for socket in module_socket_tags:
		if not socket is int or socket < 0 or socket >= module_slot_limit() or String(module_socket_tags[socket]).is_empty():
			errors.append("유효하지 않은 모듈 소켓입니다.")
	var module_ids := PackedStringArray()
	if installed_modules.size() > module_slot_limit():
		errors.append("모듈 슬롯 제한을 초과했습니다.")
	for module_instance in installed_modules:
		if module_instance == null or module_instance.definition == null or not module_instance.definition.is_valid():
			errors.append("유효하지 않은 모듈 인스턴스가 있습니다.")
			continue
		if module_instance.instance_id == &"" or String(module_instance.instance_id) in instance_ids:
			errors.append("모듈 인스턴스 ID가 비어 있거나 중복됩니다.")
		if String(module_instance.definition.module_id) in module_ids:
			errors.append("동일한 모듈이 중복 장착됐습니다: %s" % module_instance.definition.display_name)
		instance_ids.append(String(module_instance.instance_id))
		var socket := module_socket_index(module_instance)
		if socket < 0 or socket >= module_slot_limit() or socket in occupied_sockets:
			errors.append("모듈 소켓이 중복되거나 범위를 벗어났습니다.")
		occupied_sockets.append(socket)
		module_ids.append(String(module_instance.definition.module_id))
		var maximum_module_level := module_instance.definition.maximum_upgrade_level()
		if upgrade_balance_provider != null and upgrade_balance_provider.has_method(&"get_maximum_level"):
			maximum_module_level = int(upgrade_balance_provider.call(
				&"get_maximum_level", &"module", module_instance.definition.module_id,
				maximum_module_level
			))
		if module_instance.upgrade_level < 1 or module_instance.upgrade_level > maximum_module_level:
			errors.append("모듈 강화 단계가 현재 규칙 범위를 벗어났습니다: %s" % module_instance.definition.display_name)
	if used_module_cost() > module_cost_limit():
		errors.append("모듈 장착 코스트 제한을 초과했습니다.")
	var granted_tags := PackedStringArray()
	for module_tag in granted_module_tags:
		if module_tag == &"" or String(module_tag) in granted_tags:
			errors.append("개조 모듈 태그가 비어 있거나 중복됩니다.")
		granted_tags.append(String(module_tag))
	for option in assigned_fixed_options:
		if option == null or not option.is_valid():
			errors.append("유효하지 않은 장비 고정 옵션이 있습니다.")
			continue
		if is_weapon() and option.target_kind != EquipmentFixedOption.TargetKind.WEAPON:
			errors.append("무기에는 무기 대상 고정 옵션만 부여할 수 있습니다.")
		if is_armor() and option.target_kind != EquipmentFixedOption.TargetKind.PLAYER:
			errors.append("방어구에는 플레이어 대상 고정 옵션만 부여할 수 있습니다.")
	return errors


func display_name() -> String:
	if definition == null:
		return "없음"
	return String(definition.get("display_name"))


func snapshot() -> Dictionary:
	var part_names := PackedStringArray()
	for part in installed_parts:
		part_names.append("%s Lv.%d" % [
			part.display_name,
			int(part_upgrade_levels.get(part.part_id, 1)),
		])
	var module_lines := PackedStringArray()
	var module_instance_ids := PackedStringArray()
	var granted_tags := PackedStringArray()
	for module_tag in granted_module_tags:
		granted_tags.append(String(module_tag))
	for module_instance in installed_modules:
		module_instance_ids.append(String(module_instance.instance_id))
		module_lines.append("%s Lv.%d (%d)" % [
			module_instance.definition.display_name,
			module_instance.upgrade_level,
			effective_module_cost(module_instance),
		])
	return {
		&"state_id": state_id,
		&"display_name": display_name(),
		&"level": level,
		&"maximum_level": maximum_level(),
		&"parts": part_names,
		&"modules": module_lines,
		&"module_instance_ids": module_instance_ids,
		&"module_count": installed_modules.size(),
		&"module_slot_limit": module_slot_limit(),
		&"used_module_cost": used_module_cost(),
		&"module_cost_limit": module_cost_limit(),
		&"granted_module_tags": granted_tags,
		&"quality_label": QUALITY.label(item_quality_payload),
		&"quality_multiplier": quality_multiplier(),
		&"quality_socket_count": QUALITY.socket_count(item_quality_payload),
		&"fixed_identity": get_fixed_identity_snapshot(),
	}
