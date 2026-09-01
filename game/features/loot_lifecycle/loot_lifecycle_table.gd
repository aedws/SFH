class_name LootLifecycleTable
extends RefCounted

const COLUMNS := [
	"item_id", "display_name", "item_type", "grid_width", "grid_height",
	"linked_resource", "credit_value", "consumable", "description", "loot_family",
	"session_behavior", "extract_result", "death_result", "convert_value", "region_tags",
	"runtime_enabled",
]


static func parse(csv_text: String) -> Dictionary:
	var matrix := _parse_matrix(csv_text)
	if matrix.is_empty():
		return {&"data": {}, &"errors": PackedStringArray(["CSV가 비어 있습니다."])}
	var headers: PackedStringArray = matrix[0]
	var errors := PackedStringArray()
	for column in COLUMNS:
		if column not in headers:
			errors.append("필수 열이 없습니다: %s" % column)
	if not errors.is_empty():
		return {&"data": {}, &"errors": errors}
	var definitions: Dictionary = {}
	for line_index in range(1, matrix.size()):
		var row := _to_row(headers, matrix[line_index])
		if not _is_enabled(row[&"runtime_enabled"]):
			continue
		var definition := LootLifecycleDefinition.new()
		definition.item_id = StringName(row[&"item_id"])
		definition.display_name = row[&"display_name"]
		definition.item_type = StringName(row[&"item_type"])
		definition.loot_family = StringName(row[&"loot_family"])
		definition.session_behavior = StringName(row[&"session_behavior"])
		definition.extract_result = StringName(row[&"extract_result"])
		definition.death_result = StringName(row[&"death_result"])
		definition.convert_value = int(row[&"convert_value"])
		definition.region_tags = _parse_tags(row[&"region_tags"])
		definition.description = row[&"description"]
		if definitions.has(definition.item_id):
			errors.append("item_id가 중복입니다: %s" % definition.item_id)
			continue
		var row_errors := definition.validation_errors()
		for row_error in row_errors:
			errors.append("%s: %s" % [definition.item_id, row_error])
		if row_errors.is_empty():
			definitions[definition.item_id] = definition
	return {&"data": definitions, &"errors": errors}


static func _parse_matrix(csv_text: String) -> Array[PackedStringArray]:
	var matrix: Array[PackedStringArray] = []
	for line in csv_text.replace("\r\n", "\n").replace("\r", "\n").split("\n", false):
		if not line.strip_edges().is_empty():
			matrix.append(_parse_csv_line(line))
	return matrix


static func _to_row(headers: PackedStringArray, cells: PackedStringArray) -> Dictionary:
	var row: Dictionary = {}
	for index in range(headers.size()):
		row[StringName(headers[index])] = cells[index].strip_edges() if index < cells.size() else ""
	return row


static func _parse_tags(value: String) -> PackedStringArray:
	var result := PackedStringArray()
	for tag in value.split("|", false):
		result.append(tag.strip_edges())
	return result


static func _is_enabled(value: String) -> bool:
	return value.strip_edges().to_lower() in ["true", "1", "yes", "y", "on"]


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
