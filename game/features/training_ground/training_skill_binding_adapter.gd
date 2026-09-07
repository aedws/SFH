class_name TrainingSkillBindingAdapter
extends Node

## Maps the current trial skill to the original slot's live key setting without
## changing or saving the permanent skill binding provider.
signal bindings_changed(snapshot: Dictionary)
var loadout: Resource
var source: Node
var original_ids: Array[StringName] = []
var fallback_actions: Array[StringName] = []
var fallback_labels: Array[String] = []

func configure(current_loadout: Resource, binding_source: Node = null) -> void:
	if is_instance_valid(source) and source.has_signal(&"bindings_changed") and source.is_connected(&"bindings_changed", _on_bindings_changed):
		source.disconnect(&"bindings_changed", _on_bindings_changed)
	original_ids.clear()
	fallback_actions.clear()
	fallback_labels.clear()
	loadout = current_loadout
	source = binding_source
	for skill: Resource in loadout.get("skills"):
		original_ids.append(StringName(skill.get("skill_id")))
		fallback_actions.append(StringName(skill.get("input_action")))
		fallback_labels.append(String(skill.get("input_label")))
	if is_instance_valid(source) and source.has_signal(&"bindings_changed"):
		source.connect(&"bindings_changed", _on_bindings_changed)

func _on_bindings_changed(snapshot: Dictionary) -> void:
	bindings_changed.emit(snapshot)

func action_for_skill(skill_id: StringName) -> StringName:
	var index := _index_of(skill_id)
	if index < 0: return &""
	if is_instance_valid(source):
		return source.call(&"action_for_skill", original_ids[index])
	return fallback_actions[index]

func input_label_for_skill(skill_id: StringName) -> String:
	var index := _index_of(skill_id)
	if index < 0: return "미배치"
	if is_instance_valid(source):
		return String(source.call(&"input_label_for_skill", original_ids[index]))
	return fallback_labels[index]

func skill_for_action(action_id: StringName) -> StringName:
	for skill: Resource in loadout.get("skills"):
		var id := StringName(skill.get("skill_id"))
		if action_for_skill(id) == action_id: return id
	return &""

func _index_of(skill_id: StringName) -> int:
	for index in mini(loadout.get("skills").size(), original_ids.size()):
		if StringName(loadout.get("skills")[index].get("skill_id")) == skill_id:
			return index
	return -1
