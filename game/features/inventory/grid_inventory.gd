class_name GridInventory
extends Node

signal inventory_changed(snapshot: Dictionary)

var grid_size := Vector2i.ZERO
var items: Dictionary = {}
var placements: Dictionary = {}
var serials: Dictionary = {}
var runtime_payloads: Dictionary = {}
var item_definitions_by_resource: Dictionary = {}
var item_definitions_by_id: Dictionary = {}


func configure(catalog: InventoryCatalog) -> bool:
	if catalog == null or not catalog.validation_errors().is_empty():
		push_error("유효한 InventoryCatalog가 필요합니다.")
		return false
	grid_size = catalog.grid_size
	items.clear()
	placements.clear()
	serials.clear()
	runtime_payloads.clear()
	item_definitions_by_resource.clear()
	item_definitions_by_id.clear()
	for definition in catalog.items:
		item_definitions_by_id[definition.item_id] = definition
		if definition.linked_resource != null:
			item_definitions_by_resource[_resource_key(definition.linked_resource)] = definition
	for definition in catalog.items:
		if add_item(definition) == &"":
			push_error("인벤토리에 초기 아이템을 배치하지 못했습니다: %s" % definition.display_name)
			return false
	inventory_changed.emit(get_snapshot())
	return true


func add_item(
	definition: InventoryItemDefinition,
	preferred_position: Vector2i = Vector2i(-1, -1)
) -> StringName:
	return add_item_with_payload(definition, {}, preferred_position)


func add_item_with_payload(
	definition: InventoryItemDefinition,
	runtime_payload: Dictionary = {},
	preferred_position: Vector2i = Vector2i(-1, -1)
) -> StringName:
	if definition == null or not definition.is_valid():
		return &""
	var position := preferred_position
	if position.x < 0 or position.y < 0:
		position = find_first_space(definition.grid_size)
	if position.x < 0 or not can_place(definition.grid_size, position):
		return &""
	var instance_id := _next_instance_id(definition.item_id)
	items[instance_id] = definition
	placements[instance_id] = position
	runtime_payloads[instance_id] = runtime_payload.duplicate(true)
	inventory_changed.emit(get_snapshot())
	return instance_id


func get_item_definition(item_id: StringName) -> InventoryItemDefinition:
	return item_definitions_by_id.get(item_id) as InventoryItemDefinition


func can_add_catalog_items(item_id: StringName, quantity: int) -> bool:
	var definition := get_item_definition(item_id)
	if definition == null or quantity <= 0:
		return false
	var occupied: Array[Rect2i] = []
	for instance_id in placements:
		var current := items[instance_id] as InventoryItemDefinition
		occupied.append(Rect2i(placements[instance_id], current.grid_size))
	var bounds := Rect2i(Vector2i.ZERO, grid_size)
	for _index in quantity:
		var placement := Vector2i(-1, -1)
		for y in range(grid_size.y - definition.grid_size.y + 1):
			for x in range(grid_size.x - definition.grid_size.x + 1):
				var candidate := Rect2i(Vector2i(x, y), definition.grid_size)
				if not bounds.encloses(candidate):
					continue
				var blocked := false
				for other in occupied:
					if candidate.intersects(other):
						blocked = true
						break
				if not blocked:
					placement = candidate.position
					occupied.append(candidate)
					break
			if placement.x >= 0:
				break
		if placement.x < 0:
			return false
	return true


func add_catalog_item(
	item_id: StringName,
	runtime_payload: Dictionary = {},
	preferred_position: Vector2i = Vector2i(-1, -1)
) -> StringName:
	return add_item_with_payload(
		get_item_definition(item_id), runtime_payload, preferred_position
	)


func remove_item_instances(instance_ids: Array) -> bool:
	var removed_any := false
	for value in instance_ids:
		var instance_id := StringName(value)
		if not items.has(instance_id):
			continue
		items.erase(instance_id)
		placements.erase(instance_id)
		runtime_payloads.erase(instance_id)
		removed_any = true
	if removed_any:
		inventory_changed.emit(get_snapshot())
	return removed_any


func add_linked_resource(
	linked_resource: Resource,
	runtime_payload: Dictionary = {},
	preferred_position: Vector2i = Vector2i(-1, -1)
) -> StringName:
	var definition := _inventory_definition_for_resource(linked_resource)
	if definition == null:
		return &""
	var instance_id := add_item_with_payload(definition, runtime_payload, preferred_position)
	if instance_id != &"":
		item_definitions_by_id[definition.item_id] = definition
	return instance_id


func can_add_linked_resource(
	linked_resource: Resource,
	removing_instance_id: StringName = &""
) -> bool:
	var definition := _inventory_definition_for_resource(linked_resource)
	return (
		definition != null
		and _find_first_space_ignoring(definition.grid_size, removing_instance_id).x >= 0
	)


func can_place(
	item_size: Vector2i,
	position: Vector2i,
	ignore_instance_id: StringName = &""
) -> bool:
	var candidate := Rect2i(position, item_size)
	var bounds := Rect2i(Vector2i.ZERO, grid_size)
	if not bounds.encloses(candidate):
		return false
	for instance_id in placements:
		if instance_id == ignore_instance_id:
			continue
		var definition := items[instance_id] as InventoryItemDefinition
		var occupied := Rect2i(placements[instance_id], definition.grid_size)
		if candidate.intersects(occupied):
			return false
	return true


func find_first_space(item_size: Vector2i) -> Vector2i:
	for y in range(grid_size.y - item_size.y + 1):
		for x in range(grid_size.x - item_size.x + 1):
			var candidate := Vector2i(x, y)
			if can_place(item_size, candidate):
				return candidate
	return Vector2i(-1, -1)


func move_item(instance_id: StringName, new_position: Vector2i) -> bool:
	if not items.has(instance_id):
		return false
	var definition := items[instance_id] as InventoryItemDefinition
	if not can_place(definition.grid_size, new_position, instance_id):
		return false
	placements[instance_id] = new_position
	inventory_changed.emit(get_snapshot())
	return true


func take_item(instance_id: StringName) -> InventoryItemDefinition:
	var entry := take_item_entry(instance_id)
	return entry.get(&"definition") as InventoryItemDefinition


func take_item_entry(instance_id: StringName) -> Dictionary:
	if not items.has(instance_id):
		return {}
	var definition := items[instance_id] as InventoryItemDefinition
	var result := {
		&"definition": definition,
		&"runtime_payload": (runtime_payloads.get(instance_id, {}) as Dictionary).duplicate(true),
	}
	items.erase(instance_id)
	placements.erase(instance_id)
	runtime_payloads.erase(instance_id)
	inventory_changed.emit(get_snapshot())
	return result


func get_runtime_payload(instance_id: StringName) -> Dictionary:
	return (runtime_payloads.get(instance_id, {}) as Dictionary).duplicate(true)


func get_items_by_type(item_type: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for entry in get_snapshot()[&"items"]:
		if entry[&"item_type"] == item_type:
			result.append(entry)
	return result


func find_instance_ids_by_resource(linked_resource: Resource) -> PackedStringArray:
	var result := PackedStringArray()
	if linked_resource == null:
		return result
	for instance_id in items:
		var definition := items[instance_id] as InventoryItemDefinition
		if definition.linked_resource == linked_resource:
			result.append(String(instance_id))
	return result


func consume_linked_resource(linked_resource: Resource, amount: int = 1) -> bool:
	if amount <= 0:
		return true
	var instance_ids := find_instance_ids_by_resource(linked_resource)
	if instance_ids.size() < amount:
		return false
	for index in range(amount):
		take_item(instance_ids[index])
	return true


func get_snapshot() -> Dictionary:
	var item_snapshots: Array[Dictionary] = []
	for instance_id in items:
		var definition := items[instance_id] as InventoryItemDefinition
		item_snapshots.append({
			&"instance_id": instance_id,
			&"item_id": definition.item_id,
			&"display_name": definition.display_name,
			&"item_type": definition.item_type,
			&"grid_size": definition.grid_size,
			&"position": placements[instance_id],
			&"panel_color": definition.panel_color,
			&"description": definition.description,
			&"linked_resource": definition.linked_resource,
			&"runtime_payload": get_runtime_payload(instance_id),
		})
	return {&"grid_size": grid_size, &"items": item_snapshots}


func export_runtime_state() -> Dictionary:
	return {
		&"grid_size": grid_size,
		&"items": items.duplicate(true),
		&"placements": placements.duplicate(true),
		&"serials": serials.duplicate(true),
		&"runtime_payloads": runtime_payloads.duplicate(true),
	}


func validate_runtime_state(saved: Dictionary) -> PackedStringArray:
	var errors := PackedStringArray()
	if saved.is_empty():
		return errors
	var saved_size: Vector2i = saved.get(&"grid_size", Vector2i.ZERO)
	var saved_items: Dictionary = saved.get(&"items", {})
	var saved_placements: Dictionary = saved.get(&"placements", {})
	if saved_size.x <= 0 or saved_size.y <= 0:
		errors.append("가방 격자 크기가 유효하지 않습니다.")
		return errors
	if saved_items.size() != saved_placements.size():
		errors.append("가방 아이템과 배치 정보 수가 다릅니다.")
		return errors
	var occupied: Array[Rect2i] = []
	var bounds := Rect2i(Vector2i.ZERO, saved_size)
	for instance_id in saved_items:
		var definition := saved_items[instance_id] as InventoryItemDefinition
		if definition == null or not definition.is_valid() or not saved_placements.has(instance_id):
			errors.append("가방 아이템 정의 또는 위치가 유효하지 않습니다: %s" % instance_id)
			continue
		var rect := Rect2i(saved_placements[instance_id], definition.grid_size)
		if not bounds.encloses(rect):
			errors.append("가방 아이템이 격자 밖에 배치됐습니다: %s" % instance_id)
		for other in occupied:
			if rect.intersects(other):
				errors.append("가방 아이템 배치가 서로 겹칩니다: %s" % instance_id)
				break
		occupied.append(rect)
	return errors


func validate_operation_launch(request: Dictionary) -> PackedStringArray:
	return validate_runtime_state(request.get(&"runtime_context", {}).get(&"inventory_state", {}))


func restore_runtime_state(saved: Dictionary) -> bool:
	if not validate_runtime_state(saved).is_empty():
		return false
	var saved_size: Vector2i = saved.get(&"grid_size", Vector2i.ZERO)
	var saved_items: Dictionary = saved.get(&"items", {})
	var saved_placements: Dictionary = saved.get(&"placements", {})
	if saved_size.x <= 0 or saved_size.y <= 0 or saved_items.size() != saved_placements.size():
		return false
	grid_size = saved_size
	items = saved_items.duplicate(true)
	placements = saved_placements.duplicate(true)
	serials = (saved.get(&"serials", {}) as Dictionary).duplicate(true)
	runtime_payloads = (saved.get(&"runtime_payloads", {}) as Dictionary).duplicate(true)
	for instance_id in items:
		if not runtime_payloads.has(instance_id):
			runtime_payloads[instance_id] = {}
	inventory_changed.emit(get_snapshot())
	return true


func _next_instance_id(item_id: StringName) -> StringName:
	var next_serial := int(serials.get(item_id, 0)) + 1
	serials[item_id] = next_serial
	return StringName("%s_%d" % [item_id, next_serial])


func _find_first_space_ignoring(
	item_size: Vector2i,
	ignore_instance_id: StringName
) -> Vector2i:
	for y in range(grid_size.y - item_size.y + 1):
		for x in range(grid_size.x - item_size.x + 1):
			var candidate := Vector2i(x, y)
			if can_place(item_size, candidate, ignore_instance_id):
				return candidate
	return Vector2i(-1, -1)


func _inventory_definition_for_resource(linked_resource: Resource) -> InventoryItemDefinition:
	if linked_resource == null:
		return null
	var key := _resource_key(linked_resource)
	if item_definitions_by_resource.has(key):
		return item_definitions_by_resource[key] as InventoryItemDefinition
	var definition := InventoryItemDefinition.new()
	definition.linked_resource = linked_resource
	definition.display_name = String(linked_resource.get("display_name"))
	definition.panel_color = Color(0.28, 0.72, 0.66, 1.0)
	if linked_resource is EquipmentWeaponDefinition:
		var weapon := linked_resource as EquipmentWeaponDefinition
		definition.item_id = weapon.weapon_id
		definition.item_type = &"weapon"
		definition.grid_size = Vector2i(2, 2) if weapon.tags.minor_tag == &"pistol" else Vector2i(3, 2)
		definition.description = weapon.description
	elif linked_resource is EquipmentArmorDefinition:
		var armor := linked_resource as EquipmentArmorDefinition
		definition.item_id = armor.armor_id
		definition.item_type = &"armor"
		definition.grid_size = Vector2i(2, 3)
		definition.description = armor.description
	elif linked_resource is EquipmentModuleDefinition:
		definition.item_id = (linked_resource as EquipmentModuleDefinition).module_id
		definition.item_type = &"module"
		definition.grid_size = Vector2i.ONE
		definition.description = "장비 코스트를 사용하는 능력 모듈"
	elif linked_resource is EquipmentPartDefinition:
		definition.item_id = (linked_resource as EquipmentPartDefinition).part_id
		definition.item_type = &"part"
		definition.grid_size = Vector2i.ONE
		definition.description = "무기 소분류와 소켓이 일치해야 하는 고유 파츠"
	else:
		return null
	item_definitions_by_resource[key] = definition
	return definition


func _resource_key(linked_resource: Resource) -> String:
	if not linked_resource.resource_path.is_empty():
		return linked_resource.resource_path
	return "%s:%s" % [linked_resource.get_class(), linked_resource.get_instance_id()]
