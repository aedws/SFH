class_name CharacterTable
extends RefCounted

const COLUMNS := [
	"character_id", "display_name", "entry_cost", "passive_id", "passive_name",
	"passive_description", "max_health_add", "defense_add",
	"movement_speed_multiplier", "runtime_enabled", "source_status", "planner_note",
]


static func parse(csv_text: String) -> Dictionary:
	var matrix: Array[PackedStringArray] = []
	for line in csv_text.replace("\r\n", "\n").replace("\r", "\n").split("\n", false):
		if not line.strip_edges().is_empty():
			matrix.append(_parse_csv_line(line))
	if matrix.is_empty():
		return {&"definitions": [], &"errors": PackedStringArray(["Character CSV가 비어 있습니다."])}
	var headers := matrix[0]
	var errors := PackedStringArray()
	for column in COLUMNS:
		if column not in headers:
			errors.append("필수 열이 없습니다: %s" % column)
	if not errors.is_empty():
		return {&"definitions": [], &"errors": errors}
	var definitions: Array[CharacterDefinition] = []
	var ids := {}
	for line_index in range(1, matrix.size()):
		var row := _to_row(headers, matrix[line_index])
		if row[&"runtime_enabled"].to_lower() not in ["true", "1", "yes", "y", "on"]:
			continue
		var definition := CharacterDefinition.new()
		definition.character_id = StringName(row[&"character_id"])
		definition.display_name = row[&"display_name"]
		definition.entry_cost = int(row[&"entry_cost"])
		definition.passive_id = StringName(row[&"passive_id"])
		definition.passive_name = row[&"passive_name"]
		definition.passive_description = row[&"passive_description"]
		definition.max_health_add = float(row[&"max_health_add"])
		definition.defense_add = float(row[&"defense_add"])
		definition.movement_speed_multiplier = float(row[&"movement_speed_multiplier"])
		definition.source_status = StringName(row[&"source_status"])
		definition.planner_note = row[&"planner_note"]
		definition.skill_families = row.get(&"skill_families", "")
		for key in ["skill_damage_multiplier", "skill_cooldown_multiplier", "skill_radius_multiplier"]:
			var value := String(row.get(StringName(key), "1"))
			definition.set(key, float(value) if not value.is_empty() else 1.0)
		if ids.has(definition.character_id):
			errors.append("character_id가 중복입니다: %s" % definition.character_id)
			continue
		ids[definition.character_id] = true
		var definition_errors := definition.validation_errors()
		for definition_error in definition_errors:
			errors.append("%s: %s" % [definition.character_id, definition_error])
		if definition_errors.is_empty():
			definitions.append(definition)
	return {&"definitions": definitions, &"errors": errors}


static func _to_row(headers: PackedStringArray, cells: PackedStringArray) -> Dictionary:
	var row := {}
	for index in range(headers.size()):
		row[StringName(headers[index])] = cells[index].strip_edges() if index < cells.size() else ""
	return row


static func _parse_csv_line(line: String) -> PackedStringArray:
	var cells := PackedStringArray()
	var current := ""
	var in_quotes := false
	var index := 0
	while index < line.length():
		var character := line[index]
		if character == '"':
			if in_quotes and index + 1 < line.length() and line[index + 1] == '"':
				current += '"'
				index += 1
			else:
				in_quotes = not in_quotes
		elif character == "," and not in_quotes:
			cells.append(current)
			current = ""
		else:
			current += character
		index += 1
	cells.append(current)
	return cells
