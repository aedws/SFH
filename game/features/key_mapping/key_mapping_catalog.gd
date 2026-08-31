class_name KeyMappingCatalog
extends Resource

## 플레이어가 변경할 수 있는 입력 Action과 기획자용 표시 정보를 정의합니다.

@export var action_ids: PackedStringArray = PackedStringArray()
@export var display_names: PackedStringArray = PackedStringArray()
@export var categories: PackedStringArray = PackedStringArray()


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if action_ids.is_empty():
		errors.append("키 설정 Action이 비어 있습니다.")
	if display_names.size() != action_ids.size() or categories.size() != action_ids.size():
		errors.append("키 설정 Action·표시명·분류 수가 서로 다릅니다.")
	var seen := {}
	for action_id in action_ids:
		if action_id.is_empty():
			errors.append("빈 키 설정 Action이 있습니다.")
		elif seen.has(action_id):
			errors.append("중복 키 설정 Action이 있습니다: %s" % action_id)
		seen[action_id] = true
		if not InputMap.has_action(StringName(action_id)):
			errors.append("InputMap에 없는 Action입니다: %s" % action_id)
	return errors


func get_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for index in action_ids.size():
		entries.append({
			&"action_id": StringName(action_ids[index]),
			&"display_name": display_names[index],
			&"category": categories[index],
		})
	return entries
