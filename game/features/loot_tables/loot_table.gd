class_name LootTable
extends RefCounted

const COLUMNS := [
	"entry_id", "region_id", "difficulty_id", "map_size", "source_type", "item_id",
	"grade", "base_weight", "minimum_quantity", "maximum_quantity", "boss_only",
	"runtime_enabled", "planner_note",
]


static func parse(csv_text: String) -> Dictionary:
	var matrix := _parse_matrix(csv_text)
	if matrix.is_empty():
		return {&"data": [], &"errors": PackedStringArray(["CSV가 비어 있습니다."])}
	var headers: PackedStringArray = matrix[0]
	var errors := PackedStringArray()
	for column in COLUMNS:
		if column not in headers:
			errors.append("필수 열이 없습니다: %s" % column)
	if not errors.is_empty():
		return {&"data": [], &"errors": errors}
	var entries: Array[LootDropEntry] = []
	var entry_ids := {}
	for line_index in range(1, matrix.size()):
		var row := _to_row(headers, matrix[line_index])
		if not _is_enabled(row[&"runtime_enabled"]):
			continue
		var entry := LootDropEntry.new()
		entry.entry_id = StringName(row[&"entry_id"])
		entry.region_id = StringName(row[&"region_id"])
		entry.difficulty_id = StringName(row[&"difficulty_id"])
		entry.map_size = StringName(row[&"map_size"])
		entry.source_type = StringName(row[&"source_type"])
		entry.item_id = StringName(row[&"item_id"])
		entry.grade = int(row[&"grade"])
		entry.base_weight = float(row[&"base_weight"])
		entry.minimum_quantity = int(row[&"minimum_quantity"])
		entry.maximum_quantity = int(row[&"maximum_quantity"])
		entry.boss_only = _is_enabled(row[&"boss_only"])
		entry.planner_note = row[&"planner_note"]
		if entry_ids.has(entry.entry_id):
			errors.append("entry_id가 중복입니다: %s" % entry.entry_id)
			continue
		entry_ids[entry.entry_id] = true
		var row_errors := entry.validation_errors()
		for row_error in row_errors:
			errors.append("%s: %s" % [entry.entry_id, row_error])
		if row_errors.is_empty():
			entries.append(entry)
	return {&"data": entries, &"errors": errors}


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
