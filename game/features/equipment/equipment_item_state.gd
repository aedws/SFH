class_name EquipmentItemState
extends Resource

@export var state_id: StringName
@export var definition: Resource
@export_range(1, 100, 1) var level: int = 1
@export var installed_parts: Array[EquipmentPartDefinition] = []
@export var part_upgrade_levels: Dictionary = {}
@export var installed_modules: Array[EquipmentModuleInstance] = []
@export var granted_module_tags: Array[StringName] = []
var upgrade_balance_provider: Node


func configure(new_state_id: StringName, new_definition: Resource) -> void:
	state_id = new_state_id
	definition = new_definition
	level = 1
	installed_parts.clear()
	part_upgrade_levels.clear()
	installed_modules.clear()
	granted_module_tags.clear()


func is_weapon() -> bool:
	return definition is EquipmentWeaponDefinition


func is_armor() -> bool:
	return definition is EquipmentArmorDefinition


func set_upgrade_balance_provider(provider: Node) -> void:
	upgrade_balance_provider = provider


func maximum_level() -> int:
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
	if is_weapon():
		return (definition as EquipmentWeaponDefinition).weapon_id
	if is_armor():
		return (definition as EquipmentArmorDefinition).armor_id
	return &""


func module_slot_limit() -> int:
	if is_weapon():
		return (definition as EquipmentWeaponDefinition).module_slot_limit
	if is_armor():
		return (definition as EquipmentArmorDefinition).module_slot_limit
	return 0


func module_cost_limit() -> int:
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


func install_part(part: EquipmentPartDefinition) -> bool:
	if not can_install_part(part):
		return false
	installed_parts.append(part)
	part_upgrade_levels[part.part_id] = 1
	return true


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
	for module_tag in module_instance.definition.module_tags:
		if module_tag in granted_module_tags:
			return ceili(float(cost) * 0.5)
	return cost


func used_module_cost() -> int:
	var result := 0
	for module_instance in installed_modules:
		result += effective_module_cost(module_instance)
	return result


func can_install_module(module_definition: EquipmentModuleDefinition) -> bool:
	if module_definition == null or not module_definition.is_valid():
		return false
	if installed_modules.size() >= module_slot_limit():
		return false
	for module_instance in installed_modules:
		if module_instance.definition.module_id == module_definition.module_id:
			return false
	var candidate := EquipmentModuleInstance.new()
	candidate.configure(&"preview", module_definition)
	return used_module_cost() + effective_module_cost(candidate) <= module_cost_limit()


func install_module(instance_id: StringName, module_definition: EquipmentModuleDefinition) -> bool:
	if not can_install_module(module_definition):
		return false
	var module_instance := EquipmentModuleInstance.new()
	module_instance.configure(instance_id, module_definition)
	installed_modules.append(module_instance)
	return true


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
	}
