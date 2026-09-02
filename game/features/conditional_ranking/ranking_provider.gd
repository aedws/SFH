class_name RankingProvider
extends Node

signal ranking_updated(condition_key: String, entries: Array[Dictionary])
signal provider_status_changed(snapshot: Dictionary)


func submit_run(_result: Dictionary) -> Dictionary:
	return {&"accepted": false, &"reason": "랭킹 제공자가 제출을 구현하지 않음"}


func get_entries(_condition_key: String, _ranking_id: StringName = &"recovered_value") -> Array[Dictionary]:
	return []


func get_snapshot() -> Dictionary:
	return {}


func get_provider_status() -> Dictionary:
	return {
		&"mode": &"unknown",
		&"state": &"unavailable",
		&"label": "랭킹 공급자 없음",
		&"online": false,
		&"local_preserved": false,
		&"sync_state": &"none",
	}
