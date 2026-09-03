class_name ConditionalRankingPolicy
extends Resource

@export_range(1, 1000, 1) var maximum_entries_per_condition := 20
@export_range(0.0, 1000.0, 0.1) var recovered_value_weight := 1.0
@export_range(0.0, 1000.0, 0.1) var kill_weight := 10.0
## Provisional Slayer policy: total kills first, explicit boss defeats break ties.
@export var slayer_boss_tiebreak_enabled := true
@export_range(0.0, 1000.0, 0.1) var reward_multiplier_weight := 100.0
@export_range(0.0, 100.0, 0.01) var elapsed_seconds_penalty := 0.25
@export_range(0, 1000, 1) var minimum_penalty_score := 10
@export var ranking_ids := PackedStringArray(["recovered_value", "elapsed_seconds", "kills"])


func is_valid() -> bool:
	return (
		maximum_entries_per_condition > 0
		and recovered_value_weight >= 0.0
		and kill_weight >= 0.0
		and reward_multiplier_weight >= 0.0
		and elapsed_seconds_penalty >= 0.0
		and not ranking_ids.is_empty()
	)


func calculate_score(result: Dictionary) -> float:
	return maxf(0.0,
		float(result.get(&"recovered_value", 0)) * recovered_value_weight
		+ float(result.get(&"kills", 0)) * kill_weight
		+ float(result.get(&"reward_multiplier", 1.0)) * reward_multiplier_weight
		- float(result.get(&"elapsed_seconds", 0.0)) * elapsed_seconds_penalty
	)


func metric_value(ranking_id: StringName, result: Dictionary) -> float:
	match ranking_id:
		&"elapsed_seconds":
			return float(result.get(&"elapsed_seconds", INF))
		&"kills":
			return float(result.get(&"kills", 0))
		_:
			return float(result.get(&"recovered_value", 0))


func ranks_before(ranking_id: StringName, first: Dictionary, second: Dictionary) -> bool:
	var first_value := metric_value(ranking_id, first)
	var second_value := metric_value(ranking_id, second)
	if is_equal_approx(first_value, second_value):
		if ranking_id == &"kills" and slayer_boss_tiebreak_enabled:
			var first_bosses := int(first.get(&"boss_kills", 0))
			var second_bosses := int(second.get(&"boss_kills", 0))
			if first_bosses != second_bosses:
				return first_bosses > second_bosses
		return int(first.get(&"timestamp", 0)) < int(second.get(&"timestamp", 0))
	return first_value < second_value if ranking_id == &"elapsed_seconds" else first_value > second_value
