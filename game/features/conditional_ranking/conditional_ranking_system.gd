class_name ConditionalRankingSystem
extends Node

signal ranking_updated(condition_key: String, entries: Array[Dictionary])

var storage_path := "user://sfh_rankings.json"
var persistence_enabled := true
var policy: Resource
var entries_by_condition: Dictionary = {}


func configure(
	new_storage_path: String,
	ranking_policy: Resource,
	enable_persistence: bool = true
) -> bool:
	if (
		ranking_policy == null
		or not ranking_policy.has_method(&"is_valid")
		or not ranking_policy.call(&"is_valid")
		or not ranking_policy.has_method(&"calculate_score")
	):
		return false
	storage_path = new_storage_path
	policy = ranking_policy
	persistence_enabled = enable_persistence and not storage_path.is_empty()
	entries_by_condition.clear()
	if persistence_enabled:
		_load()
	return true


func submit_run(result: Dictionary) -> Dictionary:
	if not bool(result.get(&"success", false)):
		return {&"accepted": false, &"reason": "성공 작전만 랭킹에 기록"}
	var condition_key := String(result.get(&"condition_key", ""))
	if condition_key.is_empty():
		return {&"accepted": false, &"reason": "조건 키 없음"}
	if int(result.get(&"penalty_score", 0)) < int(policy.get("minimum_penalty_score")):
		return {&"accepted": false, &"reason": "최소 페널티 점수 미달"}
	var score := calculate_score(result)
	var entry := {
		&"score": score,
		&"elapsed_seconds": float(result.get(&"elapsed_seconds", 0.0)),
		&"kills": int(result.get(&"kills", 0)),
		&"recovered_value": int(result.get(&"recovered_value", 0)),
		&"penalty_score": int(result.get(&"penalty_score", 0)),
		&"timestamp": int(Time.get_unix_time_from_system()),
	}
	var ladders: Dictionary = entries_by_condition.get(condition_key, {})
	var maximum_entries := int(policy.get("maximum_entries_per_condition"))
	var ranks := {}
	for ranking_name in policy.get("ranking_ids"):
		var ranking_id := StringName(ranking_name)
		var entries: Array = ladders.get(ranking_id, [])
		var ranking_entry := entry.duplicate(true)
		ranking_entry[&"ranking_id"] = ranking_id
		entries.append(ranking_entry)
		entries.sort_custom(func(a, b): return bool(policy.call(&"ranks_before", ranking_id, a, b)))
		if entries.size() > maximum_entries:
			entries.resize(maximum_entries)
		ladders[ranking_id] = entries
		ranks[ranking_id] = entries.find(ranking_entry) + 1
	entries_by_condition[condition_key] = ladders
	if persistence_enabled:
		_save()
	ranking_updated.emit(condition_key, get_entries(condition_key, &"recovered_value"))
	return {
		&"accepted": true,
		&"condition_key": condition_key,
		&"score": score,
		&"rank": int(ranks.get(&"recovered_value", 0)),
		&"ranks": ranks,
	}


func calculate_score(result: Dictionary) -> float:
	return float(policy.call(&"calculate_score", result)) if policy != null else 0.0


func get_entries(condition_key: String, ranking_id: StringName = &"recovered_value") -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var ladders: Variant = entries_by_condition.get(condition_key, {})
	var source: Array = ladders.get(ranking_id, []) if ladders is Dictionary else ladders
	for entry in source:
		result.append((entry as Dictionary).duplicate(true))
	return result


func get_snapshot() -> Dictionary:
	return {
		&"condition_count": entries_by_condition.size(),
		&"entries_by_condition": entries_by_condition.duplicate(true),
		&"maximum_entries_per_condition": (
			int(policy.get("maximum_entries_per_condition")) if policy != null else 0
		),
		&"ranking_ids": policy.get("ranking_ids") if policy != null else PackedStringArray(),
		&"minimum_penalty_score": int(policy.get("minimum_penalty_score")) if policy != null else 0,
	}


func _save() -> void:
	var file := FileAccess.open(storage_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(entries_by_condition))


func _load() -> void:
	if not FileAccess.file_exists(storage_path):
		return
	var file := FileAccess.open(storage_path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text()) if file != null else null
	if parsed is Dictionary:
		entries_by_condition = parsed
		_migrate_legacy_entries()


func _migrate_legacy_entries() -> void:
	for condition_key in entries_by_condition.keys():
		var legacy: Variant = entries_by_condition[condition_key]
		if not legacy is Array:
			continue
		var ladders := {}
		for ranking_name in policy.get("ranking_ids"):
			var ranking_id := StringName(ranking_name)
			var entries: Array = (legacy as Array).duplicate(true)
			entries.sort_custom(func(a, b): return bool(policy.call(&"ranks_before", ranking_id, a, b)))
			ladders[ranking_id] = entries
		entries_by_condition[condition_key] = ladders
