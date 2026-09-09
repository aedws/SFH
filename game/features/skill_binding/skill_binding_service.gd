class_name SkillBindingService
extends Node

signal bindings_changed(snapshot: Dictionary)
signal binding_rejected(message: String)

## 스킬→Action 배치와 충돌 교환·JSON 영속화를 물리 키 설정과 분리합니다.

var loadout: Resource
var profile: Resource
var physical_binding_provider: Node
var storage_path: String = "user://sfh_skill_bindings.json"
var skill_to_action: Dictionary = {}
var action_to_skill: Dictionary = {}
var configured: bool = false
var runtime_replacement_count: int = 0
## Runtime identities inherit a permanent slot owner; temporary skill IDs are
## never written to the user's bindings file, even when edited from K.
var runtime_origins: Dictionary = {}
var runtime_definitions: Dictionary = {}


func configure(
	new_loadout: Resource,
	new_profile: Resource,
	new_storage_path: String,
	new_physical_binding_provider: Node = null,
	load_saved: bool = true
) -> bool:
	if (
		new_loadout == null
		or new_profile == null
		or new_storage_path.is_empty()
		or not new_profile.has_method(&"validation_errors")
		or not new_profile.call(&"validation_errors", new_loadout).is_empty()
	):
		return false
	loadout = new_loadout
	profile = new_profile
	storage_path = new_storage_path
	physical_binding_provider = new_physical_binding_provider
	if (
		is_instance_valid(physical_binding_provider)
		and physical_binding_provider.has_signal(&"bindings_changed")
		and not physical_binding_provider.is_connected(
			&"bindings_changed", Callable(self, &"_on_physical_bindings_changed")
		)
	):
		physical_binding_provider.connect(
			&"bindings_changed", Callable(self, &"_on_physical_bindings_changed")
		)
	runtime_origins.clear()
	runtime_definitions.clear()
	_apply_defaults()
	configured = true
	runtime_replacement_count = 0
	if load_saved and FileAccess.file_exists(storage_path):
		_load_saved_bindings()
	bindings_changed.emit(get_snapshot())
	return true


func assign_skill(skill_id: StringName, action_id: StringName) -> Dictionary:
	if not configured or not skill_to_action.has(skill_id) or not _is_allowed_action(action_id):
		return _reject("배치할 수 없는 스킬 또는 슬롯입니다.")
	var previous_skills := skill_to_action.duplicate()
	var previous_actions := action_to_skill.duplicate()
	var source_action: StringName = skill_to_action.get(skill_id, &"")
	if source_action == action_id:
		return {&"success": true, &"message": "이미 해당 슬롯에 배치되어 있습니다."}
	var displaced_skill: StringName = action_to_skill.get(action_id, &"")
	if not source_action.is_empty():
		action_to_skill.erase(source_action)
	if not displaced_skill.is_empty():
		skill_to_action[displaced_skill] = source_action
		if not source_action.is_empty():
			action_to_skill[source_action] = displaced_skill
	skill_to_action[skill_id] = action_id
	action_to_skill[action_id] = skill_id
	if not _save_bindings():
		skill_to_action = previous_skills
		action_to_skill = previous_actions
		return _reject("스킬 배치 저장에 실패해 변경 전 배치로 복구했습니다.")
	var snapshot := get_snapshot()
	bindings_changed.emit(snapshot)
	return {
		&"success": true,
		&"message": "%s을(를) %s 슬롯에 배치했습니다.%s" % [
			_display_name(skill_id), _action_slot_label(action_id),
			" 기존 스킬은 서로 교환했습니다." if not displaced_skill.is_empty() else "",
		],
		&"swapped_skill_id": displaced_skill,
		&"snapshot": snapshot,
	}


func reset_defaults(save_after_reset: bool = true) -> bool:
	if not configured:
		return false
	var previous_skills := skill_to_action.duplicate()
	var previous_actions := action_to_skill.duplicate()
	if runtime_replacement_count == 0:
		_apply_defaults()
	else:
		action_to_skill.clear()
		var defaults: Dictionary = profile.call(&"get_defaults")
		for skill_id: StringName in skill_to_action:
			var action: StringName = defaults.get(runtime_origins.get(skill_id, skill_id), &"")
			skill_to_action[skill_id] = action
			action_to_skill[action] = skill_id
	var saved := not save_after_reset or _save_bindings()
	if not saved:
		skill_to_action = previous_skills
		action_to_skill = previous_actions
	bindings_changed.emit(get_snapshot())
	return saved


func replace_runtime_skill(
	previous_skill_id: StringName,
	new_skill_id: StringName,
	action_id: StringName,
	definition: Resource = null
) -> bool:
	if (
		not configured
		or previous_skill_id.is_empty()
		or new_skill_id.is_empty()
		or not _is_allowed_action(action_id)
		or StringName(skill_to_action.get(previous_skill_id, &"")) != action_id
		or (new_skill_id != previous_skill_id and skill_to_action.has(new_skill_id))
		or (definition != null and StringName(definition.get("skill_id")) != new_skill_id)
	):
		return false
	runtime_origins[new_skill_id] = runtime_origins.get(previous_skill_id, previous_skill_id)
	if definition != null:
		runtime_definitions[new_skill_id] = definition
	skill_to_action.erase(previous_skill_id)
	var prior_action: StringName = skill_to_action.get(new_skill_id, &"")
	if not prior_action.is_empty():
		action_to_skill.erase(prior_action)
	var displaced: StringName = action_to_skill.get(action_id, &"")
	if not displaced.is_empty() and displaced != previous_skill_id:
		skill_to_action.erase(displaced)
	skill_to_action[new_skill_id] = action_id
	action_to_skill[action_id] = new_skill_id
	runtime_replacement_count += 1
	bindings_changed.emit(get_snapshot())
	return true


func restore_runtime_skill(
	current_skill_id: StringName,
	previous_skill_id: StringName,
	action_id: StringName
) -> bool:
	if (
		not configured
		or not skill_to_action.has(current_skill_id)
		or (previous_skill_id != current_skill_id and skill_to_action.has(previous_skill_id))
		or (not _has_skill(previous_skill_id) and not runtime_origins.has(previous_skill_id))
		or not _is_allowed_action(action_id)
	):
		return false
	# A player may have remapped this slot since the swap. Restore identity, not
	# the stale historical action, or another skill can silently lose its key.
	action_id = skill_to_action[current_skill_id]
	skill_to_action.erase(current_skill_id)
	action_to_skill.erase(action_id)
	skill_to_action[previous_skill_id] = action_id
	action_to_skill[action_id] = previous_skill_id
	runtime_replacement_count = maxi(0, runtime_replacement_count - 1)
	if runtime_replacement_count == 0:
		runtime_origins.clear()
		runtime_definitions.clear()
	bindings_changed.emit(get_snapshot())
	return true


func action_for_skill(skill_id: StringName) -> StringName:
	return skill_to_action.get(skill_id, &"")


func skill_for_action(action_id: StringName) -> StringName:
	return action_to_skill.get(action_id, &"")


func input_label_for_skill(skill_id: StringName) -> String:
	var action_id := action_for_skill(skill_id)
	return _binding_text(action_id) if not action_id.is_empty() else "미배치"


func get_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	if not configured:
		return entries
	for skill_id: StringName in skill_to_action:
		var action_id := action_for_skill(skill_id)
		var skill: Resource = runtime_definitions.get(skill_id)
		if skill == null:
			for base: Resource in loadout.get("skills"):
				if StringName(base.get("skill_id")) == skill_id:
					skill = base
					break
		entries.append({
			&"skill_id": skill_id,
			&"display_name": String(skill.get("display_name")) if skill != null else String(skill_id),
			&"action_id": action_id,
			&"action_slot_label": _action_slot_label(action_id),
			&"binding_text": input_label_for_skill(skill_id),
		})
	return entries


func get_allowed_actions() -> Array[StringName]:
	var result: Array[StringName] = []
	if profile == null:
		return result
	for action_text in profile.get("allowed_action_ids"):
		result.append(StringName(action_text))
	return result


func get_snapshot() -> Dictionary:
	return {
		&"configured": configured,
		&"storage_path": storage_path,
		&"skill_binding_count": skill_to_action.size(),
		&"allowed_action_count": get_allowed_actions().size(),
		&"entries": get_entries(),
		&"runtime_replacement_count": runtime_replacement_count,
		&"runtime_replacements_persisted": false,
	}


func _apply_defaults() -> void:
	skill_to_action.clear()
	action_to_skill.clear()
	if profile == null:
		return
	var defaults: Dictionary = profile.call(&"get_defaults")
	for skill_id: StringName in defaults:
		var action_id: StringName = defaults[skill_id]
		skill_to_action[skill_id] = action_id
		action_to_skill[action_id] = skill_id


func _load_saved_bindings() -> bool:
	var file := FileAccess.open(storage_path, FileAccess.READ)
	if file == null:
		return false
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary or not parsed.get("bindings", {}) is Dictionary:
		return false
	var candidate: Dictionary = parsed["bindings"]
	var restored_skill_to_action := {}
	var restored_action_to_skill := {}
	for skill_text in candidate:
		var skill_id := StringName(skill_text)
		var action_id := StringName(candidate[skill_text])
		if (
			not _has_skill(skill_id)
			or not _is_allowed_action(action_id)
			or restored_action_to_skill.has(action_id)
		):
			continue
		restored_skill_to_action[skill_id] = action_id
		restored_action_to_skill[action_id] = skill_id
	if restored_skill_to_action.size() != loadout.get("skills").size():
		return false
	skill_to_action = restored_skill_to_action
	action_to_skill = restored_action_to_skill
	return true


func _save_bindings() -> bool:
	var serialized := {}
	for skill_id: StringName in skill_to_action:
		serialized[String(runtime_origins.get(skill_id, skill_id))] = String(skill_to_action[skill_id])
	var file := FileAccess.open(storage_path, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify({"version": 1, "bindings": serialized}, "  "))
	return true


func _has_skill(skill_id: StringName) -> bool:
	if loadout == null:
		return false
	for skill: Resource in loadout.get("skills"):
		if StringName(skill.get("skill_id")) == skill_id:
			return true
	return false


func _is_allowed_action(action_id: StringName) -> bool:
	return get_allowed_actions().has(action_id)


func _display_name(skill_id: StringName) -> String:
	for entry in get_entries():
		if entry[&"skill_id"] == skill_id:
			return entry[&"display_name"]
	return String(skill_id)


func _action_slot_label(action_id: StringName) -> String:
	var text := String(action_id).trim_prefix("combat_skill_")
	return "스킬 %s" % text


func _binding_text(action_id: StringName) -> String:
	if action_id.is_empty():
		return "미배치"
	if is_instance_valid(physical_binding_provider) and physical_binding_provider.has_method(&"get_entries"):
		for entry: Dictionary in physical_binding_provider.call(&"get_entries"):
			if entry[&"action_id"] == action_id:
				return String(entry[&"binding_text"])
	var labels := PackedStringArray()
	for event: InputEvent in InputMap.action_get_events(action_id):
		if is_instance_valid(physical_binding_provider) and physical_binding_provider.has_method(&"format_event"):
			labels.append(String(physical_binding_provider.call(&"format_event", event)))
		elif event is InputEventKey:
			labels.append(OS.get_keycode_string((event as InputEventKey).physical_keycode))
	return " / ".join(labels) if not labels.is_empty() else "미지정"


func _on_physical_bindings_changed(_snapshot: Dictionary) -> void:
	bindings_changed.emit(get_snapshot())


func _reject(message: String) -> Dictionary:
	binding_rejected.emit(message)
	return {&"success": false, &"message": message, &"swapped_skill_id": &""}
