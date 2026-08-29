class_name GridInventory
extends Node

signal inventory_changed(snapshot: Dictionary)

var grid_size := Vector2i.ZERO
var items: Dictionary = {}
var placements: Dictionary = {}
var serials: Dictionary = {}


func configure(catalog: InventoryCatalog) -> bool:
	if catalog == null or not catalog.validation_errors().is_empty():
		push_error("유효한 InventoryCatalog가 필요합니다.")
		return false
	grid_size = catalog.grid_size
	items.clear()
	placements.clear()
	serials.clear()
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
	inventory_changed.emit(get_snapshot())
	return instance_id


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
	if not items.has(instance_id):
		return null
	var definition := items[instance_id] as InventoryItemDefinition
	items.erase(instance_id)
	placements.erase(instance_id)
	inventory_changed.emit(get_snapshot())
	return definition


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
		})
	return {&"grid_size": grid_size, &"items": item_snapshots}


func _next_instance_id(item_id: StringName) -> StringName:
	var next_serial := int(serials.get(item_id, 0)) + 1
	serials[item_id] = next_serial
	return StringName("%s_%d" % [item_id, next_serial])
