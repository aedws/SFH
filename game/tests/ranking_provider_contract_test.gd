extends SceneTree

const RANKING_SCENE := preload("res://game/features/conditional_ranking/conditional_ranking_system.tscn")
const POLICY := preload("res://game/features/conditional_ranking/configs/default_conditional_ranking.tres")
const CONFIG_SCRIPT := preload("res://game/features/conditional_ranking/ranking_provider_config.gd")


class FakeOnlineGateway extends Node:
	var available := true
	var submissions: Array[Dictionary] = []

	func is_available() -> bool:
		return available

	func submit_run(result: Dictionary) -> Dictionary:
		submissions.append(result.duplicate(true))
		return {&"accepted": true, &"online_rank": submissions.size()}

	func get_entries(_condition_key: String, ranking_id: StringName) -> Array[Dictionary]:
		return [{&"ranking_id": ranking_id, &"score": 999.0, &"source": &"online"}]


func _initialize() -> void:
	var failures: Array[String] = []
	var ranking := RANKING_SCENE.instantiate()
	root.add_child(ranking)
	var config := CONFIG_SCRIPT.new()
	config.provider_mode = "local"
	_check(ranking.configure("", POLICY, false, config), "로컬 공급자 구성 실패", failures)

	var first: Dictionary = ranking.submit_run(_run_result(100, 18, 80.0))
	_check(bool(first.get(&"accepted", false)), "로컬 기록 거부", failures)
	_check(first.get(&"provider_status", {}).get(&"state") == &"local", "로컬 상태 비표시", failures)
	_check(ranking.get_entries("small|ruined_city|standard").size() == 1, "로컬 기록 미보존", failures)

	_check(ranking.set_provider_mode("auto"), "auto 공급자 전환 실패", failures)
	var offline: Dictionary = ranking.submit_run(_run_result(200, 25, 70.0))
	var offline_status: Dictionary = offline.get(&"provider_status", {})
	_check(offline_status.get(&"state") == &"offline_fallback", "장애 폴백 상태 누락", failures)
	_check(offline_status.get(&"sync_state") == &"waiting_for_provider", "동기화 대기 표시 누락", failures)
	_check(ranking.get_entries("small|ruined_city|standard").size() == 2, "오프라인 기록 손실", failures)

	var gateway := FakeOnlineGateway.new()
	root.add_child(gateway)
	ranking.set_online_gateway(gateway)
	var online: Dictionary = ranking.submit_run(_run_result(300, 30, 60.0))
	_check(online.get(&"provider_status", {}).get(&"state") == &"synced", "온라인 동기화 상태 누락", failures)
	_check(gateway.submissions.size() == 1, "온라인 어댑터 제출 누락", failures)
	_check(ranking.local_provider.get_entries("small|ruined_city|standard").size() == 3, "온라인 제출 시 로컬 미보존", failures)
	_check(ranking.get_entries("small|ruined_city|standard")[0].get(&"source") == &"online", "온라인 조회 교체 실패", failures)

	gateway.available = false
	var failed_online: Dictionary = ranking.submit_run(_run_result(400, 35, 55.0))
	_check(failed_online.get(&"provider_status", {}).get(&"state") == &"offline_fallback", "네트워크 단절 폴백 실패", failures)
	_check(ranking.local_provider.get_entries("small|ruined_city|standard").size() == 4, "네트워크 단절 기록 손실", failures)
	var snapshot: Dictionary = ranking.get_snapshot()
	_check(snapshot.has(&"local_snapshot") and snapshot.has(&"provider_status"), "공급자 스냅샷 계약 누락", failures)

	if failures.is_empty():
		print("P6_RANKING_PROVIDER_OK local_online_swap offline_fallback local_preserved visible_sync_state")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _run_result(value: int, kills: int, elapsed: float) -> Dictionary:
	return {
		&"success": true,
		&"condition_key": "small|ruined_city|standard",
		&"penalty_score": 10,
		&"recovered_value": value,
		&"kills": kills,
		&"elapsed_seconds": elapsed,
		&"reward_multiplier": 1.0,
	}


func _check(condition: bool, message: String, failures: Array[String]) -> void:
	if not condition:
		failures.append(message)
