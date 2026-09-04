class_name ShopRotationState
extends RefCounted

var rotation_index := 0
var offers: Array[Dictionary] = []
var active_run_id: StringName = &""
var completed_run_ids: Dictionary = {}
var last_reason: StringName = &"initial"
var last_changed_count := 0
var paid_reroll_count := 0


func apply(next_offers: Array[Dictionary], reason: StringName, changed_count: int) -> bool:
	if next_offers.is_empty():
		return false
	rotation_index += 1
	offers = next_offers.duplicate(true)
	last_reason = reason
	last_changed_count = maxi(0, changed_count)
	return true


func begin_run(run_id: StringName) -> bool:
	if run_id == &"" or active_run_id != &"" or completed_run_ids.has(run_id):
		return false
	active_run_id = run_id
	return true


func complete_run() -> Dictionary:
	if active_run_id == &"" or completed_run_ids.has(active_run_id):
		return {&"success": false, &"reason": "갱신할 완료 작전이 없습니다"}
	var completed_id := active_run_id
	completed_run_ids[completed_id] = true
	active_run_id = &""
	return {&"success": true, &"run_id": completed_id}


func cancel_run() -> bool:
	if active_run_id == &"":
		return false
	active_run_id = &""
	return true


func record_paid_reroll() -> void:
	paid_reroll_count += 1


func reset_paid_rerolls() -> void:
	paid_reroll_count = 0


func get_snapshot() -> Dictionary:
	return {
		&"rotation_index": rotation_index,
		&"offers": offers.duplicate(true),
		&"active_run_id": active_run_id,
		&"completed_run_count": completed_run_ids.size(),
		&"last_refresh_reason": last_reason,
		&"last_changed_count": last_changed_count,
		&"paid_reroll_count": paid_reroll_count,
	}
