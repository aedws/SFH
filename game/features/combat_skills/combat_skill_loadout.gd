class_name CombatSkillLoadout
extends Resource

@export var skills: Array[Resource] = []


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if skills.is_empty():
		errors.append("전투 스킬을 하나 이상 지정해야 합니다.")
	if skills.size() > 10:
		errors.append("전투 스킬은 최대 10개까지 구성할 수 있습니다.")
	var used_ids := {}
	var used_actions := {}
	for skill in skills:
		if skill == null or not bool(skill.call(&"is_valid")):
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
