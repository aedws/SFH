class_name FieldLootSkillEntry
extends Resource

@export var item_id: StringName
@export_range(0, 8, 1) var target_slot_index: int = 0
@export_range(1, 5, 1) var grade: int = 1
@export var definition: CombatSkillDefinition
@export var region_tags := PackedStringArray(["global"])


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if item_id == &"" or definition == null or not definition.is_valid():
		errors.append("현장 스킬 항목에는 ID와 유효한 전투 스킬 정의가 필요합니다.")
	elif item_id != definition.skill_id:
		errors.append("현장 스킬 item_id와 skill_id가 일치해야 합니다.")
	if target_slot_index < 0 or target_slot_index > 8:
		errors.append("현장 스킬 슬롯은 0~8 범위여야 합니다.")
	if grade < 1 or grade > 5:
		errors.append("현장 스킬 등급은 1~5 범위여야 합니다.")
	if region_tags.is_empty():
		errors.append("현장 스킬에는 지역 태그가 하나 이상 필요합니다.")
	return errors


func to_lifecycle_definition() -> LootLifecycleDefinition:
	if not validation_errors().is_empty():
		return null
	var result := LootLifecycleDefinition.new()
	result.item_id = item_id
	result.display_name = definition.display_name
	result.item_type = &"skill"
	result.loot_family = LootLifecycleDefinition.PERSISTENT_ASSET
	result.session_behavior = &"runtime_skill"
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
		&"item_type": &"skill",
		&"target_slot_index": target_slot_index,
		&"grade": grade,
		&"required_combat_tags": (
			definition.required_combat_tags.duplicate() if definition != null else []
		),
		&"region_tags": region_tags.duplicate(),
	}
