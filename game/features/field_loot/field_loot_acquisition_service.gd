class_name FieldLootAcquisitionService
extends Node

signal drop_spawned(drop: Node2D, candidate: Dictionary)
signal preview_changed(visible: bool, comparison: Dictionary)
signal loot_acquired(item_id: StringName, quantity: int, snapshot: Dictionary)
signal loot_equipped(item_id: StringName, result: Dictionary, snapshot: Dictionary)
signal acquisition_cancelled(item_id: StringName)
signal interaction_availability_changed(available: bool, prompt: String)

const DROP_SCRIPT := preload("res://game/features/field_loot/field_loot_drop.gd")
const PANEL_SCRIPT := preload("res://game/features/field_loot/field_loot_comparison_panel.gd")

var player: Node2D
var drop_parent: Node2D
var lifecycle_provider: Node
var table_provider: Node
var comparison_service := FieldLootComparisonService.new()
var equip_service := FieldLootEquipService.new()
var equip_catalog: FieldLootEquipCatalog
var operation_context: Dictionary = {}
var run_seed := 0
var active_drops: Array[Node2D] = []
var focused_drop: Node2D
var acquired_items: Dictionary = {}
var panel: FieldLootComparisonPanel
var total_spawned := 0
var total_acquired := 0
var total_cancelled := 0


func configure(
	new_player: Node2D,
	new_drop_parent: Node2D,
	ui_parent: Node,
	new_lifecycle_provider: Node,
	new_table_provider: Node,
	equipment_provider: Node,
	inventory_provider: Node,
	new_operation_context: Dictionary,
	new_run_seed: int,
	new_equip_catalog: FieldLootEquipCatalog = null
) -> bool:
	if (
		not is_instance_valid(new_player)
		or not is_instance_valid(new_drop_parent)
		or not is_instance_valid(ui_parent)
		or not _supports(new_table_provider, [&"roll_drop"])
		or not comparison_service.configure(
			new_lifecycle_provider, equipment_provider, inventory_provider, new_equip_catalog
		)
	):
		return false
	player = new_player
	drop_parent = new_drop_parent
	lifecycle_provider = new_lifecycle_provider
	table_provider = new_table_provider
	operation_context = new_operation_context.duplicate(true)
	run_seed = new_run_seed
	equip_catalog = new_equip_catalog
	if equip_catalog != null and not equip_service.configure(equipment_provider, equip_catalog):
		return false
	acquired_items.clear()
	active_drops.clear()
	focused_drop = null
	total_spawned = 0
	total_acquired = 0
	total_cancelled = 0
	panel = PANEL_SCRIPT.new()
	ui_parent.add_child(panel)
	return true


func spawn_from_source(
	world_position: Vector2,
	source_type: StringName,
	roll_index: int
) -> Node2D:
	var context := operation_context.duplicate(true)
	context[&"source_type"] = source_type
	var candidate: Dictionary = table_provider.call(&"roll_drop", context, run_seed, roll_index)
	return spawn_candidate(world_position, candidate)


func spawn_candidate(world_position: Vector2, candidate: Dictionary) -> Node2D:
	if candidate.is_empty():
		return null
	var comparison := comparison_service.compare(candidate)
	if comparison.is_empty():
		return null
	var drop := DROP_SCRIPT.new() as Node2D
	drop_parent.add_child(drop)
	drop.global_position = world_position
	if not drop.call(&"configure", player, candidate, comparison):
		drop.queue_free()
		return null
	drop.connect(&"proximity_changed", Callable(self, &"_on_drop_proximity_changed"))
	active_drops.append(drop)
	total_spawned += 1
	drop_spawned.emit(drop, candidate.duplicate(true))
	return drop


func acquire_focused() -> bool:
	if not is_instance_valid(focused_drop):
		return false
	return _finalize_focused_acquisition(&"run_storage")


func equip_focused() -> bool:
	if not is_instance_valid(focused_drop) or equip_catalog == null:
		return false
	var comparison: Dictionary = focused_drop.get("comparison")
	var item_id := StringName(comparison.get(&"item_id", &""))
	var equip_result := equip_service.equip(item_id)
	if not bool(equip_result.get(&"success", false)):
		return false
	var completed := _finalize_focused_acquisition(&"equipped", equip_result)
	if completed:
		loot_equipped.emit(item_id, equip_result.duplicate(true), get_snapshot())
	return completed


func restore_equipment_swaps() -> int:
	return equip_service.restore_swaps() if equip_catalog != null else 0


func _finalize_focused_acquisition(mode: StringName, equip_result: Dictionary = {}) -> bool:
	var comparison: Dictionary = focused_drop.get("comparison")
	var item_id := StringName(comparison.get(&"item_id", &""))
	var quantity := maxi(1, int(comparison.get(&"quantity", 1)))
	var entry: Dictionary = acquired_items.get(item_id, {
		&"item_id": item_id,
		&"display_name": comparison.get(&"display_name", item_id),
		&"quantity": 0,
		&"highest_grade": 0,
		&"loot_family": comparison.get(&"family_label", ""),
		&"extract_result": comparison.get(&"extract_label", ""),
		&"death_result": comparison.get(&"death_label", ""),
	})
	entry[&"quantity"] = int(entry.get(&"quantity", 0)) + quantity
	entry[&"highest_grade"] = maxi(
		int(entry.get(&"highest_grade", 0)), int(comparison.get(&"candidate_grade", 1))
	)
	entry[&"last_acquisition_mode"] = mode
	if not equip_result.is_empty():
		entry[&"previous_item_name"] = equip_result.get(&"previous_name", "")
		entry[&"previous_destination"] = equip_result.get(&"previous_destination", &"")
	acquired_items[item_id] = entry
	var acquired_drop := focused_drop
	focused_drop = null
	active_drops.erase(acquired_drop)
	panel.hide_comparison()
	preview_changed.emit(false, {})
	interaction_availability_changed.emit(false, "")
	total_acquired += 1
	loot_acquired.emit(item_id, quantity, get_snapshot())
	acquired_drop.queue_free()
	return true


func cancel_preview() -> bool:
	if not is_instance_valid(focused_drop):
		return false
	var comparison: Dictionary = focused_drop.get("comparison")
	var item_id := StringName(comparison.get(&"item_id", &""))
	focused_drop = null
	panel.hide_comparison()
	preview_changed.emit(false, {})
	interaction_availability_changed.emit(false, "")
	total_cancelled += 1
	acquisition_cancelled.emit(item_id)
	return true


func get_active_drops() -> Array[Node2D]:
	_prune_drops()
	return active_drops.duplicate()


func get_panel() -> Control:
	return panel


func get_snapshot() -> Dictionary:
	_prune_drops()
	return {
		&"active_drop_count": active_drops.size(),
		&"focused_item_id": (
			StringName((focused_drop.get("comparison") as Dictionary).get(&"item_id", &""))
			if is_instance_valid(focused_drop) else &""
		),
		&"acquired_items": acquired_items.duplicate(true),
		&"total_spawned": total_spawned,
		&"total_acquired": total_acquired,
		&"total_cancelled": total_cancelled,
		&"panel": panel.get_snapshot() if is_instance_valid(panel) else {},
		&"separate_from_equipment_mutation": true,
		&"equipment_mutation_delegated": true,
		&"immediate_equip": equip_service.get_snapshot(),
		&"lifecycle_linked": is_instance_valid(lifecycle_provider),
		&"table_linked": is_instance_valid(table_provider),
	}


func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(focused_drop):
		return
	if event.is_action_pressed(&"interact"):
		if acquire_focused():
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"equip_field_loot"):
		if equip_focused():
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_cancel"):
		if cancel_preview():
			get_viewport().set_input_as_handled()


func _on_drop_proximity_changed(drop: Node2D, available: bool) -> void:
	if available:
		focused_drop = drop
		var comparison: Dictionary = drop.get("comparison")
		panel.show_comparison(comparison)
		preview_changed.emit(true, comparison.duplicate(true))
		interaction_availability_changed.emit(
			true,
			(
				"R · 즉시 장착 / F · 런 보관 / ESC · 보류"
				if not (comparison.get(&"equip_preview", {}) as Dictionary).is_empty()
				else "F · %s 획득 / ESC · 보류" % comparison.get(&"display_name", "전리품")
			)
		)
	elif focused_drop == drop:
		focused_drop = null
		panel.hide_comparison()
		preview_changed.emit(false, {})
		interaction_availability_changed.emit(false, "")


func _prune_drops() -> void:
	for index in range(active_drops.size() - 1, -1, -1):
		if not is_instance_valid(active_drops[index]):
			active_drops.remove_at(index)


func _supports(candidate: Node, methods: Array[StringName]) -> bool:
	if not is_instance_valid(candidate):
		return false
	for method_name in methods:
		if not candidate.has_method(method_name):
			return false
	return true
