class_name SeasonPolicy
extends Resource

## Provisional local weekly schedule. Change policy_id when changing rules.
@export var policy_id := "prototype-weekly-v1"
@export var display_name := "주간 테스트 시즌"
@export var starts_at: int = 1788134400 # 2026-08-31 00:00 UTC
@export_range(60, 31536000, 1) var duration_seconds: int = 604800
@export var recurring := true
@export_range(0, 1000, 1) var minimum_penalty_score := 10
@export var allowed_map_sizes := PackedStringArray(["small", "medium", "large"])
@export_range(1, 104, 1) var maximum_archives := 12


func is_valid() -> bool:
	return not policy_id.is_empty() and not display_name.is_empty() and starts_at >= 0 and duration_seconds >= 60 and minimum_penalty_score >= 0 and not allowed_map_sizes.is_empty() and maximum_archives > 0


func season_at(now: int) -> Dictionary:
	if now < starts_at or (not recurring and now >= starts_at + duration_seconds):
		return {}
	var index := int((now - starts_at) / duration_seconds) if recurring else 0
	var start := starts_at + index * duration_seconds
	return {
		&"season_id": "%s-%d" % [policy_id, index + 1],
		&"policy_id": policy_id,
		&"starts_at": start, &"ends_at": start + duration_seconds,
		&"display_name": "%s %d" % [display_name, index + 1],
		&"minimum_penalty_score": minimum_penalty_score,
		&"allowed_map_sizes": Array(allowed_map_sizes),
	}


func participation(season: Dictionary, contract: Dictionary) -> Dictionary:
	if season.is_empty():
		return {&"eligible": false, &"reason": "시즌 비활성"}
	var condition_key := String(contract.get(&"ranking_condition_key", contract.get(&"condition_key", "")))
	# OperationContractService publishes region|difficulty|map_size.
	var map_size := condition_key.get_slice("|", 2)
	if map_size not in season.get(&"allowed_map_sizes", []):
		return {&"eligible": false, &"reason": "시즌 참가 규모 불일치"}
	if int(contract.get(&"penalty_score", 0)) < int(season.get(&"minimum_penalty_score", 0)):
		return {&"eligible": false, &"reason": "시즌 최소 페널티 %d점 필요" % int(season.get(&"minimum_penalty_score", 0))}
	return {&"eligible": true, &"reason": "시즌 참가 가능 · 종료 전 탈출 성공 필요"}


func context_for(season: Dictionary) -> Dictionary:
	if season.is_empty():
		return {}
	return {
		&"season_id": String(season[&"season_id"]), &"policy_id": String(season[&"policy_id"]),
		&"starts_at": int(season[&"starts_at"]), &"ends_at": int(season[&"ends_at"]),
	}
