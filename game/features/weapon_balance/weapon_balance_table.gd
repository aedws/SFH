class_name WeaponBalanceTable
extends RefCounted

const REQUIRED_COLUMNS := [
	"weapon_id",
	"display_name",
	"trait_id",
	"damage",
	"fire_interval_sec",
	"projectile_speed_px_sec",
	"target_range_px",
	"projectiles_per_shot",
	"spread_angle_deg",
	"burst_count",
	"burst_interval_sec",
	"critical_chance",
	"critical_multiplier",
	"pierce_count",
	"pierce_damage_retention",
	"projectile_lifetime_sec",
	"projectile_color_hex",
	"description",
]


static func parse(csv_text: String) -> Dictionary:
	var lines := csv_text.replace("\r\n", "\n").replace("\r", "\n").split("\n", false)
	if lines.is_empty():
		return {&"data": {}, &"errors": PackedStringArray(["CSV가 비어 있습니다."])}
	var headers := _parse_csv_line(lines[0])
	var errors := PackedStringArray()
	for required_column in REQUIRED_COLUMNS:
		if required_column not in headers:
			errors.append("필수 열이 없습니다: %s" % required_column)
	if not errors.is_empty():
		return {&"data": {}, &"errors": errors}

	var result: Dictionary = {}
	for line_index in range(1, lines.size()):
		if lines[line_index].strip_edges().is_empty():
			continue
		var cells := _parse_csv_line(lines[line_index])
		if cells.size() < headers.size():
			errors.append("%d행의 열 수가 헤더보다 적습니다." % (line_index + 1))
			continue
		var row: Dictionary = {}
		for column_index in range(headers.size()):
			row[StringName(headers[column_index])] = cells[column_index].strip_edges()
		var weapon_id := StringName(row[&"weapon_id"])
		if weapon_id == &"" or result.has(weapon_id):
			errors.append("%d행의 weapon_id가 비어 있거나 중복입니다." % (line_index + 1))
			continue
		var parsed := _convert_row(row)
		var row_error := _validate_row(parsed)
		if not row_error.is_empty():
			errors.append("%s: %s" % [weapon_id, row_error])
			continue
		result[weapon_id] = parsed
	return {&"data": result, &"errors": errors}


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


static func _convert_row(row: Dictionary) -> Dictionary:
	return {
		&"weapon_id": StringName(row[&"weapon_id"]),
		&"display_name": String(row[&"display_name"]),
		&"trait_id": StringName(row[&"trait_id"]),
		&"damage": float(row[&"damage"]),
		&"fire_interval_sec": float(row[&"fire_interval_sec"]),
		&"projectile_speed_px_sec": float(row[&"projectile_speed_px_sec"]),
		&"target_range_px": float(row[&"target_range_px"]),
		&"projectiles_per_shot": int(row[&"projectiles_per_shot"]),
		&"spread_angle_deg": float(row[&"spread_angle_deg"]),
		&"burst_count": int(row[&"burst_count"]),
		&"burst_interval_sec": float(row[&"burst_interval_sec"]),
		&"critical_chance": float(row[&"critical_chance"]),
		&"critical_multiplier": float(row[&"critical_multiplier"]),
		&"pierce_count": int(row[&"pierce_count"]),
		&"pierce_damage_retention": float(row[&"pierce_damage_retention"]),
		&"projectile_lifetime_sec": float(row[&"projectile_lifetime_sec"]),
		&"projectile_color": Color.from_string(row[&"projectile_color_hex"], Color.WHITE),
		&"description": String(row[&"description"]),
	}


static func _validate_row(row: Dictionary) -> String:
	if row[&"display_name"].is_empty() or row[&"trait_id"] == &"":
		return "표시 이름과 특색 ID가 필요합니다."
	if row[&"damage"] <= 0.0 or row[&"fire_interval_sec"] <= 0.0:
		return "피해량과 발사 주기는 0보다 커야 합니다."
	if row[&"projectile_speed_px_sec"] <= 0.0 or row[&"target_range_px"] <= 0.0:
		return "투사체 속도와 자동 탐지 거리는 0보다 커야 합니다."
	if row[&"projectiles_per_shot"] < 1 or row[&"burst_count"] < 1:
		return "발사체 수와 버스트 수는 1 이상이어야 합니다."
	if row[&"critical_chance"] < 0.0 or row[&"critical_chance"] > 1.0:
		return "치명타 확률은 0~1 범위여야 합니다."
	if row[&"critical_multiplier"] < 1.0:
		return "치명타 배율은 1 이상이어야 합니다."
	if row[&"pierce_count"] < 0:
		return "관통 횟수는 음수일 수 없습니다."
	if row[&"pierce_damage_retention"] <= 0.0 or row[&"pierce_damage_retention"] > 1.0:
		return "관통 피해 유지율은 0 초과 1 이하여야 합니다."
	return ""
