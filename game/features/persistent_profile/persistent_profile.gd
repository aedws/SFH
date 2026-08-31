class_name PersistentProfile
extends Node

signal profile_changed(snapshot: Dictionary)

var storage_path := "user://sfh_profile.json"
var persistence_enabled := true
var banked_credits := 5000
var unlock_ids: Array[StringName] = [&"operation_gate", &"region_ruined_city"]
var warehouse: Dictionary = {&"scrap": 8, &"field_medkit": 2}
var consumable_loadout: Array[StringName] = []
var blueprints: Dictionary = {&"assault_rifle_blueprint": 1}
var crafted_items: Array[Dictionary] = []
var unlocked_shop_offer_ids: Array[StringName] = []
var unlocked_skill_ids: Array[StringName] = [&"blink"]


func configure(new_storage_path: String, enable_persistence: bool = true) -> bool:
	storage_path = new_storage_path
	persistence_enabled = enable_persistence and not storage_path.is_empty()
	_reset_defaults()
	if persistence_enabled:
		_load()
	profile_changed.emit(get_snapshot())
	return true


func can_spend(amount: int) -> bool:
	return amount >= 0 and banked_credits >= amount


func spend(amount: int) -> bool:
	if not can_spend(amount):
		return false
	banked_credits -= amount
	_commit()
	return true


func add_credits(amount: int) -> int:
	var accepted := maxi(0, amount)
	banked_credits += accepted
	_commit()
	return accepted


func is_unlocked(unlock_id: StringName) -> bool:
	return unlock_id in unlock_ids


func unlock(unlock_id: StringName) -> bool:
	if unlock_id == &"" or is_unlocked(unlock_id):
		return false
	unlock_ids.append(unlock_id)
	_commit()
	return true


func register_shop_offer(offer_id: StringName) -> bool:
	if offer_id == &"" or offer_id in unlocked_shop_offer_ids:
		return false
	unlocked_shop_offer_ids.append(offer_id)
	_commit()
	return true


func is_shop_offer_registered(offer_id: StringName) -> bool:
	return offer_id == &"" or offer_id in unlocked_shop_offer_ids


func unlock_skill(skill_id: StringName) -> bool:
	if skill_id == &"" or skill_id in unlocked_skill_ids:
		return false
	unlocked_skill_ids.append(skill_id)
	_commit()
	return true


func add_warehouse_item(item_id: StringName, quantity: int = 1) -> int:
	if item_id == &"" or quantity <= 0:
		return 0
	warehouse[item_id] = int(warehouse.get(item_id, 0)) + quantity
	_commit()
	return quantity


func has_warehouse_item(item_id: StringName, quantity: int = 1) -> bool:
	return quantity >= 0 and int(warehouse.get(item_id, 0)) >= quantity


func take_warehouse_item(item_id: StringName, quantity: int = 1) -> bool:
	if quantity <= 0 or not has_warehouse_item(item_id, quantity):
		return false
	var remaining := int(warehouse.get(item_id, 0)) - quantity
	if remaining <= 0:
		warehouse.erase(item_id)
	else:
		warehouse[item_id] = remaining
	_commit()
	return true


func add_blueprint(blueprint_id: StringName, quantity: int = 1) -> int:
	if blueprint_id == &"" or quantity <= 0:
		return 0
	blueprints[blueprint_id] = int(blueprints.get(blueprint_id, 0)) + quantity
	_commit()
	return quantity


func consume_blueprint(blueprint_id: StringName) -> bool:
	if int(blueprints.get(blueprint_id, 0)) <= 0:
		return false
	blueprints[blueprint_id] = int(blueprints[blueprint_id]) - 1
	if int(blueprints[blueprint_id]) <= 0:
		blueprints.erase(blueprint_id)
	_commit()
	return true


func add_crafted_item(item: Dictionary) -> int:
	if item.is_empty():
		return -1
	crafted_items.append(item.duplicate(true))
	_commit()
	return crafted_items.size() - 1


func set_consumable_loadout(item_ids: Array[StringName], maximum_slots: int = 3) -> bool:
	if item_ids.size() > maximum_slots:
		return false
	var required: Dictionary = {}
	for item_id in item_ids:
		required[item_id] = int(required.get(item_id, 0)) + 1
	for item_id in required:
		if not has_warehouse_item(item_id, int(required[item_id])):
			return false
	consumable_loadout = item_ids.duplicate()
	_commit()
	return true


func consume_loadout_for_run() -> Array[StringName]:
	var consumed: Array[StringName] = []
	for item_id in consumable_loadout:
		if take_warehouse_item(item_id, 1):
			consumed.append(item_id)
	consumable_loadout.clear()
	_commit()
	return consumed


func get_snapshot() -> Dictionary:
	return {
		&"banked_credits": banked_credits,
		&"unlock_ids": unlock_ids.duplicate(),
		&"warehouse": warehouse.duplicate(true),
		&"consumable_loadout": consumable_loadout.duplicate(),
		&"blueprints": blueprints.duplicate(true),
		&"crafted_items": crafted_items.duplicate(true),
		&"unlocked_shop_offer_ids": unlocked_shop_offer_ids.duplicate(),
		&"unlocked_skill_ids": unlocked_skill_ids.duplicate(),
	}


func reset_profile(delete_storage: bool = false) -> void:
	_reset_defaults()
	if delete_storage and FileAccess.file_exists(storage_path):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(storage_path))
	_commit()


func _reset_defaults() -> void:
	banked_credits = 5000
	unlock_ids = [&"operation_gate", &"region_ruined_city"]
	warehouse = {&"scrap": 8, &"field_medkit": 2}
	consumable_loadout = []
	blueprints = {&"assault_rifle_blueprint": 1}
	crafted_items = []
	unlocked_shop_offer_ids = []
	unlocked_skill_ids = [&"blink"]


func _commit() -> void:
	if persistence_enabled:
		_save()
	profile_changed.emit(get_snapshot())


func _save() -> void:
	var file := FileAccess.open(storage_path, FileAccess.WRITE)
	if file == null:
		push_warning("영구 프로필 저장 파일을 열 수 없습니다: %s" % storage_path)
		return
	file.store_string(JSON.stringify({
		"banked_credits": banked_credits,
		"unlock_ids": Array(unlock_ids).map(func(value): return String(value)),
		"warehouse": _string_key_dictionary(warehouse),
		"consumable_loadout": Array(consumable_loadout).map(func(value): return String(value)),
		"blueprints": _string_key_dictionary(blueprints),
		"crafted_items": crafted_items,
		"unlocked_shop_offer_ids": Array(unlocked_shop_offer_ids).map(func(value): return String(value)),
		"unlocked_skill_ids": Array(unlocked_skill_ids).map(func(value): return String(value)),
	}))


func _load() -> void:
	if not FileAccess.file_exists(storage_path):
		return
	var file := FileAccess.open(storage_path, FileAccess.READ)
	var parsed = JSON.parse_string(file.get_as_text()) if file != null else null
	if not parsed is Dictionary:
		return
	banked_credits = maxi(0, int(parsed.get("banked_credits", banked_credits)))
	unlock_ids = _string_name_array(parsed.get("unlock_ids", []))
	warehouse = _string_name_key_dictionary(parsed.get("warehouse", {}))
	consumable_loadout = _string_name_array(parsed.get("consumable_loadout", []))
	blueprints = _string_name_key_dictionary(parsed.get("blueprints", {}))
	crafted_items = Array(parsed.get("crafted_items", []), TYPE_DICTIONARY, "", null)
	unlocked_shop_offer_ids = _string_name_array(parsed.get("unlocked_shop_offer_ids", []))
	unlocked_skill_ids = _string_name_array(parsed.get("unlocked_skill_ids", [&"blink"]))


func _string_key_dictionary(source: Dictionary) -> Dictionary:
	var result := {}
	for key in source:
		result[String(key)] = source[key]
	return result


func _string_name_key_dictionary(source: Dictionary) -> Dictionary:
	var result := {}
	for key in source:
		result[StringName(key)] = int(source[key])
	return result


func _string_name_array(source: Array) -> Array[StringName]:
	var result: Array[StringName] = []
	for value in source:
		result.append(StringName(value))
	return result
