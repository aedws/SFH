extends SceneTree

const RANKING := preload("res://game/features/conditional_ranking/conditional_ranking_system.gd")
const POLICY := preload("res://game/features/conditional_ranking/conditional_ranking_policy.gd")
const CONFIG := preload("res://game/features/conditional_ranking/ranking_provider_config.gd")
const SEASON := preload("res://game/features/conditional_ranking/season_policy.gd")
const ENVELOPE := preload("res://game/features/conditional_ranking/run_submission_envelope.gd")
const METRICS := preload("res://game/core/run_combat_metrics.gd")
const TEST_PATH := "user://sfh_p6_season_contract.json"
var now := 1000
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred(&"_run")


func _run() -> void:
	_cleanup()
	_verify_boss_defeats()
	_verify_envelopes()
	var ranking := _ranking(true)
	var state: Dictionary = ranking.get_season_briefing(_result("preview"))
	_check(bool(state.get(&"eligible")), "시작 시각에 참가 불가")
	_check("UTC" in String(state.get(&"text", "")) and "10점" in String(state.get(&"text", "")), "종료 시각·조건 안내 누락")
	var context: Dictionary = state[&"context"]
	var first := _result("first", context, 1)
	_check(bool(ranking.submit_run(first).get(&"season", {}).get(&"accepted")), "시즌 제출 실패")
	var duplicate: Dictionary = ranking.submit_run(first)
	_check(bool(duplicate.get(&"season", {}).get(&"duplicate")), "시즌 중복 집계")
	var with_boss := _result("boss", context, 2)
	ranking.submit_run(with_boss)
	ranking.free()
	ranking = _ranking(true)
	_check(ranking.get_season_briefing(first)[&"context"] == context, "저장 JSON 숫자 변환이 출격 시즌 컨텍스트 변경")
	var leaders: Array = ranking.get_entries("ruined_city|standard|small", &"kills")
	_check(leaders[0][&"boss_kills"] == 2, "학살자 보스 동점 우선순위 누락")
	var mismatch := _result("mismatch", context)
	mismatch[&"condition_key"] = "ruined_city|standard|medium"
	var mismatch_result: Dictionary = ranking.submit_run(mismatch)
	_check(bool(mismatch_result.get(&"accepted")) and not bool(mismatch_result.get(&"season", {}).get(&"accepted")), "규모 불일치가 시즌 집계되거나 일반 기록 차단")
	var low := _result("low", context)
	low[&"penalty_score"] = 0
	_check(not bool(ranking.get_season_briefing(low).get(&"eligible")), "최소 페널티 미달 허용")
	var dead := _result("dead", context)
	dead[&"success"] = false
	_check(not bool(ranking.submit_run(dead).get(&"accepted")), "사망 런 집계")
	now = 1059
	_check(bool(ranking.submit_run(_result("last-second", context)).get(&"season", {}).get(&"accepted")), "종료 직전 런 거부")
	ranking.free()
	# Closed while application was offline: restore, close once, create next season.
	now = 1060
	ranking = _ranking(true)
	var archived: Dictionary = ranking.get_season_archive(String(context[&"season_id"]))
	_check(bool(archived.get(&"read_only")), "종료 시각에 읽기 전용 스냅샷 미생성")
	var previous := archived.duplicate(true)
	var crossed: Dictionary = ranking.submit_run(_result("crossed", context))
	_check(bool(crossed.get(&"accepted")) and not bool(crossed.get(&"season", {}).get(&"accepted")), "시즌 경계 런 일반 보존 / 이전 시즌 마감 실패")
	_check(previous == ranking.get_season_archive(String(context[&"season_id"])), "종료 시즌이 늦은 제출로 변함")
	_check("마감 · 수정 불가" in String(ranking.get_season_briefing(first).get(&"history_text", "")), "마감된 기록의 읽기 전용 안내 누락")
	archived.clear()
	_check(not ranking.get_season_archive(String(context[&"season_id"])).is_empty(), "반환 사본 변경이 원본 변조")
	var second_context: Dictionary = ranking.get_season_briefing(_result("preview"))[&"context"]
	_check(context != second_context, "새 시즌 식별자 미변경")
	_check(bool(ranking.submit_run(_result("new-season", second_context)).get(&"season", {}).get(&"accepted")), "신규 시즌 참여 실패")
	now = 1005
	_check(not bool(ranking.get_season_briefing(first).get(&"eligible")), "시계 역행으로 닫힌 시즌 재개")
	now = 1060
	ranking.free()
	ranking = _ranking(true)
	_check(ranking.get_snapshot()[&"season"][&"archives"].size() == 1, "재실행 시 중복 마감 또는 기록 손실")
	_check(ranking.get_snapshot()[&"season"][&"ladder"][&"condition_count"] == 1, "현재 시즌 저장 복원 실패")
	ranking.free()
	var disabled := RANKING.new()
	root.add_child(disabled)
	var config := CONFIG.new()
	config.provider_mode = "local"
	_check(disabled.configure("", POLICY.new(), false, config), "시즌 미설치 구성 실패")
	_check(disabled.get_season_briefing({}).is_empty() and bool(disabled.submit_run(_result("disabled")).get(&"accepted")), "시즌 제거가 일반 랭킹 파괴")
	disabled.free()
	var broad := RANKING.new()
	root.add_child(broad)
	var broad_config := CONFIG.new()
	broad_config.provider_mode = "local"
	var broad_season := SEASON.new()
	broad_season.starts_at = 1000
	broad_season.duration_seconds = 60
	broad_season.minimum_penalty_score = 0
	broad_config.season_policy = broad_season
	_check(broad.configure("", POLICY.new(), false, broad_config, null, func(): return now), "확장 정책 구성 실패")
	var broad_run := _result("broad", broad.get_season_briefing({})[&"context"])
	broad_run[&"penalty_score"] = 0
	var broad_result: Dictionary = broad.submit_run(broad_run)
	_check(not bool(broad_result.get(&"accepted")) and bool(broad_result.get(&"season", {}).get(&"accepted")), "시즌 참가 조건 축소가 일반 랭킹 조건에 강제 결합")
	broad.free()
	# Invalid on-disk shapes fail closed without replacing the user's file.
	var damaged_path := TEST_PATH.replace(".json", "_seasons.json")
	var damaged := FileAccess.open(damaged_path, FileAccess.WRITE)
	damaged.store_string("{\"schema_version\":1,\"active\":{},\"ladder\":[]}")
	damaged.close()
	var original := FileAccess.get_file_as_string(damaged_path)
	var corrupt := _ranking(true)
	_check(not corrupt.get_snapshot()[&"season"][&"storage_error"].is_empty(), "손상 파일 안내 누락")
	_check(FileAccess.get_file_as_string(damaged_path) == original, "손상 원본 무단 덮어쓰기")
	_check(bool(corrupt.submit_run(_result("corrupt-file")).get(&"accepted")), "시즌 파일 손상이 일반 기록 차단")
	corrupt.free()
	var single := SEASON.new()
	single.starts_at = 1000
	single.duration_seconds = 60
	single.recurring = false
	_check(single.season_at(999).is_empty() and not single.season_at(1000).is_empty() and single.season_at(1060).is_empty(), "단발 시즌 시작/종료 경계 실패")
	_cleanup()
	if failures.is_empty():
		print("P6_SEASON_OK boss_identity defeat_once legacy_zero digest_v1_v2 slayer_tiebreak frozen_launch_context eligibility deadline_crossing lifetime_preserved offline_close immutable_archive restart clock_rollback optional_module")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)


func _ranking(persist: bool) -> Node:
	var ranking := RANKING.new()
	root.add_child(ranking)
	var config := CONFIG.new()
	config.provider_mode = "local"
	var season := SEASON.new()
	season.starts_at = 1000
	season.duration_seconds = 60
	season.allowed_map_sizes = PackedStringArray(["small"])
	config.season_policy = season
	_check(ranking.configure(TEST_PATH, POLICY.new(), persist, config, null, func(): return now), "시즌 구성 실패")
	return ranking


func _verify_boss_defeats() -> void:
	var metrics := METRICS.new()
	var host := Node2D.new()
	root.add_child(host)
	var target := Node2D.new()
	host.add_child(target)
	var spawner: Node = load("res://game/features/spawning/enemy_spawner.tscn").instantiate()
	host.add_child(spawner)
	_check(spawner.configure(target, host, false, null, true, false, load("res://game/features/spawning/configs/small.tres"), {}, {&"boss_spawn_guaranteed": true}), "보스 생성 계약 실패")
	spawner.set_process(false)
	var boss: Node = spawner.spawn_enemy_at(Vector2(100, 0), &"room_1")
	var normal: Node = spawner.spawn_enemy_at(Vector2(200, 0), &"room_1")
	_check(boss != null and boss.get_combat_identity()[&"is_boss"], "방 생성 경로에서 보스 확정 누락")
	_check(normal != null and not normal.get_combat_identity()[&"is_boss"], "보스 중복 생성")
	metrics.register_enemy(boss)
	metrics.register_enemy(boss)
	metrics.register_enemy(normal)
	_check(metrics.boss_kills == 0, "스폰만으로 격파 수 증가")
	normal.priority_rank = 5
	normal.take_damage(100000.0)
	boss.take_damage(100000.0)
	boss.defeated.emit(1, Vector2.ZERO)
	_check(metrics.kills == 2 and metrics.boss_kills == 1, "보스 실제 피해·처치·1회 집계 실패 또는 등급을 보스로 오인")
	metrics.reset()
	_check(metrics.get_snapshot()[&"boss_kills"] == 0, "런 초기화 실패")
	host.free()


func _verify_envelopes() -> void:
	var builder := ENVELOPE.new()
	var envelope := builder.build(_result("digest", {}, 1), "player", "build")
	_check(bool(builder.validate(envelope).get(&"valid")), "신규 봉투 검증 실패")
	envelope[&"payload"][&"boss_kills"] = 2
	_check(builder.validate(envelope).get(&"reason_code") == &"payload_tampered", "보스 수 변조 미탐지")
	envelope[&"payload"][&"boss_kills"] = 999
	_check(builder.validate(envelope).get(&"reason_code") == &"invalid_metrics", "전체 처치보다 보스 수가 큼")
	var legacy := builder.build(_result("legacy"), "player", "build")
	legacy[&"schema_version"] = 1
	legacy[&"payload"].erase(&"boss_kills")
	legacy[&"payload"].erase(&"season_context")
	legacy[&"payload_digest"] = builder._payload_digest(legacy[&"payload"], 1)
	_check(bool(builder.validate(legacy).get(&"valid")), "저장된 v1 대기열 검증 호환 실패")
	legacy[&"payload"][&"boss_kills"] = 1
	_check(not bool(builder.validate(legacy).get(&"valid")), "v1에 보스 수 주입 허용")
	var season_envelope := builder.build(_result("season-digest", {&"season_id": "a", &"starts_at": 1000, &"ends_at": 1060, &"policy_id": "p"}), "player", "build")
	season_envelope[&"payload"][&"season_context"][&"ends_at"] = 9999
	_check(builder.validate(season_envelope).get(&"reason_code") == &"payload_tampered", "시즌 종료 시각 변조 미탐지")
	var provider := preload("res://game/features/conditional_ranking/local_ranking_provider.gd").new()
	root.add_child(provider)
	provider.configure("", POLICY.new(), false)
	provider.restore_snapshot({&"entries_by_condition": {"legacy": [{&"kills": 10}]}})
	_check(provider.get_entries("legacy", &"kills")[0][&"boss_kills"] == 0, "구형 로컬 보스 수 기본 0 누락")
	provider.free()


func _result(id: String, context: Dictionary = {}, bosses: int = 0) -> Dictionary:
	return {&"run_id": id, &"success": true, &"condition_key": "ruined_city|standard|small", &"penalty_score": 10, &"recovered_value": 100, &"kills": 10, &"boss_kills": bosses, &"elapsed_seconds": 10.0, &"reward_multiplier": 1.0, &"season_context": context.duplicate(true)}


func _cleanup() -> void:
	for suffix in ["", "_identity", "_submissions", "_seasons"]:
		var path := TEST_PATH.replace(".json", "%s.json" % suffix)
		for candidate in [path, path + ".tmp"]:
			if FileAccess.file_exists(candidate):
				DirAccess.remove_absolute(candidate)


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
