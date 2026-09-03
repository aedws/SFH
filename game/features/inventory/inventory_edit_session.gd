class_name InventoryEditSession
extends Node
## Owns a disconnected draft. UI never takes items out of the live bag.
signal changed
signal committed

const GRID_SCRIPT = preload("res://game/features/inventory/grid_inventory.gd")
var inventory: Node
var equipment: Node
var live_inventory: Node
var live_equipment: Node
var dirty := false
var conflicted := false
var applying := false
var error_message := ""


func configure(bag: Node, gear: Node = null) -> void:
	live_inventory = bag
	live_equipment = gear
	bag.inventory_changed.connect(_on_live_changed)
	if gear != null:
		gear.customization_changed.connect(_on_live_changed)


func begin() -> bool:
	if inventory != null:
		inventory.free()
	if equipment != null:
		equipment.free()
	inventory = GRID_SCRIPT.new()
	add_child(inventory)
	if not inventory.restore_runtime_state(live_inventory.export_runtime_state()):
		return false
	equipment = live_equipment.create_edit_copy(self) if live_equipment != null else null
	if equipment != null:
		add_child(equipment)
	dirty = false
	conflicted = false
	error_message = ""
	return live_equipment == null or equipment != null


func apply_equipment_modifiers(_modifiers: Dictionary) -> void:
	pass # Preview sink, intentionally disconnected from live HP/combat signals.


func move_item(instance_id: StringName, position: Vector2i) -> bool:
	if inventory.placements.get(instance_id) == position:
		return true
	if not inventory.move_item(instance_id, position):
		return _reject("이동 불가 · 다른 아이템과 겹치거나 가방 밖입니다.")
	return _changed()


func equip_item(instance_id: StringName, slot_id: StringName) -> bool:
	var entry := get_item_entry(instance_id)
	var definition: Resource = entry.get(&"linked_resource")
	if equipment == null or definition == null or not equipment.can_equip_definition(slot_id, definition):
		return _reject("장착 불가 · 무기/방어구 슬롯 태그가 맞지 않습니다.")
	var previous: Resource = equipment.get_equipment_state(slot_id)
	if previous != null and not inventory.can_add_linked_resource(previous.definition, instance_id):
		return _reject("기존 장비를 돌려놓을 가방 공간이 부족합니다.")
	var before := _checkpoint()
	var item: Dictionary = inventory.take_item_entry(instance_id)
	var saved: Resource = item.get(&"runtime_payload", {}).get(&"equipment_state")
	var runtime_payload: Dictionary = item.get(&"runtime_payload", {})
	var ok := bool(
		equipment.equip_state(slot_id, saved)
		if saved != null
		else equipment.equip_definition(slot_id, definition, runtime_payload)
	)
	if ok and previous != null:
		ok = inventory.add_linked_resource(previous.definition, {&"equipment_state": previous}) != &""
	return _finish_operation(ok, before)


func unequip_item(slot_id: StringName) -> bool:
	var state: Resource = equipment.get_equipment_state(slot_id) if equipment != null else null
	if state == null or not inventory.can_add_linked_resource(state.definition):
		return _reject("해제 불가 · 장비가 없거나 가방 공간이 부족합니다.")
	var before := _checkpoint()
	var removed: Resource = equipment.take_equipment_state(slot_id)
	return _finish_operation(inventory.add_linked_resource(removed.definition, {&"equipment_state": removed}) != &"", before)


func install_item(instance_id: StringName, slot_id: StringName) -> bool:
	var entry := get_item_entry(instance_id)
	var state: Resource = equipment.get_equipment_state(slot_id) if equipment != null else null
	var definition: Resource = entry.get(&"linked_resource")
	var kind: StringName = entry.get(&"item_type", &"")
	if state == null or definition == null or kind not in [&"module", &"part"]:
		return _reject("장착할 장비와 모듈/파츠를 먼저 선택하세요.")
	# Validate on an isolated state before taking anything from the draft bag.
	var preview: Resource = state.duplicate(true)
	preview.set_upgrade_balance_provider(state.upgrade_balance_provider)
	var runtime_payload: Dictionary = entry.get(&"runtime_payload", {})
	var level := int(runtime_payload.get(&"upgrade_level", 1))
	var valid := bool(
		preview.install_module(instance_id, definition, level, runtime_payload)
		if kind == &"module" else preview.install_part(definition, level)
	)
	if not valid or not preview.validation_errors().is_empty():
		return _reject("장착 불가 · 태그, 고유 소켓, 중복 또는 모듈 코스트를 확인하세요.")
	var before := _checkpoint()
	inventory.take_item_entry(instance_id)
	return _finish_operation(equipment.equip_state(slot_id, preview), before)


func remove_modification(slot_id: StringName, kind: StringName, item_id: StringName) -> bool:
	var state: Resource = equipment.get_equipment_state(slot_id) if equipment != null else null
	if state == null or kind not in [&"module", &"part"]:
		return false
	var preview: Resource = state.duplicate(true)
	var removed: Dictionary = preview.remove_module(item_id) if kind == &"module" else preview.remove_part(item_id)
	if removed.is_empty() or not inventory.can_add_linked_resource(removed.get(&"definition")):
		return _reject("해제할 아이템이 없거나 가방 공간이 부족합니다.")
	var before := _checkpoint()
	var ok := bool(equipment.equip_state(slot_id, preview))
	if ok:
		var payload: Dictionary = (
			removed.get(&"item_quality_payload", {}) as Dictionary
		).duplicate(true)
		payload[&"upgrade_level"] = removed.get(&"upgrade_level", 1)
		ok = inventory.add_linked_resource(removed[&"definition"], payload) != &""
	return _finish_operation(ok, before)


func commit() -> bool:
	if conflicted:
		return _reject("편집 중 원본이 변경됐습니다. 변경 취소 후 다시 열어 주세요.")
	var draft := _checkpoint()
	if not live_inventory.validate_runtime_state(draft[&"bag"]).is_empty():
		return _reject("가방 검증 실패 · 저장하지 않았습니다.")
	if live_equipment != null and not live_equipment.validate_runtime_state(draft[&"gear"]).is_empty():
		return _reject("장비 검증 실패 · 저장하지 않았습니다.")
	var previous_bag: Dictionary = live_inventory.export_runtime_state()
	var previous_gear: Dictionary = live_equipment.export_runtime_state() if live_equipment != null else {}
	applying = true
	var ok := bool(live_inventory.restore_runtime_state(draft[&"bag"]))
	if ok and live_equipment != null:
		ok = bool(live_equipment.restore_runtime_state(draft[&"gear"]))
	if not ok:
		live_inventory.restore_runtime_state(previous_bag)
		if live_equipment != null:
			live_equipment.restore_runtime_state(previous_gear)
	applying = false
	if not ok:
		return _reject("저장 실패 · 기존 세팅을 유지했습니다.")
	dirty = false
	error_message = "세팅 저장 완료 · 거점과 작전 사이에 유지됩니다."
	committed.emit()
	changed.emit()
	return true


func _on_live_changed(_snapshot: Dictionary) -> void:
	if not applying and inventory != null:
		conflicted = true


func get_item_entry(instance_id: StringName) -> Dictionary:
	for entry: Dictionary in inventory.get_snapshot()[&"items"]:
		if entry[&"instance_id"] == instance_id:
			return entry
	return {}


func _checkpoint() -> Dictionary:
	return {&"bag": inventory.export_runtime_state(), &"gear": equipment.export_runtime_state() if equipment != null else {}}


func _finish_operation(ok: bool, before: Dictionary) -> bool:
	if ok:
		return _changed()
	inventory.restore_runtime_state(before[&"bag"])
	if equipment != null:
		equipment.restore_runtime_state(before[&"gear"])
	return _reject("변경 실패 · 아이템과 기존 세팅을 보존했습니다.")


func _changed() -> bool:
	dirty = true
	error_message = "미저장 변경 · 탭을 나가기 전에 저장 여부를 선택하세요."
	changed.emit()
	return true


func _reject(message: String) -> bool:
	error_message = message
	changed.emit()
	return false
