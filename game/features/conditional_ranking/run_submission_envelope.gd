class_name RunSubmissionEnvelope
extends RefCounted

const SCHEMA_VERSION := 1


func build(result: Dictionary, player_id: String, build_id: String) -> Dictionary:
	var payload := _normalized_payload(result)
	var run_id := String(payload.get(&"run_id", "")).strip_edges()
	var normalized_player_id := player_id.strip_edges()
	if run_id.is_empty() or normalized_player_id.is_empty():
		return {}
	var idempotency_key := _digest("%s|%s|%s" % [
		normalized_player_id, run_id, payload.get(&"condition_key", ""),
	])
	return {
		&"schema_version": SCHEMA_VERSION,
		&"submission_id": "run_%s" % idempotency_key.left(24),
		&"idempotency_key": idempotency_key,
		&"player_id": normalized_player_id,
		&"build_id": build_id.strip_edges() if not build_id.strip_edges().is_empty() else "development",
		&"created_at": int(Time.get_unix_time_from_system()),
		&"payload": payload,
		&"payload_digest": _payload_digest(payload),
	}


func validate(envelope: Dictionary) -> Dictionary:
	if int(envelope.get(&"schema_version", 0)) != SCHEMA_VERSION:
		return _invalid(&"unsupported_schema", "지원하지 않는 제출 형식")
	for required_key in [&"submission_id", &"idempotency_key", &"player_id", &"payload", &"payload_digest"]:
		if not envelope.has(required_key):
			return _invalid(&"missing_field", "제출 필수값 누락 · %s" % required_key)
	var payload: Variant = envelope.get(&"payload", {})
	if not payload is Dictionary:
		return _invalid(&"invalid_payload", "런 결과 형식 오류")
	if (
		float(payload.get(&"elapsed_seconds", 0.0)) <= 0.0
		or int(payload.get(&"kills", 0)) < 0
		or int(payload.get(&"recovered_value", 0)) < 0
		or float(payload.get(&"reward_multiplier", 0.0)) < 0.0
		or int(payload.get(&"penalty_score", 0)) < 0
	):
		return _invalid(&"invalid_metrics", "런 수치 범위 오류")
	var normalized := _normalized_payload(payload)
	if String(normalized.get(&"run_id", "")).is_empty():
		return _invalid(&"missing_run_id", "런 식별자 없음")
	if not bool(normalized.get(&"success", false)):
		return _invalid(&"unsuccessful_run", "성공 작전만 제출 가능")
	if String(normalized.get(&"condition_key", "")).is_empty():
		return _invalid(&"missing_condition", "랭킹 조건 없음")
	if String(envelope.get(&"payload_digest", "")) != _payload_digest(normalized):
		return _invalid(&"payload_tampered", "런 결과 무결성 검증 실패")
	var expected_key := _digest("%s|%s|%s" % [
		envelope.get(&"player_id", ""),
		normalized.get(&"run_id", ""),
		normalized.get(&"condition_key", ""),
	])
	if String(envelope.get(&"idempotency_key", "")) != expected_key:
		return _invalid(&"idempotency_mismatch", "멱등 키 검증 실패")
	return {&"valid": true, &"reason_code": &"verified", &"reason": "클라이언트 제출 검증 통과"}


func _normalized_payload(source: Dictionary) -> Dictionary:
	return {
		&"run_id": String(source.get(&"run_id", "")).strip_edges(),
		&"success": bool(source.get(&"success", false)),
		&"condition_key": String(source.get(&"condition_key", "")).strip_edges(),
		&"elapsed_seconds": snappedf(maxf(0.0, float(source.get(&"elapsed_seconds", 0.0))), 0.001),
		&"kills": maxi(0, int(source.get(&"kills", 0))),
		&"recovered_value": maxi(0, int(source.get(&"recovered_value", 0))),
		&"reward_multiplier": snappedf(maxf(0.0, float(source.get(&"reward_multiplier", 1.0))), 0.001),
		&"penalty_score": maxi(0, int(source.get(&"penalty_score", 0))),
	}


func _payload_digest(payload: Dictionary) -> String:
	return _digest("%s|%s|%s|%.3f|%d|%d|%.3f|%d" % [
		payload.get(&"run_id", ""),
		"1" if bool(payload.get(&"success", false)) else "0",
		payload.get(&"condition_key", ""),
		float(payload.get(&"elapsed_seconds", 0.0)),
		int(payload.get(&"kills", 0)),
		int(payload.get(&"recovered_value", 0)),
		float(payload.get(&"reward_multiplier", 1.0)),
		int(payload.get(&"penalty_score", 0)),
	])


func _digest(value: String) -> String:
	return value.sha256_text()


func _invalid(code: StringName, reason: String) -> Dictionary:
	return {&"valid": false, &"reason_code": code, &"reason": reason}
