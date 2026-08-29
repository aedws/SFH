class_name InventoryItemDefinition
extends Resource

@export var item_id: StringName
@export var display_name: String
@export var item_type: StringName
@export var grid_size := Vector2i.ONE
@export var panel_color := Color(0.2, 0.45, 0.5, 1.0)
@export var linked_resource: Resource
@export_multiline var description: String


func is_valid() -> bool:
	if item_id == &"" or display_name.is_empty() or item_type == &"":
		return false
	if grid_size.x <= 0 or grid_size.y <= 0:
		return false
	return item_type != &"module" or grid_size == Vector2i.ONE
