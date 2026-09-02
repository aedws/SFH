class_name ConditionalRankingSystem
extends "res://game/features/conditional_ranking/ranking_provider.gd"

const LOCAL_PROVIDER_SCRIPT := preload("res://game/features/conditional_ranking/local_ranking_provider.gd")
const ONLINE_PROVIDER_SCRIPT := preload("res://game/features/conditional_ranking/online_ranking_provider_adapter.gd")
const PROVIDER_CONFIG_SCRIPT := preload("res://game/features/conditional_ranking/ranking_provider_config.gd")
const IDENTITY_SCRIPT := preload("res://game/features/conditional_ranking/ranking_identity.gd")
const ENVELOPE_SCRIPT := preload("res://game/features/conditional_ranking/run_submission_envelope.gd")
const SUBMISSION_QUEUE_SCRIPT := preload("res://game/features/conditional_ranking/ranking_submission_queue.gd")

var local_provider: Node
var online_provider: Node
var provider_config: Resource
var last_provider_status: Dictionary = {}
var identity
var envelope_builder
var submission_queue
var legacy_run_sequence := 0


func configure(
	new_storage_path: String,
	ranking_policy: Resource,
	enable_persistence: bool = true,
	new_provider_config: Resource = null,
	provider_gateway: Node = null
) -> bool:
	provider_config = new_provider_config
	if provider_config == null:
		provider_config = PROVIDER_CONFIG_SCRIPT.new()
	if not provider_config.is_valid():
		return false
	identity = IDENTITY_SCRIPT.new()
	envelope_builder = ENVELOPE_SCRIPT.new()
	submission_queue = SUBMISSION_QUEUE_SCRIPT.new()
	if not identity.configure(
		_sibling_storage_path(new_storage_path, "identity"), enable_persistence
	):
		return false
	if not submission_queue.configure(
		_sibling_storage_path(new_storage_path, "submissions"), enable_persistence,
		provider_config.maximum_pending_submissions, provider_config.maximum_submission_attempts
	):
		return false
	submission_queue.queue_changed.connect(_on_submission_queue_changed)

	if local_provider == null:
		local_provider = LOCAL_PROVIDER_SCRIPT.new()
		local_provider.name = &"LocalRankingProvider"
		add_child(local_provider)
		local_provider.ranking_updated.connect(_on_local_ranking_updated)
	if online_provider == null:
		online_provider = ONLINE_PROVIDER_SCRIPT.new()
		online_provider.name = &"OnlineRankingProvider"
		add_child(online_provider)

	if not local_provider.configure(new_storage_path, ranking_policy, enable_persistence):
		return false
	online_provider.configure(provider_gateway, provider_config.online_provider_label)
	_publish_provider_status(_resolve_provider_status())
	return true


func submit_run(result: Dictionary) -> Dictionary:
	var prepared := result.duplicate(true)
	if String(prepared.get(&"run_id", "")).strip_edges().is_empty():
		legacy_run_sequence += 1
		prepared[&"run_id"] = "legacy_%d_%d" % [Time.get_ticks_usec(), legacy_run_sequence]
	var envelope: Dictionary = envelope_builder.build(
		prepared, identity.get_player_id(), provider_config.submission_build_id
	)
	var validation: Dictionary = envelope_builder.validate(envelope)
	if not bool(validation.get(&"valid", false)):
		return {
			&"accepted": false,
			&"reason": validation.get(&"reason", "제출 검증 실패"),
			&"reason_code": validation.get(&"reason_code", &"invalid_envelope"),
			&"provider_status": _validation_rejected_status(validation),
		}
	var local_payload: Dictionary = envelope.get(&"payload", {}).duplicate(true)
	local_payload[&"player_id"] = envelope.get(&"player_id", "")
	local_payload[&"submission_id"] = envelope.get(&"submission_id", "")
	local_payload[&"idempotency_key"] = envelope.get(&"idempotency_key", "")
	# 온라인 상태와 관계없이 검증 가능한 로컬 기록을 먼저 보존합니다.
	var local_result: Dictionary = local_provider.submit_run(local_payload)
	if not bool(local_result.get(&"accepted", false)):
		var ineligible_status := _ineligible_status(String(local_result.get(&"reason", "조건 미충족")))
		local_result[&"provider_status"] = ineligible_status
		_publish_provider_status(ineligible_status)
		return local_result
	local_result[&"submission"] = {
		&"submission_id": envelope.get(&"submission_id", ""),
		&"idempotency_key": envelope.get(&"idempotency_key", ""),
		&"validation": validation,
	}

	var status := _resolve_provider_status()
	if provider_config.provider_mode == "local":
		local_result[&"provider_status"] = status
		_publish_provider_status(status)
		return local_result

	var enqueue_result: Dictionary = submission_queue.enqueue(envelope)
	local_result[&"submission"][&"queue"] = enqueue_result
	if online_provider.is_available():
		local_result[&"online_result"] = retry_pending_submissions()
		status = _status_from_submission_queue(submission_queue.get_snapshot(), true)
	else:
		status = _offline_fallback_status("온라인 공급자 연결 대기")

	local_result[&"provider_status"] = status
	_publish_provider_status(status)
	return local_result


func calculate_score(result: Dictionary) -> float:
	return local_provider.calculate_score(result) if local_provider != null else 0.0


func get_entries(condition_key: String, ranking_id: StringName = &"recovered_value") -> Array[Dictionary]:
	if (
		provider_config != null
		and provider_config.provider_mode != "local"
		and online_provider != null
		and online_provider.is_available()
	):
		var online_entries: Array[Dictionary] = online_provider.get_entries(condition_key, ranking_id)
		if not online_entries.is_empty():
			return online_entries
	return local_provider.get_entries(condition_key, ranking_id) if local_provider != null else []


func get_snapshot() -> Dictionary:
	var local_snapshot: Dictionary = local_provider.get_snapshot() if local_provider != null else {}
	var snapshot: Dictionary = local_snapshot.duplicate(true)
	snapshot[&"provider_mode"] = provider_config.provider_mode if provider_config != null else "local"
	snapshot[&"provider_status"] = get_provider_status()
	snapshot[&"local_snapshot"] = local_snapshot
	snapshot[&"online_snapshot"] = online_provider.get_snapshot() if online_provider != null else {}
	snapshot[&"identity"] = identity.get_snapshot() if identity != null else {}
	snapshot[&"submission_queue"] = submission_queue.get_snapshot() if submission_queue != null else {}
	return snapshot


func get_provider_status() -> Dictionary:
	return last_provider_status.duplicate(true) if not last_provider_status.is_empty() else _resolve_provider_status()


func set_online_gateway(provider_gateway: Node) -> void:
	if online_provider == null:
		return
	online_provider.configure(provider_gateway, provider_config.online_provider_label)
	if online_provider.is_available():
		retry_pending_submissions()
	else:
		_publish_provider_status(_resolve_provider_status())


func retry_pending_submissions() -> Dictionary:
	if submission_queue == null:
		return {}
	if online_provider == null or not online_provider.is_available():
		var offline_snapshot: Dictionary = submission_queue.get_snapshot()
		_publish_provider_status(_offline_fallback_status("온라인 공급자 연결 대기"))
		return offline_snapshot
	var snapshot: Dictionary = submission_queue.process(
		online_provider, provider_config.submissions_per_retry
	)
	_publish_provider_status(_status_from_submission_queue(snapshot, true))
	return snapshot


func set_provider_mode(mode: String) -> bool:
	if provider_config == null or mode not in ["local", "auto", "online"]:
		return false
	provider_config.provider_mode = mode
	_publish_provider_status(_resolve_provider_status())
	return true


func _resolve_provider_status() -> Dictionary:
	if provider_config == null or provider_config.provider_mode == "local":
		return local_provider.get_provider_status() if local_provider != null else super.get_provider_status()
	if online_provider != null and online_provider.is_available():
		if submission_queue != null:
			return _status_from_submission_queue(submission_queue.get_snapshot(), true)
		return {
			&"mode": StringName(provider_config.provider_mode),
			&"state": &"online_ready",
			&"label": "%s · 연결됨 · 로컬 보존" % provider_config.online_provider_label,
			&"online": true,
			&"local_preserved": true,
			&"sync_state": &"ready",
			&"last_error": "",
		}
	return _offline_fallback_status("온라인 공급자 연결 대기")


func _offline_fallback_status(reason: String) -> Dictionary:
	var fallback_enabled: bool = provider_config == null or provider_config.offline_fallback_enabled
	var queue_snapshot: Dictionary = submission_queue.get_snapshot() if submission_queue != null else {}
	var pending_count := int(queue_snapshot.get(&"pending_count", 0))
	return {
		&"mode": StringName(provider_config.provider_mode) if provider_config != null else &"local",
		&"state": &"offline_fallback" if fallback_enabled else &"unavailable",
		&"label": (
			"오프라인 · 로컬 보존 · 재시도 %d건" % pending_count
			if fallback_enabled and pending_count > 0
			else "오프라인 · 로컬 보존 · 동기화 대기"
			if fallback_enabled else "온라인 랭킹 사용 불가"
		),
		&"online": false,
		&"local_preserved": true,
		&"sync_state": &"queued" if pending_count > 0 else &"waiting_for_provider",
		&"pending_count": pending_count,
		&"last_error": reason,
	}


func _status_from_submission_queue(snapshot: Dictionary, online: bool) -> Dictionary:
	var state := StringName(snapshot.get(&"state", &"idle"))
	var pending_count := int(snapshot.get(&"pending_count", 0))
	var reason := String(snapshot.get(&"last_reason", ""))
	if state == &"rejected":
		return {
			&"mode": StringName(provider_config.provider_mode), &"state": &"rejected",
			&"label": "온라인 검증 거부 · %s · 로컬 보존" % reason,
			&"online": online, &"local_preserved": true, &"sync_state": &"rejected",
			&"pending_count": pending_count, &"last_error": reason,
		}
	if pending_count > 0:
		return {
			&"mode": StringName(provider_config.provider_mode), &"state": &"retry_wait",
			&"label": "온라인 재시도 %d건 · 로컬 보존" % pending_count,
			&"online": online, &"local_preserved": true, &"sync_state": &"queued",
			&"pending_count": pending_count, &"last_error": reason,
		}
	if state == &"synced":
		return {
			&"mode": StringName(provider_config.provider_mode), &"state": &"synced",
			&"label": "%s · 서버 검증 완료 · 로컬 보존" % provider_config.online_provider_label,
			&"online": true, &"local_preserved": true, &"sync_state": &"synced",
			&"pending_count": 0, &"last_error": "",
		}
	return {
		&"mode": StringName(provider_config.provider_mode), &"state": &"online_ready",
		&"label": "%s · 연결됨 · 제출 준비" % provider_config.online_provider_label,
		&"online": true, &"local_preserved": true, &"sync_state": &"ready",
		&"pending_count": 0, &"last_error": "",
	}


func _validation_rejected_status(validation: Dictionary) -> Dictionary:
	return {
		&"mode": StringName(provider_config.provider_mode) if provider_config != null else &"local",
		&"state": &"rejected", &"label": "제출 검증 거부 · %s" % validation.get(&"reason", "형식 오류"),
		&"online": false, &"local_preserved": false, &"sync_state": &"rejected",
		&"last_error": validation.get(&"reason", "제출 검증 실패"),
	}


func _ineligible_status(reason: String) -> Dictionary:
	return {
		&"mode": StringName(provider_config.provider_mode) if provider_config != null else &"local",
		&"state": &"ineligible",
		&"label": "랭킹 미집계 · %s" % reason,
		&"online": false,
		&"local_preserved": false,
		&"sync_state": &"not_eligible",
		&"pending_count": 0,
		&"last_error": reason,
	}


func _sibling_storage_path(base_path: String, suffix: String) -> String:
	if base_path.is_empty():
		return ""
	if base_path.ends_with(".json"):
		return "%s_%s.json" % [base_path.left(-5), suffix]
	return "%s_%s.json" % [base_path, suffix]


func _publish_provider_status(status: Dictionary) -> void:
	last_provider_status = status.duplicate(true)
	provider_status_changed.emit(last_provider_status.duplicate(true))


func _on_local_ranking_updated(condition_key: String, entries: Array[Dictionary]) -> void:
	ranking_updated.emit(condition_key, entries)


func _on_submission_queue_changed(_snapshot: Dictionary) -> void:
	_publish_provider_status(_resolve_provider_status())
