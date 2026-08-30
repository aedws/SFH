class_name TimedStatModifier
extends Timer

var target: Node
var source_id: StringName


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
	wait_time = duration_seconds
	one_shot = true
	timeout.connect(queue_free)
	target.call(&"set_runtime_modifier_source", source_id, modifiers)
	start()
	return true


func _exit_tree() -> void:
	if is_instance_valid(target) and target.has_method(&"remove_runtime_modifier_source"):
		target.call(&"remove_runtime_modifier_source", source_id)
