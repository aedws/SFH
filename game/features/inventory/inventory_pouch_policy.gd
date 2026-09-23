class_name InventoryPouchPolicy
extends RefCounted
## Pure ownership/geometry rules. No wallet, UI, settlement or filesystem access.
const Records = preload("res://game/features/inventory/inventory_reserve_policy.gd")
const ALLOWED := [&"blueprint", &"rune", &"core", &"artifact"]

static func accepts(definition: InventoryItemDefinition) -> bool:
	return definition != null and definition.is_valid() and definition.item_type in ALLOWED and not (definition.linked_resource is EquipmentWeaponDefinition or definition.linked_resource is EquipmentArmorDefinition or definition.linked_resource is EquipmentModuleDefinition or definition.linked_resource is EquipmentPartDefinition)

static func position_for(entries: Dictionary, size: Vector2i, dimensions: Vector2i, ignore: StringName = &"") -> Vector2i:
	for y in range(dimensions.y - size.y + 1):
		for x in range(dimensions.x - size.x + 1):
			if fits(entries, Rect2i(Vector2i(x, y), size), dimensions, ignore): return Vector2i(x, y)
	return Vector2i(-1, -1)

static func fits(entries: Dictionary, candidate: Rect2i, dimensions: Vector2i, ignore: StringName = &"") -> bool:
	if not Rect2i(Vector2i.ZERO, dimensions).encloses(candidate): return false
	for id in entries:
		if id != ignore and candidate.intersects(Rect2i(entries[id].position, Records.size_of(entries[id]))): return false
	return true

static func validation_errors(value: Variant, dimensions: Variant, active: Dictionary, reserve: Dictionary) -> PackedStringArray:
	var errors := Records.validation_errors(value, active)
	if not dimensions is Vector2i or dimensions.x <= 0 or dimensions.y <= 0 or dimensions.x > 12 or dimensions.y > 12:
		errors.append("보호 주머니 크기 오류")
		return errors
	if not errors.is_empty(): return errors
	for id in value:
		var entry: Dictionary = value[id]
		if reserve.has(id): errors.append("보관소와 보호 주머니 실물 중복")
		if not accepts(entry.definition): errors.append("보호 주머니 수납 불가 종류")
		if not fits(value, Rect2i(entry.position, Records.size_of(entry)), dimensions, id): errors.append("보호 주머니 경계/겹침 오류")
	return errors
