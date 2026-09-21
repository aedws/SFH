class_name ExtractionDefenseConfig
extends Resource

@export var exit_policy: ExtractionExitPolicy = preload("res://game/features/extraction/configs/default_exit_policy.tres")

@export var tier_base_seconds: Dictionary = {
	&"small": 15.0, &"medium": 20.0, &"large": 25.0,
}
@export var difficulty_multipliers: Dictionary = {
	&"standard": 1.0, &"veteran": 1.2, &"nightmare": 1.4,
}


func is_valid() -> bool:
	if exit_policy == null or not exit_policy.is_valid():
		return false
	for value in tier_base_seconds.values():
		if not is_finite(float(value)) or float(value) < 0.0:
			return false
	for value in difficulty_multipliers.values():
		if not is_finite(float(value)) or float(value) <= 0.0:
			return false
	return not tier_base_seconds.is_empty() and not difficulty_multipliers.is_empty()


func duration_for(tier_id: StringName, difficulty_id: StringName) -> float:
	return float(tier_base_seconds.get(tier_id, 20.0)) * float(
		difficulty_multipliers.get(difficulty_id, 1.0)
	)
