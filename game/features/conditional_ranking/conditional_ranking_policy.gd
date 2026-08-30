class_name ConditionalRankingPolicy
extends Resource

@export_range(1, 1000, 1) var maximum_entries_per_condition := 20
@export_range(0.0, 1000.0, 0.1) var recovered_value_weight := 1.0
@export_range(0.0, 1000.0, 0.1) var kill_weight := 10.0
@export_range(0.0, 1000.0, 0.1) var reward_multiplier_weight := 100.0
@export_range(0.0, 100.0, 0.01) var elapsed_seconds_penalty := 0.25


func is_valid() -> bool:
	return (
		maximum_entries_per_condition > 0
		and recovered_value_weight >= 0.0
		and kill_weight >= 0.0
		and reward_multiplier_weight >= 0.0
		and elapsed_seconds_penalty >= 0.0
	)


func calculate_score(result: Dictionary) -> float:
	return maxf(0.0,
		float(result.get(&"recovered_value", 0)) * recovered_value_weight
		+ float(result.get(&"kills", 0)) * kill_weight
		+ float(result.get(&"reward_multiplier", 1.0)) * reward_multiplier_weight
		- float(result.get(&"elapsed_seconds", 0.0)) * elapsed_seconds_penalty
	)
