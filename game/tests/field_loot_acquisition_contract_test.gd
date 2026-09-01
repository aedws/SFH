extends SceneTree

class EquipmentStub:
	extends Node

	func get_summary() -> Dictionary:
		return {
			&"active_weapon_name": "돌격소총",
			&"active_weapon_grade": 2,
		}


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
		lifecycle
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
		&"configure", player, drops, ui, lifecycle, table, equipment, inventory, context, 7411
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
	print("FIELD_LOOT_ACQUISITION_OK spawn approach compare lifecycle cancel retain reacquire select run_storage viewport_safe modular_boundary")
	quit(0)


func _fail(message: String) -> void:
	failure = message
	push_error(message)
	quit(1)
