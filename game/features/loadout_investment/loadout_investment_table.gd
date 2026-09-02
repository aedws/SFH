class_name LoadoutInvestmentTable
extends RefCounted


static func parse(csv_text: String, item_kind: StringName) -> Dictionary:
	var lines := csv_text.replace("\r\n", "\n").replace("\r", "\n").split("\n", false)
	if lines.is_empty():
		return {&"entries": [], &"errors": PackedStringArray(["투자 CSV가 비어 있습니다."])}
	var headers := _parse_csv_line(lines[0])
	var required := [
		"item_id", "display_name", "slot_id", "resource_path", "run_investment_price",
		"default_owned", "required_unlock_id", "source_status",
	]
	var errors := PackedStringArray()
	for column in required:
		if column not in headers:
			errors.append("필수 열이 없습니다: %s" % column)
	if not errors.is_empty():
		return {&"entries": [], &"errors": errors}
	var entries: Array[LoadoutInvestmentEntry] = []
	var ids := {}
	for line_index in range(1, lines.size()):
		if lines[line_index].strip_edges().is_empty():
			continue
		var row := _to_row(headers, _parse_csv_line(lines[line_index]))
		var entry := LoadoutInvestmentEntry.new()
		entry.item_kind = item_kind
		entry.item_id = StringName(row[&"item_id"])
		entry.display_name = row[&"display_name"]
		entry.slot_id = StringName(row[&"slot_id"])
		entry.definition_path = row[&"resource_path"]
		entry.run_investment_price = int(row[&"run_investment_price"])
		entry.default_owned = row[&"default_owned"].to_lower() in ["true", "1", "yes", "y", "on"]
		entry.required_unlock_id = StringName(row[&"required_unlock_id"])
		entry.source_status = StringName(row[&"source_status"])
		if ids.has(entry.item_id):
			errors.append("item_id가 중복입니다: %s" % entry.item_id)
			continue
		ids[entry.item_id] = true
		for error in entry.validation_errors():
			errors.append("%s: %s" % [entry.item_id, error])
		if entry.validation_errors().is_empty():
			entries.append(entry)
	return {&"entries": entries, &"errors": errors}


static func _to_row(headers: PackedStringArray, cells: PackedStringArray) -> Dictionary:
	var row := {}
	for index in headers.size():
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
