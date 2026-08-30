class_name TimedStatModifier
extends Node

var target: Node
var source_id: StringName
var remaining_seconds: float = 0.0


func configure(
	new_target: Node,
	new_source_id: StringName,
	modifiers: Dictionary,
	duration_seconds: float
) -> bool:
	if (
		not is_instance_valid(new_target)
		or not new_target.has_method(&"set_runtime_modifier_source")
		or not new_target.has_method(&"remove_runtime_modifier_source")
		or new_source_id == &""
		or duration_seconds <= 0.0
	):
		return false
	target = new_target
	source_id = new_source_id
	remaining_seconds = duration_seconds
	target.call(&"set_runtime_modifier_source", source_id, modifiers)
	return true


func _process(delta: float) -> void:
	remaining_seconds = maxf(0.0, remaining_seconds - maxf(0.0, delta))
	if remaining_seconds <= 0.0:
		queue_free()


func _exit_tree() -> void:
	if is_instance_valid(target) and target.has_method(&"remove_runtime_modifier_source"):
		target.call(&"remove_runtime_modifier_source", source_id)
