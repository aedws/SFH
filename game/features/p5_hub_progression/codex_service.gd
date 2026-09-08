class_name CodexService
extends RefCounted

var profile: Node
var entries: Array[Dictionary] = []


func configure(profile_provider: Node, rows: Array[Dictionary]) -> bool:
	profile = profile_provider
	entries = rows.duplicate(true)
	return is_instance_valid(profile) and not entries.is_empty()


func record_extraction(acquired: Dictionary) -> PackedStringArray:
	var completed := PackedStringArray()
	for entry in entries:
		var source_id := StringName(entry.get(&"source_id", &""))
		var quantity := _quantity_of(acquired.get(source_id, 0))
		if quantity <= 0:
			continue
		var entry_id := StringName(entry.get(&"entry_id", &""))
		var progress := int(profile.call(&"add_codex_progress", entry_id, quantity))
		if progress >= int(entry.get(&"required_count", 1)):
			completed.append(String(entry_id))
	return completed


func _quantity_of(value: Variant) -> int:
	if value is Dictionary:
		return maxi(0, int((value as Dictionary).get(&"quantity", 0)))
	if value is int or value is float:
		return maxi(0, int(value))
	return 0


func get_entry(entry_id: StringName) -> Dictionary:
	for entry in entries:
		if StringName(entry.get(&"entry_id", &"")) == entry_id:
			var result := entry.duplicate(true)
			var progress := int(profile.call(&"get_codex_progress", entry_id))
			result[&"progress"] = progress
			result[&"completed"] = progress >= int(entry.get(&"required_count", 1))
			return result
	return {}


func get_region_hints() -> Dictionary:
	var result := {}
	for entry in entries:
		var region := StringName(entry.get(&"region_hint", &""))
		if region != &"":
			if not result.has(region):
				result[region] = PackedStringArray()
			result[region].append(String(entry.get(&"display_name", entry.get(&"entry_id", &""))))
	return result


func get_snapshot() -> Dictionary:
	var completed := 0
	for entry in entries:
		if bool(get_entry(StringName(entry.get(&"entry_id", &""))).get(&"completed", false)):
			completed += 1
	return {&"entry_count": entries.size(), &"completed_count": completed,
		&"progress": profile.call(&"get_snapshot").get(&"codex_progress", {}),
		&"region_hints": get_region_hints()}


func get_entries() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in entries:
		result.append(get_entry(StringName(entry.get(&"entry_id", &""))))
	return result
