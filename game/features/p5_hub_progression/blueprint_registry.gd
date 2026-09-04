class_name BlueprintRegistry
extends RefCounted

var profile: Node


func configure(profile_provider: Node) -> bool:
	profile = profile_provider
	return (
		is_instance_valid(profile)
		and profile.has_method(&"register_blueprint")
		and profile.has_method(&"is_blueprint_registered")
		and profile.has_method(&"get_snapshot")
	)


func register(blueprint_id: StringName) -> bool:
	if blueprint_id == &"" or is_registered(blueprint_id):
		return false
	return bool(profile.call(&"register_blueprint", blueprint_id))


func is_registered(blueprint_id: StringName) -> bool:
	return (
		blueprint_id != &""
		and bool(profile.call(&"is_blueprint_registered", blueprint_id))
	)


func registered_ids() -> Array[StringName]:
	var result: Array[StringName] = []
	for value in profile.call(&"get_snapshot").get(&"registered_blueprint_ids", []):
		var blueprint_id := StringName(value)
		if blueprint_id != &"" and blueprint_id not in result:
			result.append(blueprint_id)
	return result


func get_snapshot() -> Dictionary:
	var ids := registered_ids()
	return {&"registered_ids": ids, &"registered_count": ids.size()}
