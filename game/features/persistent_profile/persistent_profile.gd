class_name PersistentProfile
extends Node

signal profile_changed(snapshot: Dictionary)

var storage_path := "user://sfh_profile.json"
var persistence_enabled := true
var safe_persistence := false
var storage_error := ""
var save_store = preload("res://game/core/persistence/atomic_json_store.gd").new()
var banked_credits := 5000
var unlock_ids: Array[StringName] = [&"operation_gate", &"region_ruined_city"]
var warehouse: Dictionary = {&"scrap": 8, &"field_medkit": 2}
var consumable_loadout: Array[StringName] = []
var blueprints: Dictionary = {&"assault_rifle_blueprint": 1}
var crafted_items: Array[Dictionary] = []
var unlocked_shop_offer_ids: Array[StringName] = []
var unlocked_skill_ids: Array[StringName] = [&"blink"]
var registered_blueprint_ids: Array[StringName] = []
var codex_progress: Dictionary = {}
var processed_transaction_ids: Array[StringName] = []


func configure(new_storage_path: String, enable_persistence: bool = true, use_safe_storage: bool = false) -> bool:
	storage_path = new_storage_path
	persistence_enabled = enable_persistence and not storage_path.is_empty()
	safe_persistence = use_safe_storage
	storage_error = ""
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


func remove_crafted_item(instance_id: StringName) -> bool:
	if instance_id == &"":
		return false
	for index in crafted_items.size():
		if StringName(crafted_items[index].get(&"instance_id", &"")) == instance_id:
			crafted_items.remove_at(index)
			_commit()
			return true
	return false


func register_blueprint(blueprint_id: StringName) -> bool:
	if blueprint_id == &"" or blueprint_id in registered_blueprint_ids:
		return false
	registered_blueprint_ids.append(blueprint_id)
	_commit()
	return true


func is_blueprint_registered(blueprint_id: StringName) -> bool:
	return blueprint_id != &"" and blueprint_id in registered_blueprint_ids


func add_codex_progress(entry_id: StringName, quantity: int = 1) -> int:
	if entry_id == &"" or quantity <= 0:
		return int(codex_progress.get(entry_id, 0))
	codex_progress[entry_id] = int(codex_progress.get(entry_id, 0)) + quantity
	_commit()
	return int(codex_progress[entry_id])


func get_codex_progress(entry_id: StringName) -> int:
	return int(codex_progress.get(entry_id, 0))


func has_processed_transaction(transaction_id: StringName) -> bool:
	return transaction_id != &"" and transaction_id in processed_transaction_ids


func mark_transaction_processed(transaction_id: StringName) -> bool:
	if transaction_id == &"" or has_processed_transaction(transaction_id):
		return false
	processed_transaction_ids.append(transaction_id)
	if processed_transaction_ids.size() > 128:
		processed_transaction_ids.pop_front()
	_commit()
	return true


func apply_economy_transaction(transaction_id: StringName, credit_delta: int,
		warehouse_deltas: Dictionary, crafted_item: Dictionary = {}) -> Dictionary:
	if transaction_id == &"" or has_processed_transaction(transaction_id):
		return {&"success": false, &"reason": "중복 거래"}
	var next_credits := banked_credits + credit_delta
	if next_credits < 0:
		return {&"success": false, &"reason": "크레딧 부족"}
	var next_warehouse := warehouse.duplicate(true)
	for raw_id in warehouse_deltas:
		var item_id := StringName(raw_id)
		var delta: Variant = warehouse_deltas[raw_id]
		if (
			item_id == &""
			or not (delta is int or delta is float)
			or (delta is float and not is_equal_approx(float(delta), roundf(float(delta))))
		):
			return {&"success": false, &"reason": "창고 거래 데이터 오류"}
		var next_quantity := int(next_warehouse.get(item_id, 0)) + int(delta)
		if next_quantity < 0:
			return {&"success": false, &"reason": "재료 부족"}
		if next_quantity == 0:
			next_warehouse.erase(item_id)
		else:
			next_warehouse[item_id] = next_quantity
	var next_crafted_items := crafted_items.duplicate(true)
	if not crafted_item.is_empty():
		var instance_id := StringName(crafted_item.get(&"instance_id", &""))
		if instance_id == &"":
			return {&"success": false, &"reason": "지급 아이템 데이터 오류"}
		for existing in next_crafted_items:
			if StringName(existing.get(&"instance_id", &"")) == instance_id:
				return {&"success": false, &"reason": "지급 인스턴스 중복"}
		next_crafted_items.append(crafted_item.duplicate(true))
	var next_transactions := processed_transaction_ids.duplicate()
	next_transactions.append(transaction_id)
	if next_transactions.size() > 128:
		next_transactions.pop_front()
	var previous_credits := banked_credits
	var previous_warehouse := warehouse
	var previous_crafted_items := crafted_items
	var previous_transactions := processed_transaction_ids
	banked_credits = next_credits
	warehouse = next_warehouse
	crafted_items = next_crafted_items
	processed_transaction_ids = next_transactions
	if not _commit():
		banked_credits = previous_credits
		warehouse = previous_warehouse
		crafted_items = previous_crafted_items
		processed_transaction_ids = previous_transactions
		return {&"success": false, &"reason": "영구 저장 실패"}
	return {
		&"success": true,
		&"transaction_id": transaction_id,
		&"balance_after": banked_credits,
		&"crafted_index": crafted_items.size() - 1 if not crafted_item.is_empty() else -1,
	}


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
		&"registered_blueprint_ids": registered_blueprint_ids.duplicate(),
		&"codex_progress": codex_progress.duplicate(true),
		&"processed_transaction_ids": processed_transaction_ids.duplicate(),
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
	registered_blueprint_ids = []
	codex_progress = {}
	processed_transaction_ids = []


func _commit() -> bool:
	if persistence_enabled and not _save():
		return false
	profile_changed.emit(get_snapshot())
	return true


func _save() -> bool:
	if safe_persistence:
		if not storage_error.is_empty(): return false
		if not save_store.write(storage_path, get_snapshot(), true):
			storage_error = save_store.last_error
			return false
		return true
	var file := FileAccess.open(storage_path, FileAccess.WRITE)
	if file == null:
		push_warning("영구 프로필 저장 파일을 열 수 없습니다: %s" % storage_path)
		return false
	file.store_string(JSON.stringify({
		"banked_credits": banked_credits,
		"unlock_ids": Array(unlock_ids).map(func(value): return String(value)),
		"warehouse": _string_key_dictionary(warehouse),
		"consumable_loadout": Array(consumable_loadout).map(func(value): return String(value)),
		"blueprints": _string_key_dictionary(blueprints),
		"crafted_items": crafted_items,
		"unlocked_shop_offer_ids": Array(unlocked_shop_offer_ids).map(func(value): return String(value)),
		"unlocked_skill_ids": Array(unlocked_skill_ids).map(func(value): return String(value)),
		"registered_blueprint_ids": Array(registered_blueprint_ids).map(func(value): return String(value)),
		"codex_progress": _string_key_dictionary(codex_progress),
		"processed_transaction_ids": Array(processed_transaction_ids).map(func(value): return String(value)),
	}))
	file.flush()
	var error := file.get_error()
	file.close()
	return error == OK


func _load() -> void:
	var parsed: Variant
	if safe_persistence:
		var stored: Dictionary = save_store.read(storage_path, true)
		if not stored.ok:
			storage_error = "영구 프로필 복원 실패 · 원본 보존"
			return
		if stored.status == "new": return
		parsed = stored.data
	else:
		if not FileAccess.file_exists(storage_path): return
		var file := FileAccess.open(storage_path, FileAccess.READ)
		parsed = JSON.parse_string(file.get_as_text()) if file != null else null
	if not parsed is Dictionary:
		return
	if not _valid_saved_profile(parsed):
		storage_error = "영구 프로필 형식 오류 · 원본 보존"
		return
	banked_credits = maxi(0, int(parsed.get("banked_credits", banked_credits)))
	unlock_ids = _string_name_array(parsed.get("unlock_ids", []))
	warehouse = _string_name_key_dictionary(parsed.get("warehouse", {}))
	consumable_loadout = _string_name_array(parsed.get("consumable_loadout", []))
	blueprints = _string_name_key_dictionary(parsed.get("blueprints", {}))
	crafted_items = Array(parsed.get("crafted_items", []), TYPE_DICTIONARY, "", null)
	unlocked_shop_offer_ids = _string_name_array(parsed.get("unlocked_shop_offer_ids", []))
	unlocked_skill_ids = _string_name_array(parsed.get("unlocked_skill_ids", [&"blink"]))
	registered_blueprint_ids = _string_name_array(parsed.get("registered_blueprint_ids", []))
	codex_progress = _string_name_key_dictionary(parsed.get("codex_progress", {}))
	processed_transaction_ids = _string_name_array(parsed.get("processed_transaction_ids", []))


func get_storage_status() -> Dictionary:
	return {"ok": storage_error.is_empty(), "message": storage_error, "path": storage_path}


func _valid_saved_profile(data: Dictionary) -> bool:
	if not (data.get("banked_credits") is float or data.get("banked_credits") is int): return false
	for key in ["warehouse", "blueprints", "codex_progress"]:
		if not data.get(key, {}) is Dictionary: return false
		for quantity in data.get(key, {}).values():
			if not (quantity is float or quantity is int): return false
	for key in ["unlock_ids", "consumable_loadout", "unlocked_shop_offer_ids", "unlocked_skill_ids", "registered_blueprint_ids", "processed_transaction_ids"]:
		if not data.get(key, []) is Array: return false
		for value in data.get(key, []):
			if not value is String: return false
	if not data.get("crafted_items", []) is Array: return false
	for item in data.get("crafted_items", []):
		if not item is Dictionary: return false
	return true


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
