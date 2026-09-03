class_name FieldLootEquipEntry
extends Resource

@export var item_id: StringName
@export var target_slot: StringName = &"main"
@export var definition: Resource
@export var region_tags := PackedStringArray(["global"])


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if not (definition is EquipmentWeaponDefinition or definition is EquipmentArmorDefinition):
		errors.append("현장 장착은 무기 또는 방어구 정의만 받습니다.")
	elif item_id == &"" or not definition.is_valid():
		errors.append("현장 장착 항목에는 ID와 유효한 장비 정의가 필요합니다.")
	elif item_id != definition.get("weapon_id" if definition is EquipmentWeaponDefinition else "armor_id"):
		errors.append("현장 장착 item_id와 장비 ID가 일치해야 합니다.")
	if target_slot not in [&"main", &"secondary", &"body", &"feet"]:
		errors.append("현장 장착 대상 슬롯이 올바르지 않습니다.")
	if definition is EquipmentWeaponDefinition and target_slot not in [&"main", &"secondary"]:
		errors.append("무기는 무기 슬롯만 사용합니다.")
	if definition is EquipmentArmorDefinition and definition.slot_id != target_slot:
		errors.append("방어구 슬롯 태그와 대상 슬롯이 다릅니다.")
	if region_tags.is_empty():
		errors.append("현장 장착 항목에는 지역 태그가 하나 이상 필요합니다.")
	return errors


func to_lifecycle_definition() -> LootLifecycleDefinition:
	if not validation_errors().is_empty():
		return null
	var result := LootLifecycleDefinition.new()
	result.item_id = item_id
	result.display_name = definition.display_name
	result.item_type = &"weapon" if definition is EquipmentWeaponDefinition else &"armor"
	result.loot_family = LootLifecycleDefinition.PERSISTENT_ASSET
	result.session_behavior = &"warehouse_item"
	result.extract_result = &"warehouse"
	result.death_result = &"lost"
	result.convert_value = 0
	result.region_tags = region_tags.duplicate()
	result.description = definition.description
	return result


func get_snapshot() -> Dictionary:
	return {
		&"item_id": item_id,
		&"display_name": definition.display_name if definition != null else String(item_id),
		&"item_type": &"weapon" if definition is EquipmentWeaponDefinition else &"armor",
		&"target_slot": target_slot,
		&"weapon_id": definition.get("weapon_id") if definition is EquipmentWeaponDefinition else &"",
		&"region_tags": region_tags.duplicate(),
	}
