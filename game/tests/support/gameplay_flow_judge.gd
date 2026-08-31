extends RefCounted

## 실제 입력에서 월드 결과까지 이어지는 인과관계를 읽기 전용 스냅샷으로 판정합니다.


func judge(flow_id: StringName, evidence: Dictionary) -> Dictionary:
	var errors := PackedStringArray()
	match flow_id:
		&"primary_attack_resolution":
			_judge_primary_attack(evidence, errors)
		&"room_encounter_resolution":
			_judge_room_encounter(evidence, errors)
		&"ten_minute_session":
			_judge_ten_minute_session(evidence, errors)
		&"fog_room_corridor_transition":
			_judge_fog_transition(evidence, errors)
		_:
			errors.append("알 수 없는 게임플레이 흐름입니다: %s" % flow_id)
	return {
		&"success": errors.is_empty(),
		&"errors": errors,
		&"flow_id": flow_id,
	}


func _judge_primary_attack(evidence: Dictionary, errors: PackedStringArray) -> void:
	_require_increase(evidence, &"projectiles_before", &"projectiles_after", "발사체", errors)
	_require_increase(evidence, &"hits_before", &"hits_after", "타격", errors)
	_require_increase(evidence, &"lethal_before", &"lethal_after", "치명타격", errors)
	_require_increase(evidence, &"kills_before", &"kills_after", "처치", errors)
	_require_increase(evidence, &"drops_before", &"drops_after", "드랍", errors)
	if not bool(evidence.get(&"physical_left_mouse", false)):
		errors.append("물리 좌클릭 입력이 사용되지 않았습니다.")
	if not bool(evidence.get(&"target_removed", false)):
		errors.append("처치된 대상이 월드에서 제거되지 않았습니다.")


func _judge_room_encounter(evidence: Dictionary, errors: PackedStringArray) -> void:
	var active: Dictionary = evidence.get(&"active", {})
	var cleared: Dictionary = evidence.get(&"cleared", {})
	var collected: Dictionary = evidence.get(&"collected", {})
	if int(active.get(&"active_room_index", -1)) < 0:
		errors.append("방 진입이 전투를 활성화하지 못했습니다.")
	if int(active.get(&"active_enemy_count", 0)) <= 0:
		errors.append("방 진입 후 적이 생성되지 않았습니다.")
	if active.get(&"last_trigger_source", &"none") != &"room_entry":
		errors.append("플레이어의 실제 방 진입이 교전을 시작하지 않았습니다.")
	if int(active.get(&"active_enemy_count", 0)) < int(active.get(&"minimum_horde_size", 1)):
		errors.append("방 적 무리가 티어별 핵앤슬래시 최소 스폰량보다 적습니다.")
	if not bool(active.get(&"minimum_horde_met", false)):
		errors.append("방 교전이 최소 무리 보장 정책을 충족하지 못했습니다.")
	if int(active.get(&"locked_door_count", 0)) <= 0:
		errors.append("적 생성 후 문이 봉쇄되지 않았습니다.")
	if int(cleared.get(&"active_room_index", -2)) != -1:
		errors.append("적 섬멸 뒤 방 전투가 종료되지 않았습니다.")
	if int(cleared.get(&"locked_door_count", -1)) != 0:
		errors.append("방 클리어 뒤 문이 열리지 않았습니다.")
	if int(cleared.get(&"rewards_spawned", 0)) <= int(active.get(&"rewards_spawned", 0)):
		errors.append("방 클리어 뒤 보상이 생성되지 않았습니다.")
	if int(collected.get(&"rewards_collected", 0)) <= int(cleared.get(&"rewards_collected", 0)):
		errors.append("플레이어가 방 보상을 회수하지 못했습니다.")
	if float(evidence.get(&"experience_after", 0.0)) <= float(evidence.get(&"experience_before", 0.0)):
		errors.append("방 보상 회수 뒤 내부 경험치가 증가하지 않았습니다.")


func _judge_ten_minute_session(evidence: Dictionary, errors: PackedStringArray) -> void:
	var before: Dictionary = evidence.get(&"before_unlock", {})
	var after: Dictionary = evidence.get(&"after_unlock", {})
	if StringName(after.get(&"tier_id", &"")) not in [&"medium", &"large"]:
		errors.append("10분 세션 판정 대상이 중형 또는 대형이 아닙니다.")
	if not is_equal_approx(float(after.get(&"target_seconds", 0.0)), 600.0):
		errors.append("목표 세션 시간이 10분으로 설정되지 않았습니다.")
	if bool(before.get(&"extraction_unlocked", true)):
		errors.append("10분 도달 전에 탈출이 열렸습니다.")
	if not bool(after.get(&"extraction_unlocked", false)):
		errors.append("10분 도달 뒤 탈출이 열리지 않았습니다.")
	if float(after.get(&"elapsed_seconds", 0.0)) < 600.0:
		errors.append("논리 세션 시간이 10분에 도달하지 않았습니다.")
	if not bool(after.get(&"run_started", false)) or bool(after.get(&"run_ended", true)):
		errors.append("10분 경과 시점에 작전 세션이 유지되지 않습니다.")
	if "10:00" not in String(after.get(&"hud_text", "")):
		errors.append("플레이어 HUD가 10분 경과를 표시하지 않습니다.")


func _judge_fog_transition(evidence: Dictionary, errors: PackedStringArray) -> void:
	var room: Dictionary = evidence.get(&"room", {})
	var leaving: Dictionary = evidence.get(&"leaving", {})
	var corridor: Dictionary = evidence.get(&"corridor", {})
	var entering: Dictionary = evidence.get(&"entering", {})
	var returned: Dictionary = evidence.get(&"returned", {})
	if room.get(&"transition_phase") != &"room" or float(room.get(&"room_visibility_blend", 0.0)) < 0.999:
		errors.append("방 안에서 방 전체 시야가 안정적으로 열리지 않았습니다.")
	if leaving.get(&"transition_phase") != &"leaving_room":
		errors.append("방에서 통로로 나갈 때 부드러운 감쇠 단계가 없습니다.")
	if corridor.get(&"transition_phase") != &"corridor" or float(corridor.get(&"room_visibility_blend", 1.0)) > 0.001:
		errors.append("통로에서 원뿔 시야 모드로 완전히 전환되지 않았습니다.")
	if entering.get(&"transition_phase") != &"entering_room":
		errors.append("통로에서 방으로 들어갈 때 부드러운 개방 단계가 없습니다.")
	if returned.get(&"transition_phase") != &"room":
		errors.append("방 재진입 뒤 방 전체 시야가 복원되지 않았습니다.")
	for snapshot in [room, leaving, corridor, entering, returned]:
		if not bool(snapshot.get(&"non_active_rooms_occluded", false)):
			errors.append("현재 방 밖의 다른 방을 가리는 정책이 유지되지 않습니다.")
			break
		if not bool(snapshot.get(&"minimap_visibility_independent", false)):
			errors.append("전장의 안개가 전체 미니맵 정보까지 숨깁니다.")
			break


func _require_increase(
	evidence: Dictionary,
	before_key: StringName,
	after_key: StringName,
	label: String,
	errors: PackedStringArray
) -> void:
	if float(evidence.get(after_key, 0.0)) <= float(evidence.get(before_key, 0.0)):
		errors.append("%s 수치가 입력 전후 증가하지 않았습니다." % label)
