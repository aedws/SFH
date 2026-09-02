class_name P5CatalogTable
extends RefCounted


static func load_rows(path: String) -> Array[Dictionary]:
	return load_table(path).get(&"rows", [])


static func load_table(path: String, required_headers: Array = [], unique_id_column: StringName = &"") -> Dictionary:
	var rows: Array[Dictionary] = []
	if path.is_empty() or not FileAccess.file_exists(path):
		return {&"success": false, &"rows": rows, &"errors": ["CSV 파일 없음: %s" % path]}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {&"success": false, &"rows": rows, &"errors": ["CSV 열기 실패: %s" % path]}
	var headers := file.get_csv_line()
	if headers.is_empty():
		return {&"success": false, &"rows": rows, &"errors": ["CSV 헤더 없음: %s" % path]}
	var normalized_headers := PackedStringArray()
	for header in headers:
		normalized_headers.append(String(header).strip_edges())
	var errors := PackedStringArray()
	for required in required_headers:
		if String(required) not in normalized_headers:
			errors.append("필수 열 누락: %s" % required)
	if not errors.is_empty():
		return {&"success": false, &"rows": rows, &"errors": errors}
	file.get_csv_line() # 2행은 사람이 읽는 설명 영역입니다.
	var unique_ids: Dictionary = {}
	var row_number := 2
	while not file.eof_reached():
		row_number += 1
		var values := file.get_csv_line()
		if values.is_empty() or String(values[0]).strip_edges().is_empty():
			continue
		var row: Dictionary = {}
		for index in mini(headers.size(), values.size()):
			row[StringName(String(headers[index]).strip_edges())] = _typed_value(values[index])
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
