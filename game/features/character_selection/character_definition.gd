class_name CharacterDefinition
extends Resource

@export var character_id: StringName
@export var display_name: String
@export_range(0, 1000000, 1) var entry_cost: int = 0
@export var passive_id: StringName
@export var passive_name: String
@export_multiline var passive_description: String
@export var max_health_add: float = 0.0
@export var defense_add: float = 0.0
@export_range(0.01, 10.0, 0.01) var movement_speed_multiplier: float = 1.0
@export var source_status: StringName = &"temporary"
@export_multiline var planner_note: String


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if character_id == &"" or display_name.strip_edges().is_empty():
		errors.append("character_id와 표시 이름이 필요합니다.")
	if passive_id == &"" or passive_name.strip_edges().is_empty():
		errors.append("패시브 ID와 이름이 필요합니다.")
	if entry_cost < 0 or movement_speed_multiplier <= 0.0:
		errors.append("투입 비용과 이동 속도 배율이 올바르지 않습니다.")
	if source_status not in [&"temporary", &"confirmed"]:
		errors.append("source_status는 temporary 또는 confirmed여야 합니다.")
	return errors


func runtime_modifiers() -> Dictionary:
	var result := {}
	if not is_zero_approx(max_health_add):
		result[&"max_health"] = {&"add": max_health_add, &"multiply": 1.0}
	if not is_zero_approx(defense_add):
		result[&"defense"] = {&"add": defense_add, &"multiply": 1.0}
	if not is_equal_approx(movement_speed_multiplier, 1.0):
		result[&"movement_speed"] = {&"add": 0.0, &"multiply": movement_speed_multiplier}
	return result


func to_snapshot() -> Dictionary:
	return {
		&"character_id": character_id, &"display_name": display_name,
		&"entry_cost": entry_cost, &"passive_id": passive_id,
		&"passive_name": passive_name, &"passive_description": passive_description,
		&"runtime_modifiers": runtime_modifiers(), &"source_status": source_status,
		&"planner_note": planner_note,
	}
