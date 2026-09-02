extends SceneTree

const RANKING_SCENE := preload("res://game/features/conditional_ranking/conditional_ranking_system.tscn")
const POLICY := preload("res://game/features/conditional_ranking/configs/default_conditional_ranking.tres")
const CONFIG_SCRIPT := preload("res://game/features/conditional_ranking/ranking_provider_config.gd")
const ENVELOPE_SCRIPT := preload("res://game/features/conditional_ranking/run_submission_envelope.gd")


class FakeOnlineGateway extends Node:
	var available := true
	var submissions: Array[Dictionary] = []
	var accepted_keys: Array[String] = []
	var fail_next := false
	var reject_next := false

	func is_available() -> bool:
		return available

	func submit_envelope(envelope: Dictionary) -> Dictionary:
		submissions.append(envelope.duplicate(true))
		var validation: Dictionary = ENVELOPE_SCRIPT.new().validate(envelope)
		if not bool(validation.get(&"valid", false)):
			return {
				&"accepted": false, &"retryable": false,
				&"reason_code": validation.get(&"reason_code"), &"reason": validation.get(&"reason"),
			}
		if reject_next:
			reject_next = false
			return {&"accepted": false, &"retryable": false, &"reason_code": &"server_rule", &"reason": "서버 규칙 거부"}
		if fail_next:
			fail_next = false
			return {&"accepted": false, &"retryable": true, &"reason_code": &"timeout", &"reason": "네트워크 시간초과"}
		var key := String(envelope.get(&"idempotency_key", ""))
		if key in accepted_keys:
			return {&"accepted": true, &"duplicate": true, &"online_rank": accepted_keys.find(key) + 1}
		accepted_keys.append(key)
		return {&"accepted": true, &"online_rank": accepted_keys.size()}

	func get_entries(_condition_key: String, ranking_id: StringName) -> Array[Dictionary]:
		return [{&"ranking_id": ranking_id, &"score": 999.0, &"source": &"online"}]


func _initialize() -> void:
	var failures: Array[String] = []
	var ranking := RANKING_SCENE.instantiate()
	root.add_child(ranking)
	var config := CONFIG_SCRIPT.new()
	config.provider_mode = "local"
	config.submission_build_id = "p6-test"
	_check(ranking.configure("", POLICY, false, config), "로컬 공급자 구성 실패", failures)
	var ineligible: Dictionary = ranking.submit_run(_run_result("run-ineligible", 90, 12, 90.0, 0))
	_check(not bool(ineligible.get(&"accepted", true)), "조건 미달 기록이 허용됨", failures)
	_check(ineligible.get(&"provider_status", {}).get(&"state") == &"ineligible", "조건 미달 상태 누락", failures)
	_check("최소 페널티 점수 미달" in String(ineligible.get(&"provider_status", {}).get(&"label", "")), "조건 미달 이유 비표시", failures)

	var first: Dictionary = ranking.submit_run(_run_result("run-local", 100, 18, 80.0))
	_check(bool(first.get(&"accepted", false)), "로컬 기록 거부", failures)
	_check(first.get(&"provider_status", {}).get(&"state") == &"local", "로컬 상태 비표시", failures)
	_check(ranking.get_entries("small|ruined_city|standard").size() == 1, "로컬 기록 미보존", failures)

	_check(ranking.set_provider_mode("auto"), "auto 공급자 전환 실패", failures)
	var offline: Dictionary = ranking.submit_run(_run_result("run-offline", 200, 25, 70.0))
	var offline_status: Dictionary = offline.get(&"provider_status", {})
	_check(offline_status.get(&"state") == &"offline_fallback", "장애 폴백 상태 누락", failures)
	_check(offline_status.get(&"sync_state") == &"queued", "영구 재시도 대기 표시 누락", failures)
	_check(int(offline_status.get(&"pending_count", 0)) == 1, "재시도 대기 수량 누락", failures)
	_check(ranking.get_entries("small|ruined_city|standard").size() == 2, "오프라인 기록 손실", failures)

	var gateway := FakeOnlineGateway.new()
	root.add_child(gateway)
	ranking.set_online_gateway(gateway)
	_check(gateway.submissions.size() == 1, "연결 복구 시 대기 제출 미처리", failures)
	var online_result := _run_result("run-online", 300, 30, 60.0)
	var online: Dictionary = ranking.submit_run(online_result)
	_check(online.get(&"provider_status", {}).get(&"state") == &"synced", "온라인 동기화 상태 누락", failures)
	_check(gateway.submissions.size() == 2, "검증 봉투 온라인 제출 누락", failures)
	_check(not String(gateway.submissions.back().get(&"payload_digest", "")).is_empty(), "런 결과 무결성 서명 누락", failures)
	_check(ranking.local_provider.get_entries("small|ruined_city|standard").size() == 3, "온라인 제출 시 로컬 미보존", failures)
	_check(ranking.get_entries("small|ruined_city|standard")[0].get(&"source") == &"online", "온라인 조회 교체 실패", failures)
	var duplicate: Dictionary = ranking.submit_run(online_result)
	_check(bool(duplicate.get(&"duplicate", false)), "중복 런 로컬 멱등 처리 실패", failures)
	_check(gateway.submissions.size() == 2, "중복 제출이 서버로 재전송됨", failures)

	gateway.available = false
	var failed_online: Dictionary = ranking.submit_run(_run_result("run-disconnect", 400, 35, 55.0))
	_check(failed_online.get(&"provider_status", {}).get(&"state") == &"offline_fallback", "네트워크 단절 폴백 실패", failures)
	_check(ranking.local_provider.get_entries("small|ruined_city|standard").size() == 4, "네트워크 단절 기록 손실", failures)
	gateway.available = true
	gateway.fail_next = true
	ranking.set_online_gateway(gateway)
	_check(ranking.get_provider_status().get(&"state") == &"retry_wait", "시간초과 재시도 상태 누락", failures)
	ranking.retry_pending_submissions()
	_check(ranking.get_provider_status().get(&"state") == &"synced", "수동 재시도 동기화 실패", failures)
	gateway.reject_next = true
	var rejected: Dictionary = ranking.submit_run(_run_result("run-rejected", 450, 40, 50.0))
	_check(rejected.get(&"provider_status", {}).get(&"state") == &"rejected", "서버 검증 거부 상태 누락", failures)
	_check("서버 규칙 거부" in String(rejected.get(&"provider_status", {}).get(&"label", "")), "서버 거부 이유 비표시", failures)
	var snapshot: Dictionary = ranking.get_snapshot()
	_check(snapshot.has(&"identity") and snapshot.has(&"submission_queue"), "신원·제출 큐 스냅샷 계약 누락", failures)

	var envelope_builder := ENVELOPE_SCRIPT.new()
	var tampered := envelope_builder.build(_run_result("run-tampered", 500, 45, 45.0), "test-player", "test-build")
	tampered[&"payload"][&"kills"] = 9999
	_check(envelope_builder.validate(tampered).get(&"reason_code") == &"payload_tampered", "변조 기록 탐지 실패", failures)
	var invalid_metrics := envelope_builder.build(_run_result("run-invalid", 500, 45, 45.0), "test-player", "test-build")
	invalid_metrics[&"payload"][&"kills"] = -1
	invalid_metrics[&"payload_digest"] = _payload_digest_for_test(invalid_metrics.get(&"payload", {}))
	_check(envelope_builder.validate(invalid_metrics).get(&"reason_code") == &"invalid_metrics", "음수 런 수치 거부 실패", failures)

	var persistence_path := "user://sfh_p6_submission_roundtrip.json"
	for suffix in ["", "_identity", "_submissions"]:
		var path := persistence_path.replace(".json", "%s.json" % suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	var queued := RANKING_SCENE.instantiate()
	root.add_child(queued)
	var queued_config := CONFIG_SCRIPT.new()
	queued_config.provider_mode = "auto"
	queued_config.submission_build_id = "p6-roundtrip"
	_check(queued.configure(persistence_path, POLICY, true, queued_config), "영구 큐 구성 실패", failures)
	queued.submit_run(_run_result("run-roundtrip", 600, 50, 40.0))
	var restored := RANKING_SCENE.instantiate()
	root.add_child(restored)
	var restored_config := CONFIG_SCRIPT.new()
	restored_config.provider_mode = "auto"
	restored_config.submission_build_id = "p6-roundtrip"
	_check(restored.configure(persistence_path, POLICY, true, restored_config), "영구 큐 복원 구성 실패", failures)
	_check(int(restored.get_snapshot().get(&"submission_queue", {}).get(&"pending_count", 0)) == 1, "재시도 큐 저장·복원 실패", failures)
	var restored_gateway := FakeOnlineGateway.new()
	root.add_child(restored_gateway)
	restored.set_online_gateway(restored_gateway)
	_check(int(restored.get_snapshot().get(&"submission_queue", {}).get(&"pending_count", -1)) == 0, "복원 큐 재전송 실패", failures)
	for suffix in ["", "_identity", "_submissions"]:
		var path := persistence_path.replace(".json", "%s.json" % suffix)
		if FileAccess.file_exists(path):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	if failures.is_empty():
		print("P6_RANKING_SUBMISSION_OK identity envelope_digest idempotency local_preserved persistent_retry timeout_retry server_rejection visible_sync_state")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _run_result(run_id: String, value: int, kills: int, elapsed: float, penalty_score: int = 10) -> Dictionary:
	return {
		&"run_id": run_id,
		&"success": true,
		&"condition_key": "small|ruined_city|standard",
		&"penalty_score": penalty_score,
		&"recovered_value": value,
		&"kills": kills,
		&"elapsed_seconds": elapsed,
		&"reward_multiplier": 1.0,
	}


func _payload_digest_for_test(payload: Dictionary) -> String:
	return ("%s|%s|%s|%.3f|%d|%d|%.3f|%d" % [
		payload.get(&"run_id", ""),
		"1" if bool(payload.get(&"success", false)) else "0",
		payload.get(&"condition_key", ""),
		float(payload.get(&"elapsed_seconds", 0.0)),
		int(payload.get(&"kills", 0)),
		int(payload.get(&"recovered_value", 0)),
		float(payload.get(&"reward_multiplier", 1.0)),
		int(payload.get(&"penalty_score", 0)),
	]).sha256_text()


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
