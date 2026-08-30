class_name GrowthBalanceTable
extends RefCounted

const RUN_BUFF_COLUMNS := [
	"buff_id", "display_name", "maximum_stacks", "meta_target",
	"max_health_add", "defense_add", "movement_speed_add", "movement_speed_multiply",
	"weapon_damage_add", "weapon_damage_multiply", "fire_interval_multiply",
	"target_range_multiply", "heal_on_apply", "runtime_enabled", "description",
]
const UPGRADE_COLUMNS := [
	"target_kind", "target_id", "level", "maximum_level", "module_capacity_cost",
	"credit_cost", "material_quantity", "player_stat_id", "player_stat_add",
	"player_stat_multiply", "weapon_damage_add", "weapon_damage_multiply",
	"weapon_fire_interval_multiply", "weapon_target_range_multiply", "runtime_enabled",
	"display_name", "description",
]


static func parse_run_buffs(csv_text: String) -> Dictionary:
	var parsed := _parse_rows(csv_text, RUN_BUFF_COLUMNS)
	if not (parsed[&"errors"] as PackedStringArray).is_empty():
		return parsed
	var result: Dictionary = {}
	var errors := PackedStringArray()
	for source_row in parsed[&"rows"]:
		if not _is_enabled(source_row[&"runtime_enabled"]):
			continue
		var buff_id := StringName(source_row[&"buff_id"])
		if buff_id == &"" or result.has(buff_id):
			errors.append("buff_id가 비어 있거나 중복입니다: %s" % buff_id)
			continue
		var row := {
			&"buff_id": buff_id,
			&"display_name": String(source_row[&"display_name"]),
			&"maximum_stacks": int(source_row[&"maximum_stacks"]),
			&"meta_target": StringName(source_row[&"meta_target"]),
			&"max_health_add": float(source_row[&"max_health_add"]),
			&"defense_add": float(source_row[&"defense_add"]),
			&"movement_speed_add": float(source_row[&"movement_speed_add"]),
			&"movement_speed_multiply": float(source_row[&"movement_speed_multiply"]),
			&"weapon_damage_add": float(source_row[&"weapon_damage_add"]),
			&"weapon_damage_multiply": float(source_row[&"weapon_damage_multiply"]),
			&"fire_interval_multiply": float(source_row[&"fire_interval_multiply"]),
			&"target_range_multiply": float(source_row[&"target_range_multiply"]),
			&"heal_on_apply": float(source_row[&"heal_on_apply"]),
			&"description": String(source_row[&"description"]),
		}
		var row_error := _validate_run_buff(row)
		if not row_error.is_empty():
			errors.append("%s: %s" % [buff_id, row_error])
			continue
		result[buff_id] = row
	return {&"data": result, &"errors": errors}


static func parse_upgrades(csv_text: String) -> Dictionary:
	var parsed := _parse_rows(csv_text, UPGRADE_COLUMNS)
	if not (parsed[&"errors"] as PackedStringArray).is_empty():
		return parsed
	var result: Dictionary = {}
	var errors := PackedStringArray()
	for source_row in parsed[&"rows"]:
		if not _is_enabled(source_row[&"runtime_enabled"]):
			continue
		var target_kind := StringName(source_row[&"target_kind"])
		var target_id := StringName(source_row[&"target_id"])
		var level := int(source_row[&"level"])
		var key := upgrade_key(target_kind, target_id, level)
		if target_kind not in [&"weapon", &"armor", &"module"]:
			errors.append("지원하지 않는 target_kind입니다: %s" % target_kind)
			continue
		if target_id == &"" or level < 1 or result.has(key):
			errors.append("강화 키가 비어 있거나 중복입니다: %s" % key)
			continue
		var row := {
			&"target_kind": target_kind,
			&"target_id": target_id,
			&"level": level,
			&"maximum_level": int(source_row[&"maximum_level"]),
			&"module_capacity_cost": int(source_row[&"module_capacity_cost"]),
			&"credit_cost": int(source_row[&"credit_cost"]),
			&"material_quantity": int(source_row[&"material_quantity"]),
			&"player_stat_id": StringName(source_row[&"player_stat_id"]),
			&"player_stat_add": float(source_row[&"player_stat_add"]),
			&"player_stat_multiply": float(source_row[&"player_stat_multiply"]),
			&"weapon_damage_add": float(source_row[&"weapon_damage_add"]),
			&"weapon_damage_multiply": float(source_row[&"weapon_damage_multiply"]),
			&"weapon_fire_interval_multiply": float(source_row[&"weapon_fire_interval_multiply"]),
			&"weapon_target_range_multiply": float(source_row[&"weapon_target_range_multiply"]),
			&"display_name": String(source_row[&"display_name"]),
			&"description": String(source_row[&"description"]),
		}
		var row_error := _validate_upgrade(row)
		if not row_error.is_empty():
			errors.append("%s: %s" % [key, row_error])
			continue
		result[key] = row
	return {&"data": result, &"errors": errors}


static func upgrade_key(target_kind: StringName, target_id: StringName, level: int) -> StringName:
	return StringName("%s:%s:%d" % [target_kind, target_id, level])


static func _parse_rows(csv_text: String, required_columns: Array) -> Dictionary:
	var lines := csv_text.replace("\r\n", "\n").replace("\r", "\n").split("\n", false)
	if lines.is_empty():
		return {&"rows": [], &"errors": PackedStringArray(["CSV가 비어 있습니다."])}
	var matrix: Array[PackedStringArray] = []
	for line in lines:
		if not line.strip_edges().is_empty():
			matrix.append(_parse_csv_line(line))
	if matrix.is_empty():
		return {&"rows": [], &"errors": PackedStringArray(["CSV가 비어 있습니다."])}
	var headers := matrix[0]
	var errors := PackedStringArray()
	for required_column in required_columns:
		if required_column not in headers:
			errors.append("필수 열이 없습니다: %s" % required_column)
	if not errors.is_empty():
		return {&"rows": [], &"errors": errors}
	var rows: Array[Dictionary] = []
	for line_index in range(1, matrix.size()):
		var cells := matrix[line_index]
		var row: Dictionary = {}
		for column_index in range(headers.size()):
			row[StringName(headers[column_index])] = (
				cells[column_index].strip_edges() if column_index < cells.size() else ""
			)
		rows.append(row)
	return {&"rows": rows, &"errors": errors}


static func _validate_run_buff(row: Dictionary) -> String:
	if row[&"display_name"].is_empty() or row[&"description"].is_empty():
		return "표시 이름과 설명이 필요합니다."
	if row[&"maximum_stacks"] < 1:
		return "최대 중첩은 1 이상이어야 합니다."
	if row[&"meta_target"] not in [&"character", &"weapon", &"armor"]:
		return "meta_target은 character, weapon, armor 중 하나여야 합니다."
	for multiplier_id in [
		&"movement_speed_multiply", &"weapon_damage_multiply",
		&"fire_interval_multiply", &"target_range_multiply",
	]:
		if float(row[multiplier_id]) <= 0.0:
			return "%s는 0보다 커야 합니다." % multiplier_id
	return ""


static func _validate_upgrade(row: Dictionary) -> String:
	if row[&"maximum_level"] < row[&"level"]:
		return "maximum_level은 현재 level 이상이어야 합니다."
	if row[&"module_capacity_cost"] < 0 or row[&"credit_cost"] < 0:
		return "코스트는 음수일 수 없습니다."
	if row[&"material_quantity"] < 0:
		return "재료 수량은 음수일 수 없습니다."
	for multiplier_id in [
		&"player_stat_multiply", &"weapon_damage_multiply",
		&"weapon_fire_interval_multiply", &"weapon_target_range_multiply",
	]:
		if float(row[multiplier_id]) <= 0.0:
			return "%s는 0보다 커야 합니다." % multiplier_id
	return ""


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
