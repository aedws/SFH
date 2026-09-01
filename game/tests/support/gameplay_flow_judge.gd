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
		&"operation_combination_matrix":
			_judge_operation_combination_matrix(evidence, errors)
		&"run_loot_settlement":
			_judge_run_loot_settlement(evidence, errors)
		&"fog_room_corridor_transition":
			_judge_fog_transition(evidence, errors)
		&"loot_table_targeting":
			_judge_loot_table_targeting(evidence, errors)
		&"field_loot_acquisition":
			_judge_field_loot_acquisition(evidence, errors)
		&"field_loot_immediate_equip":
			_judge_field_loot_immediate_equip(evidence, errors)
		&"field_loot_skill_swap":
			_judge_field_loot_skill_swap(evidence, errors)
		&"session_socket_runtime":
			_judge_session_socket_runtime(evidence, errors)
		&"presentation_mobile_settings":
			_judge_presentation_mobile_settings(evidence, errors)
		&"elite_pursuit":
			_judge_elite_pursuit(evidence, errors)
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
	if int(evidence.get(&"credits_after", 0)) <= int(evidence.get(&"credits_before", 0)):
		errors.append("방 보상 박스 회수 뒤 휴대 크레딧이 증가하지 않았습니다.")


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


func _judge_operation_combination_matrix(
	evidence: Dictionary,
	errors: PackedStringArray
) -> void:
	if int(evidence.get(&"tested_combinations", 0)) != 9:
		errors.append("소·중·대형 × 표준·숙련·악몽 9개 조합을 모두 실행하지 않았습니다.")
	if int(evidence.get(&"tier_count", 0)) != 3 or int(evidence.get(&"difficulty_count", 0)) != 3:
		errors.append("맵 규모 또는 난이도 축이 일부 누락됐습니다.")
	if int(evidence.get(&"launch_failures", 1)) != 0:
		errors.append("작전 투입 뒤 전투 대신 거점으로 회귀한 조합이 있습니다.")
	if int(evidence.get(&"returned_to_hub", 0)) != 9:
		errors.append("검증한 모든 조합이 명시적 종료 뒤 거점으로 복귀하지 못했습니다.")
	if not bool(evidence.get(&"used_setup_buttons", false)):
		errors.append("작전 설정 UI의 난이도·맵·투입 버튼을 거치지 않았습니다.")


func _judge_run_loot_settlement(evidence: Dictionary, errors: PackedStringArray) -> void:
	var result: Dictionary = evidence.get(&"result", {})
	var acquired_count := int(evidence.get(&"acquired_count", 0))
	var summary := String(evidence.get(&"summary", ""))
	if acquired_count <= 0 or (result.get(&"outcomes", []) as Array).is_empty():
		errors.append("획득한 전리품이 정산 결과로 이어지지 않았습니다.")
	if not bool(result.get(&"success", false)):
		errors.append("런 전리품 정산 서비스가 성공 결과를 반환하지 않았습니다.")
	if bool(evidence.get(&"expected_extracted", false)):
		if not bool(result.get(&"extracted", false)):
			errors.append("탈출 성공 전리품이 생환 결과로 처리되지 않았습니다.")
		var retained_result_count := (
			int(result.get(&"converted_credits", 0))
			+ int(result.get(&"wallet_credits", 0))
			+ (result.get(&"warehouse_items", {}) as Dictionary).size()
			+ (result.get(&"permanent_unlocks", {}) as Dictionary).size()
		)
		if retained_result_count <= 0:
			errors.append("탈출 성공 전리품 중 환전·보관·해금된 결과가 없습니다.")
		if "전리품" not in summary or "자동 환전" not in summary or "영구 해금" not in summary or "창고 보관" not in summary:
			errors.append("성공 정산 화면이 환전·해금·창고 결과를 분리해 보여주지 않습니다.")
		if not (result.get(&"expired_items", {}) as Dictionary).is_empty() and "런 종료" not in summary:
			errors.append("런 전용·미등록 후보의 종료 결과가 성공 화면에 보이지 않습니다.")
		if not bool(evidence.get(&"duplicate_ignored", false)):
			errors.append("동일 run_id 재정산이 차단되지 않았습니다.")
		if evidence.get(&"profile_after_first", {}) != evidence.get(&"profile_after_duplicate", {}):
			errors.append("중복 정산이 프로필 자산을 다시 변경했습니다.")
	else:
		if bool(result.get(&"extracted", true)):
			errors.append("사망 전리품이 탈출 성공으로 처리됐습니다.")
		if (result.get(&"lost_items", {}) as Dictionary).size() <= 0:
			errors.append("사망한 런의 전리품 소실 목록이 비어 있습니다.")
		if "전리품" not in summary or "사망 소실" not in summary:
			errors.append("실패 정산 화면이 전리품 소실을 명시하지 않습니다.")


func _judge_fog_transition(evidence: Dictionary, errors: PackedStringArray) -> void:
	var room: Dictionary = evidence.get(&"room", {})
	var grace: Dictionary = evidence.get(&"grace", {})
	var leaving: Dictionary = evidence.get(&"leaving", {})
	var corridor: Dictionary = evidence.get(&"corridor", {})
	var entering: Dictionary = evidence.get(&"entering", {})
	var returned: Dictionary = evidence.get(&"returned", {})
	if room.get(&"transition_phase") != &"room" or float(room.get(&"room_visibility_blend", 0.0)) < 0.999:
		errors.append("방 안에서 방 전체 시야가 안정적으로 열리지 않았습니다.")
	if (
		grace.get(&"transition_phase") != &"doorway_grace"
		or float(grace.get(&"room_visibility_blend", 0.0)) < 0.999
		or float(grace.get(&"doorway_grace_remaining", 0.0)) <= 0.0
	):
		errors.append("문턱을 지날 때 방 시야를 잠시 유지하는 완충 단계가 없습니다.")
	if leaving.get(&"transition_phase") != &"leaving_room":
		errors.append("방에서 통로로 나갈 때 부드러운 감쇠 단계가 없습니다.")
	if corridor.get(&"transition_phase") != &"corridor" or float(corridor.get(&"room_visibility_blend", 1.0)) > 0.001:
		errors.append("통로에서 원뿔 시야 모드로 완전히 전환되지 않았습니다.")
	if entering.get(&"transition_phase") != &"entering_room":
		errors.append("통로에서 방으로 들어갈 때 부드러운 개방 단계가 없습니다.")
	if returned.get(&"transition_phase") != &"room":
		errors.append("방 재진입 뒤 방 전체 시야가 복원되지 않았습니다.")
	if (
		float(corridor.get(&"corridor_comfort_shell_radius", 0.0))
		<= float(corridor.get(&"corridor_near_radius", 0.0))
		or float(corridor.get(&"corridor_comfort_shell_visibility", 0.0)) <= 0.0
		or corridor.get(&"corridor_comfort_policy") != &"wide_front_near_shell_doorway_grace"
	):
		errors.append("통로 이동을 위한 근거리 완충 시야가 활성화되지 않았습니다.")
	for snapshot in [room, grace, leaving, corridor, entering, returned]:
		if not bool(snapshot.get(&"non_active_rooms_occluded", false)):
			errors.append("현재 방 밖의 다른 방을 가리는 정책이 유지되지 않습니다.")
			break
		if not bool(snapshot.get(&"minimap_visibility_independent", false)):
			errors.append("전장의 안개가 전체 미니맵 정보까지 숨깁니다.")
			break


func _judge_loot_table_targeting(evidence: Dictionary, errors: PackedStringArray) -> void:
	var briefing: Dictionary = evidence.get(&"briefing", {})
	var first: Dictionary = evidence.get(&"first_roll", {})
	var repeated: Dictionary = evidence.get(&"repeated_roll", {})
	if int(briefing.get(&"candidate_count", 0)) <= 0:
		errors.append("선택한 지역·난이도의 드랍 후보가 없습니다.")
	if (briefing.get(&"target_item_labels", PackedStringArray()) as PackedStringArray).is_empty():
		errors.append("플레이어가 타겟 파밍 품목 이름을 확인할 수 없습니다.")
	if first.is_empty() or first != repeated:
		errors.append("동일 시드의 드랍 결과가 결정적으로 재현되지 않습니다.")
	if first.get(&"region_id") != evidence.get(&"selected_region_id"):
		errors.append("선택 지역과 추첨 결과의 지역이 다릅니다.")


func _judge_field_loot_acquisition(evidence: Dictionary, errors: PackedStringArray) -> void:
	var approached: Dictionary = evidence.get(&"approached", {})
	var cancelled: Dictionary = evidence.get(&"cancelled", {})
	var acquired: Dictionary = evidence.get(&"acquired", {})
	var approached_panel: Dictionary = approached.get(&"panel", {})
	if (
		int(approached.get(&"active_drop_count", 0)) <= 0
		or StringName(approached.get(&"focused_item_id", &"")) == &""
		or not bool(approached_panel.get(&"visible", false))
		or not bool(approached_panel.get(&"shows_extract_result", false))
		or not bool(approached_panel.get(&"shows_cancel_and_select", false))
	):
		errors.append("전리품 접근 시 비교·생명 주기·선택 단서가 보이지 않습니다.")
	if (
		int(cancelled.get(&"active_drop_count", 0)) != int(approached.get(&"active_drop_count", 0))
		or int(cancelled.get(&"total_cancelled", 0)) <= int(approached.get(&"total_cancelled", 0))
		or bool((cancelled.get(&"panel", {}) as Dictionary).get(&"visible", true))
	):
		errors.append("ESC 보류가 월드 전리품은 유지하고 비교 패널만 닫지 못했습니다.")
	if (
		int(acquired.get(&"active_drop_count", -1)) >= int(cancelled.get(&"active_drop_count", 0))
		or int(acquired.get(&"total_acquired", 0)) <= int(cancelled.get(&"total_acquired", 0))
		or (acquired.get(&"acquired_items", {}) as Dictionary).is_empty()
	):
		errors.append("재접근 뒤 F 획득이 월드 전리품을 런 임시 보관으로 옮기지 못했습니다.")
	if not bool(acquired.get(&"separate_from_equipment_mutation", false)):
		errors.append("P4-03 획득 계약이 P4-04 장비 교체를 몰래 수행합니다.")


func _judge_field_loot_immediate_equip(evidence: Dictionary, errors: PackedStringArray) -> void:
	var before: Dictionary = evidence.get(&"before", {})
	var after: Dictionary = evidence.get(&"after", {})
	var panel: Dictionary = before.get(&"panel", {})
	var immediate: Dictionary = after.get(&"immediate_equip", {})
	if not bool(panel.get(&"shows_immediate_equip", false)):
		errors.append("현장 무기 후보에 R 즉시 장착 선택지가 보이지 않습니다.")
	if evidence.get(&"before_weapon", &"") == evidence.get(&"after_weapon", &""):
		errors.append("R 입력 뒤 실제 활성 무기가 바뀌지 않았습니다: %s → %s / %s" % [
			evidence.get(&"before_weapon", &""), evidence.get(&"after_weapon", &""), after,
		])
	if evidence.get(&"after_weapon", &"") != &"pulse_rifle":
		errors.append("R 입력 결과가 선택한 전격 펄스 소총이 아닙니다.")
	if int(immediate.get(&"pending_swap_count", 0)) != 1:
		errors.append("기존 무기가 런 임시 보관 복구 기록에 남지 않았습니다.")
	if (immediate.get(&"policy", {}) as Dictionary).get(&"policy_status", &"") != &"provisional":
		errors.append("미확정 기존 장비 처리 정책이 임시 상태로 표시되지 않습니다.")


func _judge_field_loot_skill_swap(evidence: Dictionary, errors: PackedStringArray) -> void:
	var before: Dictionary = evidence.get(&"before", {})
	var after: Dictionary = evidence.get(&"after", {})
	var panel: Dictionary = before.get(&"panel", {})
	var immediate: Dictionary = after.get(&"immediate_skill_equip", {})
	if not bool(panel.get(&"shows_skill_swap", false)):
		errors.append("현장 스킬 후보에 R 스킬 교체 선택지가 보이지 않습니다.")
	if evidence.get(&"before_skill", &"") == evidence.get(&"after_skill", &""):
		errors.append("R 입력 뒤 슬롯 3 스킬이 바뀌지 않았습니다.")
	if evidence.get(&"after_skill", &"") != &"arc_dash":
		errors.append("R 입력 결과가 선택한 아크 질주가 아닙니다.")
	if evidence.get(&"after_action", &"") != &"combat_skill_3":
		errors.append("스킬 교체 후 기존 3번 키 바인딩이 유지되지 않았습니다.")
	if int(immediate.get(&"pending_swap_count", 0)) != 1:
		errors.append("기존 스킬·쿨다운·충전 상태가 런 복구 기록에 남지 않았습니다.")
	if bool(immediate.get(&"bindings_persisted", true)):
		errors.append("런 전용 키 바인딩이 영구 저장되는 것으로 표시됩니다.")


func _judge_session_socket_runtime(evidence: Dictionary, errors: PackedStringArray) -> void:
	var before: Dictionary = evidence.get(&"before", {})
	var after: Dictionary = evidence.get(&"after", {})
	var panel: Dictionary = before.get(&"panel", {})
	var socket_state: Dictionary = after.get(&"session_sockets", {})
	var hud: Dictionary = evidence.get(&"hud", {})
	if not bool(panel.get(&"shows_session_socket", false)):
		errors.append("세션 자산에 F 런 소켓 장착 선택지가 보이지 않습니다.")
	if StringName(after.get(&"last_socket_result", {}).get(&"item_id", &"")) != &"arc_rune":
		errors.append("F 입력 결과가 접근한 전도 룬 소켓 장착이 아닙니다.")
	if int(socket_state.get(&"installed_count", 0)) != 1:
		errors.append("전도 룬 획득 뒤 런 소켓 점유가 HUD 상태에 반영되지 않았습니다.")
	if not bool(socket_state.get(&"runtime_only", false)):
		errors.append("세션 소켓이 작전 한정 상태로 표시되지 않습니다.")
	if int(hud.get(&"occupied_count", 0)) != 1 or not bool(hud.get(&"runtime_only_visible", false)):
		errors.append("세션 소켓 HUD가 점유 슬롯과 RUN ONLY 의미를 함께 보여주지 않습니다.")
	if float(evidence.get(&"damage_after", 0.0)) <= float(evidence.get(&"damage_before", 0.0)):
		errors.append("전도 룬 장착 뒤 실제 무기 피해가 증가하지 않았습니다.")
	if not bool(evidence.get(&"unsocket_success", false)):
		errors.append("HUD 슬롯 선택으로 세션 자산을 해제하지 못했습니다.")
	if not is_equal_approx(
		float(evidence.get(&"damage_restored", -1.0)),
		float(evidence.get(&"damage_before", 0.0))
	):
		errors.append("세션 자산 해제 뒤 임시 무기 효과가 원복되지 않았습니다.")


func _judge_presentation_mobile_settings(
	evidence: Dictionary,
	errors: PackedStringArray
) -> void:
	var before: Dictionary = evidence.get(&"before", {})
	var changed: Dictionary = evidence.get(&"changed", {})
	var presenter_changed: Dictionary = evidence.get(&"presenter_changed", {})
	var restored: Dictionary = evidence.get(&"restored", {})
	var presenter_restored: Dictionary = evidence.get(&"presenter_restored", {})
	if before.get(&"hud_anchor") != &"bottom_left":
		errors.append("플레이어 상태 HUD 기본 위치가 좌하단이 아닙니다.")
	if (
		changed.get(&"hud_anchor") != &"bottom_center"
		or changed.get(&"key_label_format") != &"boxed"
		or changed.get(&"mobile_controls_mode") != &"on"
	):
		errors.append("K 설정 변경이 HUD 위치·키 형식·모바일 표시 상태를 함께 바꾸지 못했습니다.")
	if (
		presenter_changed.get(&"hud_anchor") != &"bottom_center"
		or presenter_changed.get(&"key_label_format") != &"boxed"
	):
		errors.append("표시 설정이 실제 전투 HUD 배치와 키 배지에 반영되지 않았습니다.")
	if not bool(evidence.get(&"mobile_visible_after_modal", false)):
		errors.append("설정 화면을 닫은 뒤 모바일 키패드가 표시되지 않았습니다.")
	if float(evidence.get(&"mobile_world_delta", 0.0)) < 1.0:
		errors.append("모바일 방향 입력이 실제 플레이어 이동으로 이어지지 않았습니다.")
	if (
		restored.get(&"hud_anchor") != &"bottom_left"
		or restored.get(&"key_label_format") != &"compact"
		or restored.get(&"mobile_controls_mode") != &"auto"
		or presenter_restored.get(&"hud_anchor") != &"bottom_left"
	):
		errors.append("표시 설정 기본값 복원이 HUD까지 일관되게 반영되지 않았습니다.")
	if not bool(evidence.get(&"mobile_hidden_after_restore", false)):
		errors.append("비터치 환경의 자동 모드에서 모바일 키패드가 숨겨지지 않았습니다.")


func _judge_elite_pursuit(evidence: Dictionary, errors: PackedStringArray) -> void:
	var before: Dictionary = evidence.get(&"before", {})
	var after: Dictionary = evidence.get(&"after", {})
	var active_room_before: Dictionary = evidence.get(&"active_room_before", {})
	var active_room_after: Dictionary = evidence.get(&"active_room_after_spawn", {})
	var spawner_before: Dictionary = evidence.get(&"spawner_before", {})
	var spawner_after: Dictionary = evidence.get(&"spawner_after", {})
	var cleared: Dictionary = evidence.get(&"cleared", {})
	if bool(before.get(&"triggered", false)) or not bool(after.get(&"triggered", false)):
		errors.append("투입액 회수 임계 전후 엘리트 발생 상태가 바뀌지 않았습니다.")
	if int(after.get(&"threshold_credits", -1)) != int(after.get(&"deployment_cost", -2)):
		errors.append("엘리트 발생 임계값이 실제 투입 비용과 같지 않습니다.")
	if int(after.get(&"spawned_elite_count", 0)) < 1 or int(after.get(&"spawned_elite_count", 0)) > 2:
		errors.append("엘리트 랜덤 생성 수가 임시 정책 1~2마리를 벗어났습니다.")
	if (
		float(after.get(&"player_speed_multiplier", 1.0)) <= 1.0
		or float(after.get(&"player_attack_multiplier", 1.0)) <= 1.0
	):
		errors.append("엘리트가 플레이어보다 약간 빠르고 강한 수치 계약을 충족하지 않습니다.")
	if (
		not bool(after.get(&"room_independent", false))
		or not bool(after.get(&"door_state_independent", false))
		or not bool(after.get(&"infinite_pursuit", false))
	):
		errors.append("엘리트의 방·문 독립 무한 추적 계약이 비활성화됐습니다.")
	if (
		int(active_room_after.get(&"active_enemy_count", -1))
		!= int(active_room_before.get(&"active_enemy_count", -2))
		or int(active_room_after.get(&"locked_door_count", -1))
		!= int(active_room_before.get(&"locked_door_count", -2))
	):
		errors.append("엘리트 생성이 방 전투 적 수 또는 문 봉쇄 상태를 변경했습니다.")
	if int(spawner_after.get(&"total_spawned", -1)) != int(spawner_before.get(&"total_spawned", -2)):
		errors.append("엘리트가 일반 적 스폰 예산을 소비했습니다.")
	if not bool(evidence.get(&"elite_visible_to_targeting", false)):
		errors.append("엘리트가 스마트 자동 타게팅 대상 목록에 포함되지 않았습니다.")
	if float(evidence.get(&"distance_after", INF)) >= float(evidence.get(&"distance_before", 0.0)):
		errors.append("엘리트가 플레이어를 향해 실제로 추격하지 않았습니다.")
	if not bool(evidence.get(&"elite_alive_after_room_clear", false)):
		errors.append("방 클리어가 방 독립 엘리트까지 제거했습니다.")
	if int(cleared.get(&"locked_door_count", -1)) != 0:
		errors.append("엘리트가 남아 있어 방 클리어 후 문이 열리지 않았습니다.")


func _require_increase(
	evidence: Dictionary,
	before_key: StringName,
	after_key: StringName,
	label: String,
	errors: PackedStringArray
) -> void:
	if float(evidence.get(after_key, 0.0)) <= float(evidence.get(before_key, 0.0)):
		errors.append("%s 수치가 입력 전후 증가하지 않았습니다." % label)
