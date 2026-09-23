class_name InventoryReservePolicy
extends RefCounted
## Pure capacity migration. Overflow keeps the original instance, never becomes a quantity.

static func copy_value(value: Variant) -> Variant:
	if value is Resource: return value.duplicate(true)
	if value is Dictionary:
		var result := {}
		for key in value: result[key] = copy_value(value[key])
		return result
	if value is Array:
		var result: Array = value.duplicate()
		for i in result.size(): result[i] = copy_value(result[i])
		return result
	return value


static func record(state: Dictionary, id: StringName) -> Dictionary:
	return copy_value({&"definition": state.items[id],
		&"runtime_payload": state.get(&"runtime_payloads", {}).get(id, {}),
		&"rotated": state.get(&"rotations", {}).get(id, false),
		&"position": state.placements[id]})


static func size_of(entry: Dictionary) -> Vector2i:
	var base: Vector2i = entry.definition.grid_size
	return Vector2i(base.y, base.x) if entry.rotated else base


static func resize(source: Dictionary, dimensions: Vector2i) -> Dictionary:
	if dimensions.x <= 0 or dimensions.y <= 0: return {}
	var result: Dictionary = copy_value(source)
	result.grid_size = dimensions
	result[&"reserve"] = result.get(&"reserve", {})
	var occupied: Array[Rect2i] = []
	var displaced: Array[StringName] = []
	var bounds := Rect2i(Vector2i.ZERO, dimensions)
	# Keep valid placements first; don't displace a neighbour merely due to iteration order.
	for id in result.items:
		var entry := record(result, id)
		var rect := Rect2i(entry.position, size_of(entry))
		if bounds.encloses(rect): occupied.append(rect)
		else: displaced.append(id)
	for id in displaced:
		var entry := record(result, id)
		var footprint := size_of(entry)
		var destination := first_space(dimensions, footprint, occupied)
		if destination.x >= 0:
			result.placements[id] = destination
			occupied.append(Rect2i(destination, footprint))
		else:
			result.reserve[id] = entry
			for key in [&"items", &"placements", &"rotations", &"runtime_payloads"]:
				if result.has(key): result[key].erase(id)
	return result


static func first_space(dimensions: Vector2i, footprint: Vector2i, occupied: Array[Rect2i]) -> Vector2i:
	for y in range(dimensions.y - footprint.y + 1):
		for x in range(dimensions.x - footprint.x + 1):
			var candidate := Rect2i(Vector2i(x, y), footprint)
			var blocked := false
			for other in occupied:
				if candidate.intersects(other):
					blocked = true
					break
			if not blocked: return candidate.position
	return Vector2i(-1, -1)


static func validation_errors(reserve: Variant, active: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if not reserve is Dictionary: return PackedStringArray(["실물 보관 구획 형식 오류"])
	for id in reserve:
		if not (id is String or id is StringName) or String(id).is_empty() or active.has(id):
			errors.append("보관 실물 ID 누락/중복")
		var entry: Variant = reserve[id]
		if not entry is Dictionary:
			errors.append("보관 실물 형식 오류")
			continue
		if not entry.get(&"definition") is InventoryItemDefinition or not entry.definition.is_valid():
			errors.append("보관 실물 정의 오류")
		if not entry.get(&"runtime_payload") is Dictionary or not entry.get(&"rotated") is bool or not entry.get(&"position") is Vector2i:
			errors.append("보관 실물 상태 오류")
	return errors
