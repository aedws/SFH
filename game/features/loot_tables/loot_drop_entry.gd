class_name LootDropEntry
extends Resource

const ANY := &"any"
const REGIONS := [&"ruined_city", &"industrial_district", &"research_complex"]
const DIFFICULTIES := [ANY, &"standard", &"veteran", &"nightmare"]
const MAP_SIZES := [ANY, &"small", &"medium", &"large"]
const SOURCE_TYPES := [&"enemy", &"room_reward", &"vault", &"boss"]

@export var entry_id: StringName
@export var region_id: StringName
@export var difficulty_id: StringName = ANY
@export var map_size: StringName = ANY
@export var source_type: StringName
@export var item_id: StringName
@export_range(1, 5, 1) var grade: int = 1
@export_range(0.01, 100000.0, 0.01) var base_weight: float = 1.0
@export_range(1, 999, 1) var minimum_quantity: int = 1
@export_range(1, 999, 1) var maximum_quantity: int = 1
@export var boss_only: bool = false
@export_multiline var planner_note: String


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if entry_id == &"":
		errors.append("entry_id가 비어 있습니다.")
	if region_id not in REGIONS:
		errors.append("지원하지 않는 region_id입니다: %s" % region_id)
	if difficulty_id not in DIFFICULTIES:
		errors.append("지원하지 않는 difficulty_id입니다: %s" % difficulty_id)
	if map_size not in MAP_SIZES:
		errors.append("지원하지 않는 map_size입니다: %s" % map_size)
	if source_type not in SOURCE_TYPES:
		errors.append("지원하지 않는 source_type입니다: %s" % source_type)
	if item_id == &"":
		errors.append("item_id가 비어 있습니다.")
	if grade < 1 or grade > 5:
		errors.append("grade는 1~5여야 합니다.")
	if base_weight <= 0.0:
		errors.append("base_weight는 0보다 커야 합니다.")
	if minimum_quantity < 1 or maximum_quantity < minimum_quantity:
		errors.append("수량 범위가 올바르지 않습니다.")
	if boss_only and source_type != &"boss":
		errors.append("boss_only 행은 source_type이 boss여야 합니다.")
	return errors


func matches(context: Dictionary) -> bool:
	var requested_region := StringName(context.get(&"region_id", &""))
	var requested_difficulty := StringName(context.get(&"difficulty_id", ANY))
	requested_difficulty = preload("res://game/features/operation_contract/difficulty_catalog.gd").loot_band(requested_difficulty)
	var requested_map_size := StringName(context.get(&"map_size", ANY))
	var requested_source := StringName(context.get(&"source_type", ANY))
	if region_id != requested_region:
		return false
	if difficulty_id != ANY and difficulty_id != requested_difficulty:
		return false
	if map_size != ANY and map_size != requested_map_size:
		return false
	if requested_source != ANY and source_type != requested_source:
		return false
	if boss_only and not bool(context.get(&"boss_available", true)):
		return false
	return true


func effective_weight(high_grade_multiplier: float) -> float:
	return base_weight * pow(maxf(0.01, high_grade_multiplier), max(0, grade - 1))


func to_snapshot(high_grade_multiplier: float = 1.0) -> Dictionary:
	return {
		&"entry_id": entry_id,
		&"region_id": region_id,
		&"difficulty_id": difficulty_id,
		&"map_size": map_size,
		&"source_type": source_type,
		&"item_id": item_id,
		&"grade": grade,
		&"base_weight": base_weight,
		&"effective_weight": effective_weight(high_grade_multiplier),
		&"minimum_quantity": minimum_quantity,
		&"maximum_quantity": maximum_quantity,
		&"boss_only": boss_only,
		&"planner_note": planner_note,
	}
