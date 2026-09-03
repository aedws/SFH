class_name CatalogCsvTable
extends RefCounted


static func load_rows(path: String, payload: Resource = null) -> Array[Dictionary]:
	return load_table(path, [], &"", payload).get(&"rows", [])


static func load_table(
	path: String,
	required_headers: Array = [],
	unique_id_column: StringName = &"",
	payload: Resource = null,
	text_columns: Array = []
) -> Dictionary:
	var rows: Array[Dictionary] = []
	var csv_text := _read_csv_text(path, payload)
	if csv_text.is_empty():
		return {&"success": false, &"rows": rows, &"errors": ["CSV 파일 없음: %s" % path]}
	return parse_table(csv_text, required_headers, unique_id_column, text_columns)


static func parse_table(csv_text: String, required_headers: Array = [], unique_id_column: StringName = &"", text_columns: Array = []) -> Dictionary:
	var rows: Array[Dictionary] = []
	var csv_lines := _parse_csv_text(csv_text)
	if csv_lines.is_empty():
		return {&"success": false, &"rows": rows, &"errors": ["CSV 내용 없음"]}
	var headers: PackedStringArray = csv_lines[0]
	if headers.is_empty():
		return {&"success": false, &"rows": rows, &"errors": ["CSV 헤더 없음"]}
	var normalized_headers := PackedStringArray()
	for header in headers:
		normalized_headers.append(String(header).strip_edges())
	var errors := PackedStringArray()
	for required in required_headers:
		if String(required) not in normalized_headers:
			errors.append("필수 열 누락: %s" % required)
	if not errors.is_empty():
		return {&"success": false, &"rows": rows, &"errors": errors}
	var unique_ids: Dictionary = {}
	for line_index in range(2, csv_lines.size()): # 2행은 사람이 읽는 설명 영역입니다.
		var row_number := line_index + 1
		var values: PackedStringArray = csv_lines[line_index]
		if values.is_empty() or String(values[0]).strip_edges().is_empty():
			continue
		var row: Dictionary = {}
		for index in mini(headers.size(), values.size()):
			var key := StringName(String(headers[index]).strip_edges())
			row[key] = String(values[index]).strip_edges() if key in text_columns else _typed_value(values[index])
		if unique_id_column != &"":
			var unique_id := StringName(row.get(unique_id_column, &""))
			if unique_id == &"":
				errors.append("%d행 ID 비어 있음: %s" % [row_number, unique_id_column])
			elif unique_ids.has(unique_id):
				errors.append("중복 ID: %s" % unique_id)
			else:
				unique_ids[unique_id] = true
		if bool(row.get(&"runtime_enabled", true)):
			rows.append(row)
	return {&"success": errors.is_empty() and not rows.is_empty(), &"rows": rows, &"errors": errors}


static func _read_csv_text(path: String, payload: Resource) -> String:
	if not path.is_empty() and FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file != null:
			var text := file.get_as_text()
			if not text.is_empty():
				return text
	if (
		payload != null
		and payload.has_method(&"is_valid_for")
		and bool(payload.call(&"is_valid_for", path))
	):
		return String(payload.call(&"get_csv_text"))
	return ""


static func _parse_csv_text(text: String) -> Array[PackedStringArray]:
	var result: Array[PackedStringArray] = []
	for line in text.replace("\r\n", "\n").replace("\r", "\n").split("\n", false):
		if not line.strip_edges().is_empty():
			result.append(_parse_csv_line(line))
	return result


static func _parse_csv_line(line: String) -> PackedStringArray:
	var values := PackedStringArray()
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
			values.append(current)
			current = ""
		else:
			current += character
		index += 1
	values.append(current)
	return values


static func _typed_value(value: String) -> Variant:
	var normalized := value.strip_edges()
	if normalized.to_lower() == "true":
		return true
	if normalized.to_lower() == "false":
		return false
	if normalized.is_valid_int():
		return normalized.to_int()
	if normalized.is_valid_float():
		return normalized.to_float()
	return StringName(normalized) if normalized.contains("_") and " " not in normalized else normalized
