class_name InventorySlotButton
extends Button

signal item_dropped(instance_id: StringName)
var accepts_item: Callable


func _can_drop_data(_position: Vector2, data: Variant) -> bool:
	return not disabled and data is Dictionary and data.get(&"kind") == &"inventory_item" and accepts_item.is_valid() and accepts_item.call(data.get(&"instance_id", &""))


func _drop_data(_position: Vector2, data: Variant) -> void:
	item_dropped.emit(data[&"instance_id"])
