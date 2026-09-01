extends RefCounted

## 기능 노드의 존재가 아니라 플레이어가 화면에서 방향·선택·행동 결과·결말을
## 이해할 수 있는지 판정합니다. 게임 규칙을 호출하거나 상태를 변경하지 않습니다.

const CHECKPOINT_RULES := {
	&"hub_orientation": {
		&"unit": &"orientation",
		&"surfaces": [&"hub"],
		&"phrases": ["전초기지", "작전 게이트", "이동", "가방", "장비", "모듈", "무기", "키 설정"],
	},
	&"key_mapping_comprehension": {
		&"unit": &"choice",
		&"surfaces": [&"key_mapping"],
		&"phrases": ["입력 설정", "키 배치", "스킬 배치", "ESC", "전체 기본값 복원"],
	},
	&"inventory_comprehension": {
		&"unit": &"choice",
		&"surfaces": [&"inventory"],
		&"phrases": ["가방 인벤토리", "아이템", "공간 사용", "장비 관리"],
	},
	&"equipment_comprehension": {
		&"unit": &"choice",
		&"surfaces": [&"equipment"],
		&"phrases": ["캐릭터 장비 관리", "장착 장비", "장비 인벤토리", "장비 태그 호환"],
	},
	&"modification_comprehension": {
		&"unit": &"choice",
		&"surfaces": [&"equipment"],
		&"phrases": ["모듈", "파츠", "코스트", "적용 수치", "추천"],
	},
	&"operation_decision": {
		&"unit": &"decision",
		&"surfaces": [&"run_setup"],
		&"phrases": ["작전 브리핑", "작전 정보", "예상 회수", "위험", "소모품", "작전 투입"],
	},
	&"target_farming_decision": {
		&"unit": &"decision",
		&"surfaces": [&"run_setup"],
		&"phrases": ["TARGET LOOT", "최고 G", "후보"],
	},
	&"field_loot_comparison": {
		&"unit": &"decision",
		&"surfaces": [&"field_loot"],
		&"phrases": ["FIELD ACQUISITION", "비교", "탈출 시", "사망 시", "F 획득", "ESC 보류"],
	},
	&"field_loot_immediate_equip": {
		&"unit": &"decision",
		&"surfaces": [&"field_loot"],
		&"phrases": ["R 무기 장착", "F 런 보관", "ESC 보류", "임시 정책", "기존 장비"],
	},
	&"field_loot_skill_swap": {
		&"unit": &"decision",
		&"surfaces": [&"field_loot"],
		&"phrases": ["R 스킬 교체", "슬롯", "키", "ENERGY", "CD", "충전", "F 런 보관"],
	},
	&"combat_glance": {
		&"unit": &"glance",
		&"surfaces": [&"combat", &"combat_skills", &"dash", &"minimap"],
		&"phrases": ["MISSION", "HP", "XP", "ENERGY", "DASH", "READY", "YOU", "EXIT"],
	},
	&"combat_context_restored": {
		&"unit": &"continuity",
		&"surfaces": [&"combat", &"combat_skills", &"dash", &"minimap"],
		&"phrases": ["MISSION", "HP", "ENERGY", "DASH"],
	},
	&"run_buff_choice_comprehension": {
		&"unit": &"choice",
		&"surfaces": [&"run_buff_selector"],
		&"phrases": ["내부 증강 선택", "작전 한정", "STACK", "즉시 적용", "이 증강 선택"],
	},
	&"hub_context_restored": {
		&"unit": &"continuity",
		&"surfaces": [&"hub"],
		&"phrases": ["전초기지", "작전 게이트", "현재"],
	},
	&"weapon_switch_feedback": {
		&"unit": &"action_feedback",
		&"surfaces": [&"hub"],
		&"phrases": ["현재"],
	},
	&"skill_activation_feedback": {
		&"unit": &"action_feedback",
		&"surfaces": [&"combat", &"combat_skills"],
		&"phrases": ["점멸", "재사용", "ENERGY"],
	},
	&"dash_activation_feedback": {
		&"unit": &"action_feedback",
		&"surfaces": [&"dash"],
		&"phrases": ["DASH"],
	},
	&"primary_attack_feedback": {
		&"unit": &"action_feedback",
		&"surfaces": [&"combat"],
		&"phrases": ["HP", "처치"],
	},
	&"room_lock_feedback": {
		&"unit": &"state_feedback",
		&"surfaces": [&"combat"],
		&"phrases": ["봉쇄", "섬멸"],
	},
	&"room_clear_feedback": {
		&"unit": &"state_feedback",
		&"surfaces": [&"combat"],
		&"phrases": ["확보", "보상"],
	},
	&"loot_feedback": {
		&"unit": &"resource_feedback",
		&"surfaces": [&"combat"],
		&"phrases": ["CR"],
	},
	&"extraction_start_feedback": {
		&"unit": &"state_feedback",
		&"surfaces": [&"combat"],
		&"phrases": ["탈출 방어전 시작", "지키세요"],
	},
	&"extraction_pause_feedback": {
		&"unit": &"state_feedback",
		&"surfaces": [&"combat"],
		&"phrases": ["탈출 방어 일시정지", "재개"],
	},
	&"extraction_resume_feedback": {
		&"unit": &"state_feedback",
		&"surfaces": [&"combat"],
		&"phrases": ["탈출 방어 재개", "잔여"],
	},
	&"success_consequence": {
		&"unit": &"consequence",
		&"surfaces": [&"result"],
		&"phrases": ["탈출 성공", "생존", "처치", "정산", "시작 거점으로 복귀"],
	},
	&"failure_consequence": {
		&"unit": &"consequence",
		&"surfaces": [&"result"],
		&"phrases": ["작전 실패", "생존", "처치", "분실", "시작 거점으로 복귀"],
	},
}


func judge(game: Node, checkpoint_id: StringName, evidence: Dictionary = {}) -> Dictionary:
	var errors := PackedStringArray()
	if not CHECKPOINT_RULES.has(checkpoint_id):
		errors.append("알 수 없는 플레이어 인식 체크포인트입니다: %s" % checkpoint_id)
		return {&"success": false, &"errors": errors, &"checkpoint_id": checkpoint_id}
	var rule: Dictionary = CHECKPOINT_RULES[checkpoint_id]
	var visible_text := PackedStringArray()
	for surface_id: StringName in rule[&"surfaces"]:
		var surface := _resolve_surface(game, surface_id)
		if surface == null or not surface.is_visible_in_tree():
			errors.append("플레이어가 확인해야 할 화면이 보이지 않습니다: %s" % surface_id)
			continue
		_collect_visible_text(surface, visible_text)
	var combined_text := "\n".join(visible_text)
	for phrase: String in rule[&"phrases"]:
		if phrase not in combined_text:
			errors.append("화면에서 의미 단서를 찾을 수 없습니다: %s" % phrase)
	if "�" in combined_text or "NaN" in combined_text or "<null>" in combined_text:
		errors.append("깨진 문자 또는 유효하지 않은 값이 표시됩니다.")
	if combined_text.strip_edges().length() < 12:
		errors.append("플레이어가 상태를 이해하기에 표시 정보가 너무 적습니다.")
	_validate_evidence(evidence, errors)
	return {
		&"success": errors.is_empty(),
		&"errors": errors,
		&"checkpoint_id": checkpoint_id,
		&"perception_unit": rule[&"unit"],
		&"visible_text_count": visible_text.size(),
		&"visible_character_count": combined_text.length(),
	}


func checkpoint_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for checkpoint_id: StringName in CHECKPOINT_RULES:
		result.append(checkpoint_id)
	return result


func _validate_evidence(evidence: Dictionary, errors: PackedStringArray) -> void:
	if evidence.has(&"before_text") and evidence.has(&"after_text"):
		var before_text := String(evidence[&"before_text"])
		var after_text := String(evidence[&"after_text"])
		if before_text == after_text:
			errors.append("입력 전후의 보이는 문구가 바뀌지 않았습니다.")
		for phrase: String in evidence.get(&"after_phrases", []):
			if phrase not in after_text:
				errors.append("행동 결과 문구에 필요한 의미가 없습니다: %s" % phrase)
	if evidence.has(&"before_value") and evidence.has(&"after_value"):
		var before_value := float(evidence[&"before_value"])
		var after_value := float(evidence[&"after_value"])
		var direction := StringName(evidence.get(&"value_direction", &"changed"))
		if direction == &"increase" and after_value <= before_value:
			errors.append("행동 뒤 값이 증가하지 않았습니다: %.2f → %.2f" % [before_value, after_value])
		elif direction == &"decrease" and after_value >= before_value:
			errors.append("행동 뒤 값이 감소하지 않았습니다: %.2f → %.2f" % [before_value, after_value])
		elif direction == &"changed" and is_equal_approx(before_value, after_value):
			errors.append("행동 전후 값이 변하지 않았습니다: %.2f" % before_value)
	if evidence.has(&"minimum_world_delta"):
		var world_delta := float(evidence.get(&"world_delta", 0.0))
		if world_delta < float(evidence[&"minimum_world_delta"]):
			errors.append("행동 결과 이동량이 인지 하한보다 작습니다: %.1fpx" % world_delta)
	if evidence.has(&"minimum_visual_intensity"):
		var visual_intensity := float(evidence.get(&"visual_intensity", 0.0))
		if visual_intensity < float(evidence[&"minimum_visual_intensity"]):
			errors.append("이동 표현 강도가 인지 하한보다 작습니다: %.2f" % visual_intensity)
	if evidence.has(&"minimum_trail_points"):
		var trail_point_count := int(evidence.get(&"trail_point_count", 0))
		if trail_point_count < int(evidence[&"minimum_trail_points"]):
			errors.append("대시 궤적 표본이 부족합니다: %d개" % trail_point_count)
	if evidence.has(&"minimum_camera_lead_pixels"):
		var camera_lead_pixels := float(evidence.get(&"camera_lead_pixels", 0.0))
		if camera_lead_pixels < float(evidence[&"minimum_camera_lead_pixels"]):
			errors.append("카메라 방향 리드가 인지 하한보다 작습니다: %.1fpx" % camera_lead_pixels)
	if evidence.has(&"expected_context"):
		if StringName(evidence.get(&"actual_context", &"")) != StringName(evidence[&"expected_context"]):
			errors.append("행동 후 원래 플레이 맥락이 복원되지 않았습니다.")


func _resolve_surface(game: Node, surface_id: StringName) -> Control:
	match surface_id:
		&"hub":
			return game.get_node_or_null("UI/StartHubHUD") as Control
		&"key_mapping":
			return game.get("key_mapping_panel") as Control
		&"inventory":
			return game.get("inventory_window") as Control
		&"equipment":
			return game.get("equipment_workbench") as Control
		&"run_setup":
			return game.get_node_or_null("UI/RunSetupOverlay") as Control
		&"combat":
			return game.get_node_or_null("UI/HUDMargin") as Control
		&"combat_skills":
			return game.get("combat_skill_hud") as Control
		&"dash":
			return game.get("dash_cooldown_hud") as Control
		&"minimap":
			return game.get("minimap") as Control
		&"result":
			return game.get_node_or_null("UI/GameOverOverlay") as Control
		&"run_buff_selector":
			return game.get("run_buff_selector") as Control
		&"field_loot":
			var service = game.get("field_loot_acquisition_service")
			return service.call(&"get_panel") as Control if service != null else null
	return null


func _collect_visible_text(node: Node, output: PackedStringArray) -> void:
	if node is CanvasItem and not (node as CanvasItem).is_visible_in_tree():
		return
	if node is Control:
		var semantic_text := (node as Control).tooltip_text.strip_edges()
		if not semantic_text.is_empty():
			output.append(semantic_text)
	if node is Label:
		var label_text := (node as Label).text.strip_edges()
		if not label_text.is_empty():
			output.append(label_text)
	elif node is Button:
		var button_text := (node as Button).text.strip_edges()
		if not button_text.is_empty():
			output.append(button_text)
	for child in node.get_children():
		_collect_visible_text(child, output)
