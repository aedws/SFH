class_name SessionSocketTable
extends RefCounted

const COLUMNS := [
	"rule_id", "item_id", "display_name", "socket_type", "slot_capacity",
	"duplicate_limit", "replacement_policy", "effect_target", "modifier_id",
	"modifier_operation", "modifier_value", "priority", "runtime_enabled", "description",
]


static func parse(csv_text: String) -> Dictionary:
	var matrix := _parse_matrix(csv_text)
	if matrix.is_empty():
		return {&"rules": [], &"errors": PackedStringArray(["CSV가 비어 있습니다."])}
	var headers: PackedStringArray = matrix[0]
	var errors := PackedStringArray()
	for column in COLUMNS:
		if column not in headers:
			errors.append("필수 열이 없습니다: %s" % column)
	if not errors.is_empty():
		return {&"rules": [], &"errors": errors}
	var rules: Array[SessionSocketRule] = []
	var rule_ids: Dictionary = {}
	var type_capacities: Dictionary = {}
	var item_contracts: Dictionary = {}
	for line_index in range(1, matrix.size()):
		var row := _to_row(headers, matrix[line_index])
		if not _is_enabled(row[&"runtime_enabled"]):
			continue
		var rule := SessionSocketRule.new()
		rule.rule_id = StringName(row[&"rule_id"])
		rule.item_id = StringName(row[&"item_id"])
		rule.display_name = row[&"display_name"]
		rule.socket_type = StringName(row[&"socket_type"])
		rule.slot_capacity = int(row[&"slot_capacity"])
		rule.duplicate_limit = int(row[&"duplicate_limit"])
		rule.replacement_policy = StringName(row[&"replacement_policy"])
		rule.effect_target = StringName(row[&"effect_target"])
		rule.modifier_id = StringName(row[&"modifier_id"])
		rule.modifier_operation = StringName(row[&"modifier_operation"])
		rule.modifier_value = float(row[&"modifier_value"])
		rule.priority = int(row[&"priority"])
		rule.description = row[&"description"]
		if rule_ids.has(rule.rule_id):
			errors.append("rule_id가 중복입니다: %s" % rule.rule_id)
			continue
		rule_ids[rule.rule_id] = true
		var rule_errors := rule.validation_errors()
		for rule_error in rule_errors:
			errors.append("%s: %s" % [rule.rule_id, rule_error])
		var socket_contract := {
			&"capacity": rule.slot_capacity,
			&"replacement_policy": rule.replacement_policy,
		}
		if type_capacities.has(rule.socket_type) and type_capacities[rule.socket_type] != socket_contract:
			errors.append("%s 소켓의 수량·교체 정책이 행마다 다릅니다." % rule.socket_type)
		else:
			type_capacities[rule.socket_type] = socket_contract
		var item_contract := {
			&"socket_type": rule.socket_type,
			&"duplicate_limit": rule.duplicate_limit,
			&"display_name": rule.display_name,
		}
		if item_contracts.has(rule.item_id) and item_contracts[rule.item_id] != item_contract:
			errors.append("%s 아이템의 소켓·중복 계약이 행마다 다릅니다." % rule.item_id)
		else:
			item_contracts[rule.item_id] = item_contract
		if rule_errors.is_empty():
			rules.append(rule)
	rules.sort_custom(func(left: SessionSocketRule, right: SessionSocketRule) -> bool:
		return left.priority < right.priority
	)
	return {&"rules": rules, &"errors": errors}


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
