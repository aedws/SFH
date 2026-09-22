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
@export var skill_families := ""
@export var skill_damage_multiplier := 1.0
@export var skill_cooldown_multiplier := 1.0
@export var skill_radius_multiplier := 1.0
@export var energy_capacity_multiplier := 1.0
@export var moving_energy_regeneration_multiplier := 1.0


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
	for value in [skill_damage_multiplier, skill_cooldown_multiplier, skill_radius_multiplier, energy_capacity_multiplier, moving_energy_regeneration_multiplier]:
		if not is_finite(value) or value <= 0 or value > 5: errors.append("패시브 스킬 배율 오류")
	return errors


func resource_modifiers() -> Dictionary:
	return {&"capacity_multiplier": energy_capacity_multiplier,
		&"moving_regeneration_multiplier": moving_energy_regeneration_multiplier}

func skill_specialization() -> Dictionary:
	return {&"families": skill_families, &"damage_multiplier": skill_damage_multiplier,
		&"cooldown_multiplier": skill_cooldown_multiplier, &"radius_multiplier": skill_radius_multiplier}


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
		&"skill_specialization": skill_specialization(),
		&"resource_modifiers": resource_modifiers(),
	}
