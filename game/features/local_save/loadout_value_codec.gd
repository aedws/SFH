class_name LoadoutValueCodec
extends RefCounted
## Only registered, shipped data Resources can be constructed. Save paths/scripts are never loaded.
const TYPES := {
	"item": "res://game/features/inventory/inventory_item_definition.gd",
	"loadout": "res://game/features/equipment/equipment_loadout.gd",
	"state": "res://game/features/equipment/equipment_item_state.gd",
	"weapon": "res://game/features/equipment/weapon_definition.gd",
	"armor": "res://game/features/equipment/armor_definition.gd",
	"skill": "res://game/features/equipment/skill_definition.gd",
	"tags": "res://game/features/equipment/weapon_tag_profile.gd",
	"slot": "res://game/features/equipment/equipment_slot_rule.gd",
	"modifier": "res://game/features/equipment/stat_modifier.gd",
	"module": "res://game/features/equipment/equipment_module_definition.gd",
	"module_instance": "res://game/features/equipment/equipment_module_instance.gd",
	"part": "res://game/features/equipment/equipment_part_definition.gd",
}
var error := ""
var remaining := 40000


func encode(value: Variant, depth: int = 0) -> Variant:
	if not _budget(depth):
		return null
	match typeof(value):
		TYPE_NIL, TYPE_BOOL, TYPE_STRING: return value
		TYPE_INT: return {"t": "int", "v": str(value)}
		TYPE_FLOAT:
			if is_finite(value): return value
		TYPE_STRING_NAME: return {"t": "name", "v": String(value)}
		TYPE_VECTOR2I: return {"t": "v2i", "v": [value.x, value.y]}
		TYPE_COLOR: return {"t": "color", "v": value.to_html(true)}
		TYPE_DICTIONARY:
			var pairs := []
			for key in value:
				pairs.append([encode(key, depth + 1), encode(value[key], depth + 1)])
			return {"t": "dict", "v": pairs}
		TYPE_ARRAY, TYPE_PACKED_STRING_ARRAY, TYPE_PACKED_INT32_ARRAY:
			var entries := []
			for item in value: entries.append(encode(item, depth + 1))
			return {"t": "array", "v": entries}
		TYPE_OBJECT:
			if value is Resource and value.get_script() != null:
				var type_id: Variant = TYPES.find_key(value.get_script().resource_path)
				if type_id != null:
					var fields := {}
					for field in value.get_property_list():
						if field.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and field.usage & PROPERTY_USAGE_STORAGE:
							fields[field.name] = encode(value.get(field.name), depth + 1)
					return {"t": "resource", "type": type_id, "v": fields}
	error = "등록되지 않은 저장 데이터 형식입니다."
	return null


func decode(value: Variant, depth: int = 0) -> Variant:
	if not _budget(depth): return null
	if value == null or value is bool or value is String: return value
	if value is float or value is int:
		if is_finite(float(value)): return value
	if not value is Dictionary or not value.has("t"):
		return _invalid()
	var data: Variant = value.get("v")
	match value["t"]:
		"int":
			if data is String and data.is_valid_int(): return int(data)
		"name":
			if data is String: return StringName(data)
		"v2i":
			if data is Array and data.size() == 2 and _number(data[0]) and _number(data[1]):
				return Vector2i(int(data[0]), int(data[1]))
		"color":
			if data is String and Color.html_is_valid(data): return Color.html(data)
		"array":
			if data is Array:
				var entries := []
				for item in data: entries.append(decode(item, depth + 1))
				return entries
		"dict":
			if data is Array:
				var result := {}
				for pair in data:
					if not pair is Array or pair.size() != 2: return _invalid()
					var key: Variant = decode(pair[0], depth + 1)
					if not (key is String or key is StringName or key is int): return _invalid()
					if result.has(key): return _invalid()
					result[key] = decode(pair[1], depth + 1)
				return result
		"resource":
			if data is Dictionary and TYPES.has(value.get("type")):
				var resource: Resource = load(TYPES[value["type"]]).new()
				var fields := {}
				for field in resource.get_property_list():
					if field.usage & PROPERTY_USAGE_SCRIPT_VARIABLE and field.usage & PROPERTY_USAGE_STORAGE:
						fields[field.name] = field
				for key in data:
					if not fields.has(key): return _invalid()
					var decoded: Variant = decode(data[key], depth + 1)
					if not error.is_empty(): return null
					var current: Variant = resource.get(key)
					if current is Array:
						if not decoded is Array: return _invalid()
						for entry in decoded:
							if current.is_typed() and not _array_accepts(current, entry): return _invalid()
						current.assign(decoded)
						decoded = current
					elif fields[key].type == TYPE_OBJECT:
						if decoded != null and not decoded is Resource: return _invalid()
						var class_id: String = fields[key].class_name
						if decoded != null and not class_id.is_empty() and class_id != "Resource":
							if decoded.get_script().get_global_name() != class_id: return _invalid()
					elif current is PackedInt32Array:
						if not decoded is Array: return _invalid()
						for entry in decoded:
							if not entry is int: return _invalid()
						decoded = PackedInt32Array(decoded)
					elif current is PackedStringArray:
						if not decoded is Array: return _invalid()
						for entry in decoded:
							if not entry is String: return _invalid()
						decoded = PackedStringArray(decoded)
					elif typeof(current) != typeof(decoded):
						if current is float and _number(decoded): decoded = float(decoded)
						else: return _invalid()
					resource.set(key, decoded)
				return resource
	return _invalid()


func _array_accepts(array: Array, value: Variant) -> bool:
	if array.get_typed_builtin() == TYPE_OBJECT:
		return value is Resource and is_instance_of(value, array.get_typed_script())
	return typeof(value) == array.get_typed_builtin()


func _number(value: Variant) -> bool:
	return (value is int or value is float) and is_finite(float(value))


func _budget(depth: int) -> bool:
	remaining -= 1
	if depth > 32 or remaining < 0:
		error = "저장 데이터 구조 제한을 초과했습니다."
	return error.is_empty()


func _invalid() -> Variant:
	error = "저장 데이터 구조를 검증하지 못했습니다."
	return null
