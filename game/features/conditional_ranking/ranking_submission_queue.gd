class_name RankingSubmissionQueue
extends RefCounted

signal queue_changed(snapshot: Dictionary)

var storage_path := "user://sfh_ranking_submissions.json"
var persistence_enabled := true
var maximum_pending := 64
var maximum_attempts := 5
var pending: Array[Dictionary] = []
var completed_ids: Array[String] = []
var rejected: Array[Dictionary] = []
var last_state := &"idle"
var last_reason := ""


func configure(
	new_storage_path: String,
	enable_persistence: bool,
	new_maximum_pending: int,
	new_maximum_attempts: int
) -> bool:
	storage_path = new_storage_path
	persistence_enabled = enable_persistence and not storage_path.is_empty()
	maximum_pending = maxi(1, new_maximum_pending)
	maximum_attempts = maxi(1, new_maximum_attempts)
	pending.clear()
	completed_ids.clear()
	rejected.clear()
	last_state = &"idle"
	last_reason = ""
	if persistence_enabled:
		_load()
	return true


func enqueue(envelope: Dictionary) -> Dictionary:
	var idempotency_key := String(envelope.get(&"idempotency_key", ""))
	if idempotency_key.is_empty():
		return {&"accepted": false, &"reason_code": &"missing_idempotency_key", &"reason": "멱등 키 없음"}
	if idempotency_key in completed_ids:
		return {&"accepted": true, &"duplicate": true, &"state": &"synced", &"idempotency_key": idempotency_key}
	for item in pending:
		if String(item.get(&"idempotency_key", "")) == idempotency_key:
			return {&"accepted": true, &"duplicate": true, &"state": &"queued", &"idempotency_key": idempotency_key}
	if pending.size() >= maximum_pending:
		last_state = &"queue_full"
		last_reason = "동기화 대기열 가득 참"
		_publish()
		return {&"accepted": false, &"reason_code": &"queue_full", &"reason": last_reason}
	pending.append({
		&"idempotency_key": idempotency_key,
		&"envelope": envelope.duplicate(true),
		&"attempts": 0,
		&"state": &"queued",
		&"last_reason": "",
	})
	last_state = &"queued"
	last_reason = "온라인 검증 대기"
	_commit()
	return {&"accepted": true, &"duplicate": false, &"state": &"queued", &"idempotency_key": idempotency_key}


func process(gateway: Node, maximum_items: int = 8) -> Dictionary:
	if not is_instance_valid(gateway) or not gateway.has_method(&"submit_envelope"):
		last_state = &"offline"
		last_reason = "온라인 공급자 연결 대기"
		_publish()
		return get_snapshot()
	var processed := 0
	var synced := 0
	var retrying := 0
	var permanently_rejected := 0
	var index := 0
	while index < pending.size() and processed < maxi(1, maximum_items):
		var item: Dictionary = pending[index]
		item[&"attempts"] = int(item.get(&"attempts", 0)) + 1
		item[&"state"] = &"submitting"
		var response: Variant = gateway.call(&"submit_envelope", item.get(&"envelope", {}).duplicate(true))
		processed += 1
		if not response is Dictionary:
			response = {&"accepted": false, &"retryable": true, &"reason": "온라인 응답 형식 오류"}
		var parsed := response as Dictionary
		if bool(parsed.get(&"accepted", false)):
			completed_ids.append(String(item.get(&"idempotency_key", "")))
			_trim_completed()
			pending.remove_at(index)
			synced += 1
			last_state = &"synced"
			last_reason = "서버 검증 및 동기화 완료"
			continue
		var retryable := bool(parsed.get(&"retryable", true))
		var reason := String(parsed.get(&"reason", "온라인 제출 실패"))
		item[&"last_reason"] = reason
		if not retryable or int(item.get(&"attempts", 0)) >= maximum_attempts:
			item[&"state"] = &"rejected"
			item[&"reason_code"] = parsed.get(&"reason_code", &"server_rejected")
			rejected.append(item.duplicate(true))
			if rejected.size() > 32:
				rejected.pop_front()
			pending.remove_at(index)
			permanently_rejected += 1
			last_state = &"rejected"
			last_reason = reason
			continue
		item[&"state"] = &"retry_wait"
		pending[index] = item
		retrying += 1
		last_state = &"retry_wait"
		last_reason = reason
		index += 1
	_commit()
	return get_snapshot().merged({
		&"processed": processed,
		&"synced": synced,
		&"retrying": retrying,
		&"rejected_now": permanently_rejected,
	}, true)


func get_snapshot() -> Dictionary:
	return {
		&"state": last_state,
		&"pending_count": pending.size(),
		&"completed_count": completed_ids.size(),
		&"rejected_count": rejected.size(),
		&"last_reason": last_reason,
		&"pending": pending.duplicate(true),
		&"rejected": rejected.duplicate(true),
	}


func _commit() -> void:
	if persistence_enabled:
		_save()
	_publish()


func _publish() -> void:
	queue_changed.emit(get_snapshot())


func _trim_completed() -> void:
	while completed_ids.size() > 128:
		completed_ids.pop_front()


func _save() -> void:
	var file := FileAccess.open(storage_path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify({
		"schema_version": 1,
		"pending": pending,
		"completed_ids": completed_ids,
		"rejected": rejected,
		"last_state": String(last_state),
		"last_reason": last_reason,
	}))


func _load() -> void:
	if not FileAccess.file_exists(storage_path):
		return
	var file := FileAccess.open(storage_path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(file.get_as_text()) if file != null else null
	if not parsed is Dictionary:
		return
	for item in parsed.get("pending", []):
		if item is Dictionary and pending.size() < maximum_pending:
			pending.append((item as Dictionary).duplicate(true))
	for value in parsed.get("completed_ids", []):
		completed_ids.append(String(value))
	for item in parsed.get("rejected", []):
		if item is Dictionary:
			rejected.append((item as Dictionary).duplicate(true))
	last_state = StringName(parsed.get("last_state", "idle"))
	last_reason = String(parsed.get("last_reason", ""))
	_trim_completed()
