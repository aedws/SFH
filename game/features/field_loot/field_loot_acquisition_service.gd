class_name FieldLootAcquisitionService
extends Node

signal drop_spawned(drop: Node2D, candidate: Dictionary)
signal preview_changed(visible: bool, comparison: Dictionary)
signal loot_acquired(item_id: StringName, quantity: int, snapshot: Dictionary)
signal loot_equipped(item_id: StringName, result: Dictionary, snapshot: Dictionary)
signal loot_socketed(item_id: StringName, result: Dictionary, snapshot: Dictionary)
signal acquisition_cancelled(item_id: StringName)
signal interaction_availability_changed(available: bool, prompt: String)
## Drop identity prevents same-item piles and repeat previews from sharing timers.
signal decision_observed(drop_id: int, stage: StringName, action: StringName)

const DROP_SCRIPT := preload("res://game/features/field_loot/field_loot_drop.gd")
const PANEL_SCRIPT := preload("res://game/features/field_loot/field_loot_comparison_panel.gd")

var player: Node2D
var drop_parent: Node2D
var lifecycle_provider: Node
var table_provider: Node
var comparison_service := FieldLootComparisonService.new()
var equip_service := FieldLootEquipService.new()
var skill_equip_service := FieldLootSkillEquipService.new()
var skill_equip_available := false
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
var last_equip_result: Dictionary = {}
var session_socket_provider: Node
var last_socket_result: Dictionary = {}
var inventory_service := FieldLootInventoryService.new()
@export var spawn_policy: FieldLootSpawnPolicy = preload("res://game/features/field_loot/configs/default_field_loot_spawn.tres")
var cleared_rooms: Dictionary = {}
var registered_enemies: Dictionary = {}
var enemy_roll := 0
var random := RandomNumberGenerator.new()
var last_acquisition_result: Dictionary = {}
var suppressed_drop: Node2D
var credit_provider: Node
var immediate_equip_enabled := true


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
	new_equip_catalog: FieldLootEquipCatalog = null,
	new_combat_skill_system: Node = null,
	new_skill_binding_provider: Node = null,
	new_session_socket_provider: Node = null,
	new_credit_provider: Node = null,
	enable_immediate_equip: bool = true
) -> bool:
	if (
		not is_instance_valid(new_player)
		or not is_instance_valid(new_drop_parent)
		or not is_instance_valid(ui_parent)
		or not _supports(new_table_provider, [&"roll_drop"])
	):
		return false
	player = new_player
	drop_parent = new_drop_parent
	lifecycle_provider = new_lifecycle_provider
	table_provider = new_table_provider
	operation_context = new_operation_context.duplicate(true)
	run_seed = new_run_seed
	equip_catalog = new_equip_catalog
	credit_provider = new_credit_provider
	immediate_equip_enabled = enable_immediate_equip
	skill_equip_available = false
	if equip_catalog != null and not equip_service.configure(equipment_provider, equip_catalog):
		return false
	if (
		equip_catalog != null
		and not equip_catalog.skill_entries.is_empty()
		and is_instance_valid(new_combat_skill_system)
		and is_instance_valid(new_skill_binding_provider)
		and not skill_equip_service.configure(
			new_combat_skill_system, new_skill_binding_provider, equip_catalog
		)
	):
		return false
	skill_equip_available = (
		equip_catalog != null
		and not equip_catalog.skill_entries.is_empty()
		and is_instance_valid(new_combat_skill_system)
		and is_instance_valid(new_skill_binding_provider)
	)
	session_socket_provider = (
		new_session_socket_provider
		if _supports(new_session_socket_provider, [&"acquire_items", &"get_snapshot"])
		else null
	)
	if not comparison_service.configure(
		new_lifecycle_provider,
		equipment_provider,
		inventory_provider,
		new_equip_catalog,
		skill_equip_service if skill_equip_available else null
	):
		return false
	acquired_items.clear()
	for drop in get_active_drops():
		drop.queue_free()
	if is_instance_valid(panel):
		panel.queue_free()
	active_drops.clear()
	focused_drop = null
	suppressed_drop = null
	comparison_service.immediate_equip_enabled = immediate_equip_enabled
	total_spawned = 0
	total_acquired = 0
	total_cancelled = 0
	last_equip_result.clear()
	last_socket_result.clear()
	inventory_service.configure(inventory_provider, equipment_provider, equip_catalog)
	cleared_rooms.clear()
	registered_enemies.clear()
	enemy_roll = 0
	random.seed = new_run_seed
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
	if source_type == &"boss":
		context[&"boss_available"] = true
	var candidate: Dictionary = table_provider.call(&"roll_drop", context, run_seed, roll_index)
	return spawn_candidate(world_position, candidate)


func spawn_room_reward(world_position: Vector2, room_index: int) -> Node2D:
	if cleared_rooms.has(room_index):
		return null
	var context := operation_context.duplicate(true)
	context[&"source_type"] = &"room_reward"
	context[&"item_type"] = spawn_policy.room_category(cleared_rooms.size())
	cleared_rooms[room_index] = true
	var candidate: Dictionary = table_provider.call(&"roll_drop", context, run_seed, room_index)
	# Removed category is optional: retain ordinary rewards instead of blocking rooms.
	if candidate.is_empty():
		context.erase(&"item_type")
		candidate = table_provider.call(&"roll_drop", context, run_seed, room_index)
	return spawn_candidate(world_position, candidate)


func register_enemy(enemy: Node) -> void:
	if not is_instance_valid(enemy) or not enemy.has_signal(&"defeated"):
		return
	var id := enemy.get_instance_id()
	if registered_enemies.has(id):
		return
	registered_enemies[id] = true
	var identity: Dictionary = enemy.call(&"get_combat_identity") if enemy.has_method(&"get_combat_identity") else {}
	enemy.connect(&"defeated", func(_experience: int, position: Vector2):
		if not registered_enemies.erase(id):
			return
		enemy_roll += 1
		var boss := bool(identity.get(&"is_boss", false))
		if not boss and (get_active_drops().size() >= spawn_policy.maximum_world_drops or random.randf() > spawn_policy.enemy_drop_chance):
			return
		for index in (spawn_policy.boss_drop_count if boss else 1):
			spawn_from_source(position, &"boss" if boss else &"enemy", enemy_roll * 8 + index)
	, CONNECT_ONE_SHOT)


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
	var comparison: Dictionary = focused_drop.get("comparison")
	var item_id := StringName(comparison[&"item_id"])
	if _is_session_socket_item(item_id) and is_instance_valid(session_socket_provider):
		# Prepare before recording acquisition. A full bag leaves loot in the world.
		last_socket_result = session_socket_provider.call(&"acquire_items", item_id, int(comparison.get(&"quantity", 1)))
		if not bool(last_socket_result.get(&"success", false)):
			panel.show_acquisition_error("소켓/가방 공간 부족 · 전리품은 바닥에 유지됩니다.")
			return false
		return _finalize_focused_acquisition(&"session_socket")
	last_acquisition_result = inventory_service.acquire(StringName(comparison[&"item_id"]), int(comparison.get(&"quantity", 1)))
	if not bool(last_acquisition_result.get(&"success", false)):
		panel.show_acquisition_error(last_acquisition_result.get(&"reason", "획득 실패"))
		return false
	return _finalize_focused_acquisition(&"run_bag" if bool(last_acquisition_result.get(&"stored_in_bag", false)) else &"run_storage")


func equip_focused() -> bool:
	if not is_instance_valid(focused_drop) or equip_catalog == null or not immediate_equip_enabled:
		last_equip_result = {&"success": false, &"reason": &"no_focused_drop"}
		return false
	var comparison: Dictionary = focused_drop.get("comparison")
	var item_id := StringName(comparison.get(&"item_id", &""))
	if equip_catalog.get_skill_entry(item_id) != null and not skill_equip_available:
		last_equip_result = {&"success": false, &"reason": &"skill_equip_unavailable"}
		return false
	var equip_result := (
		skill_equip_service.equip(item_id)
		if equip_catalog.get_skill_entry(item_id) != null
		else equip_service.equip(item_id)
	)
	last_equip_result = equip_result.duplicate(true)
	if not bool(equip_result.get(&"success", false)):
		panel.show_acquisition_error("장착 불가 · 현재 요원/슬롯 태그 확인 · F 가방 보관 가능")
		return false
	var completed := _finalize_focused_acquisition(&"equipped", equip_result)
	if completed:
		loot_equipped.emit(item_id, equip_result.duplicate(true), get_snapshot())
	return completed


func restore_equipment_swaps() -> int:
	if equip_catalog == null:
		return 0
	return equip_service.restore_swaps() + skill_equip_service.restore_swaps()


func restore_run_inventory() -> void:
	inventory_service.restore_run_baseline()


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
	if comparison.get(&"item_type", &"") == &"currency" and is_instance_valid(credit_provider):
		credit_provider.call(&"add_carried", quantity)
		entry[&"wallet_already_carried"] = true
	if not equip_result.is_empty():
		entry[&"previous_item_name"] = equip_result.get(&"previous_name", "")
		entry[&"previous_destination"] = equip_result.get(&"previous_destination", &"")
	if mode != &"session_socket":
		last_socket_result.clear()
	else:
		entry[&"session_socket_result"] = last_socket_result.duplicate(true)
	acquired_items[item_id] = entry
	var acquired_drop := focused_drop
	decision_observed.emit(acquired_drop.get_instance_id(), &"resolve", mode)
	focused_drop = null
	active_drops.erase(acquired_drop)
	panel.hide_comparison()
	preview_changed.emit(false, {})
	interaction_availability_changed.emit(false, "")
	total_acquired += 1
	loot_acquired.emit(item_id, quantity, get_snapshot())
	if bool(last_socket_result.get(&"success", false)) and last_socket_result.get(&"reason", &"") != &"stored_in_bag":
		loot_socketed.emit(item_id, last_socket_result.duplicate(true), get_snapshot())
	acquired_drop.queue_free()
	return true


func cancel_preview() -> bool:
	if not is_instance_valid(focused_drop):
		return false
	var comparison: Dictionary = focused_drop.get("comparison")
	var item_id := StringName(comparison.get(&"item_id", &""))
	suppressed_drop = focused_drop
	decision_observed.emit(focused_drop.get_instance_id(), &"resolve", &"deferred")
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
		&"immediate_skill_equip": skill_equip_service.get_snapshot(),
		&"last_equip_result": last_equip_result.duplicate(true),
		&"last_socket_result": last_socket_result.duplicate(true),
		&"session_sockets": (
			session_socket_provider.call(&"get_snapshot")
			if is_instance_valid(session_socket_provider) else {}
		),
		&"lifecycle_linked": is_instance_valid(lifecycle_provider),
		&"table_linked": is_instance_valid(table_provider),
	}


func _unhandled_input(event: InputEvent) -> void:
	if not is_instance_valid(focused_drop):
		return
	if event.is_action_pressed(&"interact"):
		acquire_focused()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"equip_field_loot"):
		equip_focused()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed(&"ui_cancel"):
		if cancel_preview():
			get_viewport().set_input_as_handled()


func _on_drop_proximity_changed(drop: Node2D, available: bool) -> void:
	if available:
		if _preview_is_suppressed() or is_instance_valid(focused_drop):
			return
		focused_drop = drop
		var comparison: Dictionary = drop.get("comparison")
		panel.show_comparison(comparison)
		decision_observed.emit(drop.get_instance_id(), &"open", &"")
		preview_changed.emit(true, comparison.duplicate(true))
		var session_socket_candidate := _is_session_socket_item(
			StringName(comparison.get(&"item_id", &""))
		)
		interaction_availability_changed.emit(
			true,
			(
				"F · %s 런 소켓 장착 / ESC · 보류" % comparison.get(&"display_name", "세션 자산")
				if session_socket_candidate else
				(
					"R · 스킬 즉시 교체 / F · 런 보관 / ESC · 보류"
					if StringName((comparison.get(&"equip_preview", {}) as Dictionary).get(&"equip_kind", &"")) == &"skill"
					else "R · 장비 즉시 장착 / F · 획득·가방 / ESC · 보류"
				)
				if not (comparison.get(&"equip_preview", {}) as Dictionary).is_empty()
				else "F · %s 획득 / ESC · 보류" % comparison.get(&"display_name", "전리품")
			)
		)
	elif focused_drop == drop:
		decision_observed.emit(drop.get_instance_id(), &"interrupt", &"out_of_range")
		focused_drop = null
		panel.hide_comparison()
		preview_changed.emit(false, {})
		interaction_availability_changed.emit(false, "")
	if not available and suppressed_drop == drop:
		suppressed_drop = null


func _process(_delta: float) -> void:
	if is_instance_valid(focused_drop) or not is_instance_valid(player):
		return
	if _preview_is_suppressed():
		return
	var nearest: Node2D
	var distance := INF
	for drop in get_active_drops():
		if drop == suppressed_drop:
			continue
		var candidate_distance := player.global_position.distance_to(drop.global_position)
		if candidate_distance <= float(drop.get("interaction_radius")) and candidate_distance < distance:
			nearest = drop
			distance = candidate_distance
	if nearest != null:
		_on_drop_proximity_changed(nearest, true)


func _preview_is_suppressed() -> bool:
	# ESC closes the nearby comparison interaction, not just one card in a pile.
	# Leaving its range explicitly rearms proximity discovery without deleting loot.
	if not is_instance_valid(suppressed_drop) or not is_instance_valid(player):
		return false
	if player.global_position.distance_to(suppressed_drop.global_position) <= float(suppressed_drop.get("interaction_radius")):
		return true
	suppressed_drop = null
	return false


func _prune_drops() -> void:
	for index in range(active_drops.size() - 1, -1, -1):
		if not is_instance_valid(active_drops[index]):
			active_drops.remove_at(index)


func _is_session_socket_item(item_id: StringName) -> bool:
	if not is_instance_valid(lifecycle_provider):
		return false
	var definition = lifecycle_provider.call(&"get_definition", item_id)
	return (
		definition != null
		and StringName(definition.get("loot_family")) == &"session_convertible"
		and StringName(definition.get("session_behavior")) == &"session_socket"
	)


func _supports(candidate: Node, methods: Array[StringName]) -> bool:
	if not is_instance_valid(candidate):
		return false
	for method_name in methods:
		if not candidate.has_method(method_name):
			return false
	return true
