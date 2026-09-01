class_name SessionSocketRule
extends Resource

const SOCKET_TYPES := [&"rune", &"core", &"artifact"]
const REPLACEMENT_POLICIES := [&"replace_oldest", &"reject"]
const EFFECT_TARGETS := [&"weapon", &"skill", &"player"]
const OPERATIONS := [&"add", &"multiply"]

@export var rule_id: StringName
@export var item_id: StringName
@export var display_name: String
@export var socket_type: StringName
@export_range(1, 10, 1) var slot_capacity: int = 1
@export_range(1, 10, 1) var duplicate_limit: int = 1
@export var replacement_policy: StringName = &"replace_oldest"
@export var effect_target: StringName
@export var modifier_id: StringName
@export var modifier_operation: StringName = &"multiply"
@export var modifier_value: float = 1.0
@export var priority: int = 0
@export_multiline var description: String


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if rule_id == &"" or item_id == &"" or display_name.strip_edges().is_empty():
		errors.append("rule_id, item_id와 표시 이름이 필요합니다.")
	if socket_type not in SOCKET_TYPES:
		errors.append("socket_type은 rune, core, artifact 중 하나여야 합니다.")
	if slot_capacity < 1 or duplicate_limit < 1 or duplicate_limit > slot_capacity:
		errors.append("소켓 수와 중복 상한이 올바르지 않습니다.")
	if replacement_policy not in REPLACEMENT_POLICIES:
		errors.append("지원하지 않는 교체 정책입니다.")
	if effect_target not in EFFECT_TARGETS or modifier_id == &"":
		errors.append("효과 대상과 수정자 ID가 필요합니다.")
	if modifier_operation not in OPERATIONS:
		errors.append("수정자 연산은 add 또는 multiply여야 합니다.")
	if modifier_operation == &"multiply" and modifier_value <= 0.0:
		errors.append("곱연산 수정자는 0보다 커야 합니다.")
	return errors


func to_snapshot() -> Dictionary:
	return {
		&"rule_id": rule_id,
		&"item_id": item_id,
		&"display_name": display_name,
		&"socket_type": socket_type,
		&"slot_capacity": slot_capacity,
		&"duplicate_limit": duplicate_limit,
		&"replacement_policy": replacement_policy,
		&"effect_target": effect_target,
		&"modifier_id": modifier_id,
		&"modifier_operation": modifier_operation,
		&"modifier_value": modifier_value,
		&"priority": priority,
		&"description": description,
	}
