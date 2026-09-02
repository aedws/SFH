class_name P5CatalogTable
extends RefCounted


static func load_rows(path: String) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	if path.is_empty() or not FileAccess.file_exists(path):
		return rows
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return rows
	var headers := file.get_csv_line()
	if headers.is_empty():
		return rows
	file.get_csv_line() # 2행은 사람이 읽는 설명 영역입니다.
	while not file.eof_reached():
		var values := file.get_csv_line()
		if values.is_empty() or String(values[0]).strip_edges().is_empty():
			continue
		var row: Dictionary = {}
		for index in mini(headers.size(), values.size()):
			row[StringName(String(headers[index]).strip_edges())] = _typed_value(values[index])
		if bool(row.get(&"runtime_enabled", true)):
			rows.append(row)
	return rows


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
