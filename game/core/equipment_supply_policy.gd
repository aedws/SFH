class_name EquipmentSupplyPolicy
extends Resource
## Source admission only. Never mutates owned equipment, its innate skill, or saves.
@export_range(1, 5) var maximum_grade := 3
@export_range(1, 3) var minimum_sockets := 1
@export_range(1, 3) var maximum_sockets := 2
@export var basic_affix_stats: Array[StringName] = [&"damage_multiply", &"fire_interval_reduction", &"max_health", &"defense"]
@export var basic_quality_options: Array[StringName] = [&"worn_output", &"factory_spec", &"overclocked_output"]

static func hub_default() -> EquipmentSupplyPolicy:
	return load("res://game/core/configs/default_equipment_supply.tres").duplicate(true)

func is_valid() -> bool:
	return maximum_grade >= 1 and maximum_grade <= 5 and minimum_sockets >= 1 and maximum_sockets >= minimum_sockets and maximum_sockets <= 3 and not basic_affix_stats.is_empty()

func source_error(metadata: Dictionary) -> String:
	if not is_valid(): return "공급 정책 오류"
	var grade: Variant = metadata.get(&"grade", 1)
	if not grade is int or grade < 1: return "장비 등급 오류"
	if grade > maximum_grade: return "거점 공급 등급 초과 · 심층 현장 전용"
	var unique: Variant = metadata.get(&"unique_modifiers", [])
	if not unique is Array: return "고유 옵션 형식 오류"
	if bool(metadata.get(&"deep_only", false)) or not unique.is_empty():
		return "종결 고유 옵션 · 심층 현장 전용"
	return ""

func recipe_preview(recipe: Dictionary) -> Dictionary:
	var reason := source_error(recipe)
	var low: Variant = recipe.get(&"minimum_sockets", 0)
	var high: Variant = recipe.get(&"maximum_sockets", low)
	if not low is int or not high is int or low < 0 or high < low:
		reason = "소켓 범위 오류"
	elif high > maximum_sockets:
		reason = "거점 소켓 상한 초과 · 심층 현장 전용"
	return {&"valid": reason.is_empty(), &"reason": reason, &"grade": recipe.get(&"grade", 1),
		&"minimum_sockets": maxi(minimum_sockets, int(low)), &"maximum_sockets": maxi(minimum_sockets, int(high)),
		&"supply_source": &"hub", &"supply_policy": "거점 공급 · 최대 G%d · 기본 수치 · %d~%d소켓" % [maximum_grade, minimum_sockets, maximum_sockets]}

func affixes_allowed(affixes: Array) -> bool:
	for affix in affixes:
		if not affix is Dictionary or StringName(affix.get(&"stat_id", &"")) not in basic_affix_stats: return false
	return true

func crafted_error(item: Dictionary) -> String:
	var reason := source_error(item)
	if not reason.is_empty(): return reason
	var sockets: Variant = item.get(&"sockets", [])
	var affixes: Variant = item.get(&"affixes", [])
	if not sockets is Array or not affixes is Array: return "제작 결과 형식 오류"
	if sockets.size() < minimum_sockets or sockets.size() > maximum_sockets or sockets.size() != int(item.get(&"socket_count", -1)):
		return "제작 결과 소켓 상한 위반"
	if not affixes_allowed(affixes): return "거점 제작은 기본 수치 옵션만 허용"
	return ""

func quality_error(payload: Dictionary) -> String:
	if int(payload.get(&"quality_socket_count", 0)) > maximum_sockets: return "거점 품질 소켓 상한 초과"
	for option in payload.get(&"quality_option_ids", []):
		if StringName(option) not in basic_quality_options: return "거점 공급은 기본 품질 옵션만 허용"
	return source_error(payload)
