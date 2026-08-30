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
	var score := calculate_score(result)
	var entry := {
		&"score": score,
		&"elapsed_seconds": float(result.get(&"elapsed_seconds", 0.0)),
		&"kills": int(result.get(&"kills", 0)),
		&"recovered_value": int(result.get(&"recovered_value", 0)),
		&"timestamp": int(Time.get_unix_time_from_system()),
	}
	var entries: Array = entries_by_condition.get(condition_key, [])
	entries.append(entry)
	entries.sort_custom(func(a, b): return float(a[&"score"]) > float(b[&"score"]))
	var maximum_entries := int(policy.get("maximum_entries_per_condition"))
	if entries.size() > maximum_entries:
		entries.resize(maximum_entries)
	entries_by_condition[condition_key] = entries
	if persistence_enabled:
		_save()
	ranking_updated.emit(condition_key, entries.duplicate(true))
	return {
		&"accepted": true,
		&"condition_key": condition_key,
		&"score": score,
		&"rank": entries.find(entry) + 1,
	}


func calculate_score(result: Dictionary) -> float:
	return float(policy.call(&"calculate_score", result)) if policy != null else 0.0


func get_entries(condition_key: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in entries_by_condition.get(condition_key, []):
		result.append((entry as Dictionary).duplicate(true))
	return result


func get_snapshot() -> Dictionary:
	return {
		&"condition_count": entries_by_condition.size(),
		&"entries_by_condition": entries_by_condition.duplicate(true),
		&"maximum_entries_per_condition": (
			int(policy.get("maximum_entries_per_condition")) if policy != null else 0
		),
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
