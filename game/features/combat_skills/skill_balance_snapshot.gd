class_name SkillBalanceSnapshot
extends RefCounted
## Plain-data boundary for live trials and immutable operation plans.
static func apply(definition: Resource, values: Dictionary) -> Resource:
	var result: Resource = definition.duplicate(true)
	for key in ["cooldown_seconds", "energy_cost", "maximum_charges", "charge_recovery_seconds"]:
		if values.has(key): result.set(key, values[key])
	if values.has("effect"):
		if not result.effect is TacticalPatternEffect: return null
		var allowed: Dictionary = result.effect.get_parameters()
		for key in values.effect:
			if not allowed.has(StringName(key)): return null
			result.effect.set(key, values.effect[key])
		var pattern: Resource = result.effect
		result.targeting_range = pattern.radius
		result.targeting_mode = "densest" if pattern.anchor_on_target else "highest_health" if pattern.shape == "single" else "direction" if pattern.shape in ["line", "cone"] else "self"
	return result if result.is_valid() else null

static func parse_rows(text: String) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var lines := text.replace("\r", "").split("\n", false)
	if lines.size() < 2: return rows
	var header := CatalogCsvTable._parse_csv_line(lines[0])
	for line in lines.slice(1):
		var cells := CatalogCsvTable._parse_csv_line(line)
		var row := {}
		for index in header.size(): row[header[index]] = cells[index] if index < cells.size() else ""
		rows.append(row)
	return rows

static func parse(skill_csv: String, pattern_csv: String) -> Dictionary:
	var result := {}
	var id_pattern := RegEx.create_from_string("^[a-z][a-z0-9_]*$")
	for row in parse_rows(skill_csv):
		if String(row.get("runtime_enabled", "")).to_lower() not in ["true", "1"]: continue
		var id := String(row.get("skill_id", ""))
		if id_pattern.search(id) == null or result.has(id): return {&"error":"스킬 ID 중복 또는 형식 오류"}
		var values := {}
		for key in ["cooldown_seconds", "energy_cost", "maximum_charges", "charge_recovery_seconds"]:
			if not row.has(key) or not String(row[key]).is_valid_float(): return {&"error":"스킬 숫자 형식 오류"}
			values[key] = float(row[key])
		if values.maximum_charges != floor(values.maximum_charges) or values.maximum_charges > 10: return {&"error":"충전 횟수 범위 오류"}
		result[id] = values
	if result.is_empty(): return {&"error":"활성 스킬 목록 없음"}
	var seen := {}
	for row in parse_rows(pattern_csv):
		var id := String(row.get("skill_id", ""))
		if id in ["", "스킬 ID"]: continue
		if id_pattern.search(id) == null or seen.has(id): return {&"error":"패턴 ID 중복 또는 형식 오류"}
		seen[id] = true
		if not result.has(id): continue
		var effect := {}
		var allowed: Dictionary = TacticalPatternEffect.new().get_parameters()
		for key in allowed:
			if not row.has(String(key)): return {&"error":"효과 필수 열 누락"}
			var value := String(row[String(key)])
			if key in [&"shape", &"status_id", &"consume_status_id"]: effect[String(key)] = value
			elif key in [&"follow_player", &"anchor_on_target"]:
				if value.to_lower() not in ["true", "false"]: return {&"error":"효과 불리언 오류"}
				effect[String(key)] = value.to_lower() == "true"
			else:
				if not value.is_valid_float(): return {&"error":"효과 숫자 형식 오류"}
				effect[String(key)] = float(value)
				if key in [&"pulses", &"maximum_targets"] and float(value) != floor(float(value)): return {&"error":"효과 횟수는 정수 필요"}
		result[id]["effect"] = effect
	for id in result:
		var path := "res://game/features/combat_skills/definitions/%s.tres" % id
		if not ResourceLoader.exists(path) or apply(load(path), result[id]) == null:
			return {&"error":"미구현 또는 유효하지 않은 스킬: " + id}
		if load(path).effect is TacticalPatternEffect and not result[id].has("effect"):
			return {&"error":"활성 스킬 효과 행 누락: " + id}
	return {&"values":result}
