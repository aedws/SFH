class_name EquipmentIdentityTable
extends RefCounted

const REQUIRED_COLUMNS := [
	"equipment_kind", "definition_id", "display_name",
	"innate_skill_id", "innate_skill_name", "innate_trigger_hits", "innate_fixed_damage",
	"innate_effect_kind", "innate_effect_radius", "innate_maximum_targets",
	"fixed_option_id", "fixed_option_name", "fixed_option_modifier",
	"fixed_option_operation", "fixed_option_value", "scaling_policy", "source_status",
]

var records: Dictionary = {}


func load_locked(path: String) -> bool:
	records.clear()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return false
	var headers := file.get_csv_line()
	if PackedStringArray(headers) != PackedStringArray(REQUIRED_COLUMNS):
		return false
	while not file.eof_reached():
		var cells := file.get_csv_line()
		if cells.is_empty() or String(cells[0]).is_empty():
			continue
		var row: Dictionary = {}
		for index in REQUIRED_COLUMNS.size():
			row[StringName(REQUIRED_COLUMNS[index])] = String(cells[index]) if index < cells.size() else ""
		var key := _key(StringName(row[&"equipment_kind"]), StringName(row[&"definition_id"]))
		if key == &"" or records.has(key) or row[&"scaling_policy"] != "fixed_identity":
			return false
		records[key] = row
	return not records.is_empty()


func get_record(equipment_kind: StringName, definition_id: StringName) -> Dictionary:
	return (records.get(_key(equipment_kind, definition_id), {}) as Dictionary).duplicate(true)


func _key(equipment_kind: StringName, definition_id: StringName) -> StringName:
	if equipment_kind not in [&"weapon", &"armor"] or definition_id == &"":
		return &""
	return StringName("%s:%s" % [equipment_kind, definition_id])
