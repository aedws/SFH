class_name SessionSocketInventoryAdapter
extends RefCounted
## Only this adapter knows the bag contract. Loot accounting remains external.
var bag: Node


func configure(provider: Node) -> bool:
	for method in [&"get_snapshot", &"add_item", &"take_item_entry", &"export_runtime_state", &"restore_runtime_state"]:
		if not is_instance_valid(provider) or not provider.has_method(method):
			return false
	bag = provider
	return true


func store(item_id: StringName, title: String, type: StringName, description: String) -> bool:
	if not is_instance_valid(bag):
		return false
	var definition := InventoryItemDefinition.new()
	definition.item_id = item_id
	definition.display_name = title
	definition.item_type = type
	definition.grid_size = Vector2i.ONE
	definition.description = description + " · 작전 한정 / 탈출 시 크레딧 전환"
	return StringName(bag.call(&"add_item", definition)) != &""


func first_owned(item_id: StringName) -> StringName:
	if is_instance_valid(bag):
		for entry: Dictionary in bag.call(&"get_snapshot").get(&"items", []):
			if StringName(entry.get(&"item_id", &"")) == item_id:
				return StringName(entry[&"instance_id"])
	return &""


func owns_instance(item_id: StringName, instance_id: StringName) -> bool:
	if is_instance_valid(bag) and instance_id != &"":
		for entry: Dictionary in bag.call(&"get_snapshot").get(&"items", []):
			if StringName(entry.get(&"instance_id", &"")) == instance_id:
				return StringName(entry.get(&"item_id", &"")) == item_id
	return false
