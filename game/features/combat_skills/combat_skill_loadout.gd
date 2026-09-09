class_name CombatSkillLoadout
extends Resource

@export_range(1, 9, 1) var slot_capacity: int = 9
@export var skills: Array[Resource] = []


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if skills.is_empty():
		errors.append("전투 스킬을 하나 이상 지정해야 합니다.")
	if skills.size() > slot_capacity:
		errors.append("전투 스킬은 슬롯 용량 %d개를 초과할 수 없습니다." % slot_capacity)
	var used_ids := {}
	var used_actions := {}
	for skill in skills:
		if skill == null or not skill.has_method(&"is_valid") or not bool(skill.call(&"is_valid")):
			errors.append("유효하지 않은 전투 스킬 정의가 있습니다.")
			continue
		var skill_id: StringName = skill.get("skill_id")
		var input_action: StringName = skill.get("input_action")
		if used_ids.has(skill_id):
			errors.append("중복된 전투 스킬 ID입니다: %s" % skill_id)
		if used_actions.has(input_action):
			errors.append("중복된 전투 스킬 입력입니다: %s" % input_action)
		used_ids[skill_id] = true
		used_actions[input_action] = true
	return errors
