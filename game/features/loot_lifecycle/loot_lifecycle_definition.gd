class_name LootLifecycleDefinition
extends Resource

const PERSISTENT_ASSET := &"persistent_asset"
const SESSION_CONVERTIBLE := &"session_convertible"

@export var item_id: StringName
@export var display_name: String
@export var item_type: StringName
@export var grid_size := Vector2i.ONE
@export var loot_family: StringName
@export var session_behavior: StringName
@export var extract_result: StringName
@export var death_result: StringName = &"lost"
@export_range(0, 2147483647, 1) var convert_value: int = 0
@export var region_tags := PackedStringArray()
@export_multiline var description: String


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if item_type == &"blueprint" and (grid_size.x < 1 or grid_size.x > 12 or grid_size.y < 1 or grid_size.y > 8):
		errors.append("도면 가방 크기는 가로 1~12, 세로 1~8 정수여야 합니다.")
	if item_id == &"" or display_name.strip_edges().is_empty():
		errors.append("item_id와 표시 이름이 필요합니다.")
	if death_result not in [&"lost", &"retain"]:
		errors.append("death_result는 lost 또는 retain이어야 합니다.")
	if region_tags.is_empty() or _has_invalid_region_tags():
		errors.append("region_tags에는 중복되지 않은 지역 ID가 하나 이상 필요합니다.")
	if loot_family == PERSISTENT_ASSET:
		var expected_results := {
			&"warehouse_item": &"warehouse",
			&"carry_currency": &"wallet",
			&"permanent_unlock": &"permanent_unlock",
		}
		if not expected_results.has(session_behavior):
			errors.append("영구 자산의 session_behavior 조합이 올바르지 않습니다.")
		elif extract_result != expected_results[session_behavior]:
			errors.append("영구 자산의 사용 방식과 탈출 결과가 서로 충돌합니다.")
		if convert_value != 0:
			errors.append("영구 자산은 자동 환전값을 가질 수 없습니다.")
	elif loot_family == SESSION_CONVERTIBLE:
		if item_type not in [&"rune", &"core", &"artifact"]:
			errors.append("세션 증폭 자산은 rune, core, artifact 중 하나여야 합니다.")
		if session_behavior != &"session_socket" or extract_result != &"auto_convert":
			errors.append("세션 증폭 자산은 session_socket→auto_convert 조합이어야 합니다.")
		if death_result != &"lost" or convert_value <= 0:
			errors.append("세션 증폭 자산은 사망 시 소실되고 양수 환전값을 가져야 합니다.")
	else:
		errors.append("지원하지 않는 loot_family입니다: %s" % loot_family)
	return errors


func is_valid() -> bool:
	return validation_errors().is_empty()


func to_snapshot() -> Dictionary:
	return {
		&"item_id": item_id,
		&"display_name": display_name,
		&"item_type": item_type,
		&"loot_family": loot_family,
		&"session_behavior": session_behavior,
		&"extract_result": extract_result,
		&"death_result": death_result,
		&"convert_value": convert_value,
		&"region_tags": region_tags.duplicate(),
		&"description": description,
	}


func _has_invalid_region_tags() -> bool:
	var seen: Dictionary = {}
	for region_tag in region_tags:
		var normalized := region_tag.strip_edges()
		if normalized.is_empty() or seen.has(normalized):
			return true
		seen[normalized] = true
	return false
