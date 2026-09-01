class_name SkillBindingProfile
extends Resource

## 전투 스킬이 배치될 수 있는 InputMap Action과 최초 배치를 정의합니다.

@export var allowed_action_ids: PackedStringArray = PackedStringArray()
@export var default_skill_ids: PackedStringArray = PackedStringArray()
@export var default_action_ids: PackedStringArray = PackedStringArray()


func validation_errors(loadout: Resource) -> PackedStringArray:
	var errors := PackedStringArray()
	if loadout == null or not loadout.has_method(&"validation_errors"):
		errors.append("전투 스킬 로드아웃이 필요합니다.")
		return errors
	if allowed_action_ids.is_empty():
		errors.append("스킬 배치 Action이 비어 있습니다.")
	if default_skill_ids.size() != default_action_ids.size():
		errors.append("기본 스킬과 기본 Action 수가 서로 다릅니다.")
	var allowed := {}
	for action_text in allowed_action_ids:
		var action_id := StringName(action_text)
		if action_id.is_empty() or allowed.has(action_id):
			errors.append("비어 있거나 중복된 스킬 Action입니다: %s" % action_text)
		elif not InputMap.has_action(action_id):
			errors.append("InputMap에 없는 스킬 Action입니다: %s" % action_text)
		allowed[action_id] = true
	var loadout_skill_ids := {}
	for skill: Resource in loadout.get("skills"):
		loadout_skill_ids[StringName(skill.get("skill_id"))] = true
	if default_skill_ids.size() != loadout_skill_ids.size():
		errors.append("모든 로드아웃 스킬에는 하나의 기본 배치가 필요합니다.")
	var used_skills := {}
	var used_actions := {}
	for index in default_skill_ids.size():
		var skill_id := StringName(default_skill_ids[index])
		var action_id := StringName(default_action_ids[index])
		if not loadout_skill_ids.has(skill_id):
			errors.append("로드아웃에 없는 기본 스킬입니다: %s" % skill_id)
		if not allowed.has(action_id):
			errors.append("허용 목록에 없는 기본 Action입니다: %s" % action_id)
		if used_skills.has(skill_id) or used_actions.has(action_id):
			errors.append("기본 스킬 배치가 중복됩니다: %s / %s" % [skill_id, action_id])
		used_skills[skill_id] = true
		used_actions[action_id] = true
	for skill_id: StringName in loadout_skill_ids:
		if not used_skills.has(skill_id):
			errors.append("기본 배치가 없는 로드아웃 스킬입니다: %s" % skill_id)
	return errors


func get_defaults() -> Dictionary:
	var result := {}
	for index in default_skill_ids.size():
		result[StringName(default_skill_ids[index])] = StringName(default_action_ids[index])
	return result
