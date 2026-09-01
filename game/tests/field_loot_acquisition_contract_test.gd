extends SceneTree

class EquipmentStub:
	extends Node
	var states := {}
	var active_slot: StringName = &"main"

	func _init() -> void:
		var state := EquipmentItemState.new()
		state.configure(&"test_main", load(
			"res://game/features/equipment/definitions/weapons/assault_rifle.tres"
		))
		states[&"main"] = state

	func get_summary() -> Dictionary:
		var state: EquipmentItemState = states.get(active_slot)
		return {
			&"active_weapon_name": state.definition.display_name if state != null else "없음",
			&"active_weapon_grade": state.definition.grade if state != null else 0,
			&"active_weapon_id": state.definition.weapon_id if state != null else &"",
		}

	func get_equipment_state(slot_id: StringName):
		return states.get(slot_id)

	func get_active_weapon_slot() -> StringName:
		return active_slot

	func take_equipment_state(slot_id: StringName):
		var result = states.get(slot_id)
		states.erase(slot_id)
		return result

	func equip_definition(slot_id: StringName, definition: Resource) -> bool:
		var state := EquipmentItemState.new()
		state.configure(StringName("test_%s" % definition.weapon_id), definition)
		states[slot_id] = state
		return true

	func equip_state(slot_id: StringName, state: EquipmentItemState) -> bool:
		states[slot_id] = state
		return true

	func set_active_weapon_slot(slot_id: StringName) -> bool:
		if not states.has(slot_id):
			return false
		active_slot = slot_id
		return true


class InventoryStub:
	extends Node

	func get_snapshot() -> Dictionary:
		return {
			&"grid_size": Vector2i(12, 8),
			&"items": [{&"item_id": &"armor_plate_item"}],
		}


var failure := ""


func _init() -> void:
	call_deferred(&"_run")


func _run() -> void:
	var lifecycle_scene := load(
		"res://game/features/loot_lifecycle/loot_lifecycle_service.tscn"
	) as PackedScene
	var table_scene := load(
		"res://game/features/loot_tables/loot_table_provider.tscn"
	) as PackedScene
	var service_scene := load(
		"res://game/features/field_loot/field_loot_acquisition_service.tscn"
	) as PackedScene
	if lifecycle_scene == null or table_scene == null or service_scene == null:
		return _fail("현장 전리품 계약 Scene을 불러오지 못했습니다.")
	var lifecycle := lifecycle_scene.instantiate()
	var table := table_scene.instantiate()
	var service := service_scene.instantiate()
	var player := Node2D.new()
	var drops := Node2D.new()
	var ui := CanvasLayer.new()
	var equipment := EquipmentStub.new()
	var inventory := InventoryStub.new()
	var equip_catalog := load(
		"res://game/features/field_loot/configs/default_field_loot_equipment.tres"
	) as FieldLootEquipCatalog
	for node in [lifecycle, table, service, player, drops, ui, equipment, inventory]:
		root.add_child(node)
	await process_frame
	if not lifecycle.call(
		&"configure", load("res://game/features/loot_lifecycle/configs/default_loot_lifecycle.tres")
	):
		return _fail("생명 주기 제공자를 구성하지 못했습니다.")
	if not table.call(
		&"configure",
		load("res://game/features/loot_tables/configs/default_loot_table.tres"),
		lifecycle,
		equip_catalog
	):
		return _fail("드랍 테이블 제공자를 구성하지 못했습니다.")
	var context := {
		&"region_id": &"ruined_city",
		&"difficulty_id": &"standard",
		&"map_size": &"small",
		&"high_grade_drop_multiplier": 1.0,
		&"boss_available": false,
	}
	if not service.call(
		&"configure", player, drops, ui, lifecycle, table, equipment, inventory, context, 7411,
		equip_catalog
	):
		return _fail("현장 전리품 서비스를 구성하지 못했습니다.")
	var drop: Node2D = service.call(&"spawn_from_source", Vector2.ZERO, &"room_reward", 1)
	if drop == null:
		return _fail("방 보상 출처에서 비교 전리품이 생성되지 않았습니다.")
	player.global_position = drop.global_position
	for _frame in range(3):
		await process_frame
	var preview: Dictionary = service.call(&"get_snapshot")
	var preview_panel: Dictionary = preview.get(&"panel", {})
	if (
		int(preview.get(&"active_drop_count", 0)) != 1
		or StringName(preview.get(&"focused_item_id", &"")) == &""
		or not bool(preview_panel.get(&"visible", false))
		or not bool(preview_panel.get(&"has_comparison", false))
		or not bool(preview_panel.get(&"shows_extract_result", false))
		or not bool(preview_panel.get(&"shows_cancel_and_select", false))
		or not bool(preview_panel.get(&"viewport_safe", false))
	):
		return _fail("접근 시 비교·보존·입력 UI 계약이 충족되지 않았습니다: %s" % preview)
	if not service.call(&"cancel_preview"):
		return _fail("비교 패널 보류가 동작하지 않았습니다.")
	var cancelled: Dictionary = service.call(&"get_snapshot")
	if (
		int(cancelled.get(&"active_drop_count", 0)) != 1
		or int(cancelled.get(&"total_cancelled", 0)) != 1
		or bool((cancelled.get(&"panel", {}) as Dictionary).get(&"visible", true))
	):
		return _fail("보류가 전리품을 유지하면서 패널만 닫지 못했습니다: %s" % cancelled)
	player.global_position = Vector2(500.0, 0.0)
	drop.call(&"_process", 0.0)
	player.global_position = drop.global_position
	drop.call(&"_process", 0.0)
	if not service.call(&"acquire_focused"):
		return _fail("재접근 뒤 현장 전리품을 획득하지 못했습니다.")
	await process_frame
	var acquired: Dictionary = service.call(&"get_snapshot")
	if (
		int(acquired.get(&"active_drop_count", -1)) != 0
		or int(acquired.get(&"total_acquired", 0)) != 1
		or (acquired.get(&"acquired_items", {}) as Dictionary).is_empty()
		or not bool(acquired.get(&"separate_from_equipment_mutation", false))
		or not bool(acquired.get(&"lifecycle_linked", false))
		or not bool(acquired.get(&"table_linked", false))
	):
		return _fail("획득·런 임시 보관·모듈 경계 계약이 충족되지 않았습니다: %s" % acquired)
	var equip_drop: Node2D = service.call(&"spawn_candidate", Vector2.ZERO, {
		&"entry_id": &"test_pulse", &"item_id": &"pulse_rifle", &"grade": 3,
		&"quantity": 1, &"source_type": &"room_reward",
	})
	if equip_drop == null:
		return _fail("현장 장착 후보를 생성하지 못했습니다.")
	player.global_position = equip_drop.global_position
	equip_drop.call(&"_process", 0.0)
	var equip_preview: Dictionary = service.call(&"get_snapshot")
	if not bool((equip_preview.get(&"panel", {}) as Dictionary).get(&"shows_immediate_equip", false)):
		return _fail("즉시 장착 선택지가 플레이어에게 노출되지 않았습니다.")
	if not service.call(&"equip_focused"):
		return _fail("현장 무기 즉시 장착에 실패했습니다.")
	var equipped: Dictionary = service.call(&"get_snapshot")
	var immediate: Dictionary = equipped.get(&"immediate_equip", {})
	if (
		equipment.get_summary().get(&"active_weapon_id", &"") != &"pulse_rifle"
		or int(immediate.get(&"pending_swap_count", 0)) != 1
		or (immediate.get(&"policy", {}) as Dictionary).get(&"policy_status", &"") != &"provisional"
	):
		return _fail("즉시 장착·임시 정책·교체 기록 계약이 충족되지 않았습니다: %s" % equipped)
	if int(service.call(&"restore_equipment_swaps")) != 1:
		return _fail("거점 복귀용 장비 복구가 동작하지 않았습니다.")
	if equipment.get_summary().get(&"active_weapon_id", &"") != &"assault_rifle":
		return _fail("거점 복귀 전에 원래 장비가 복구되지 않았습니다.")
	print("FIELD_LOOT_ACQUISITION_OK spawn approach compare lifecycle cancel retain reacquire select run_storage immediate_equip provisional_policy restore_on_hub viewport_safe modular_boundary")
	quit(0)


func _fail(message: String) -> void:
	failure = message
	push_error(message)
	quit(1)
