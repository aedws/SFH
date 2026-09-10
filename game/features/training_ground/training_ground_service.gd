class_name TrainingGroundService
extends Node

signal scenario_activated(snapshot: Dictionary)
signal scenario_reset(snapshot: Dictionary)
signal scenario_stopped(snapshot: Dictionary)
signal dummy_spawned(dummy: Node)
signal telemetry_snapshot_changed(snapshot: Dictionary)
signal telemetry_finalized(snapshot: Dictionary)
signal loadout_state_changed(snapshot: Dictionary)
signal stop_requested

const DEFINITION := preload("res://game/features/training_ground/training_scenario_definition.gd")
const SPAWNER := preload("res://game/features/training_ground/training_dummy_spawner.gd")
const RESET_SERVICE := preload("res://game/features/training_ground/training_scenario_reset_service.gd")
const TELEMETRY_SERVICE := preload("res://game/features/training_ground/training_telemetry_service.gd")
const LOADOUT_SERVICE := preload("res://game/features/training_ground/training_loadout_service.gd")

var config: Resource
var definitions: Dictionary = {}
var scenario_order := PackedStringArray()
var spawner: Node
var reset_service
var reset_pending := false
var telemetry_service: Node
var loadout_service
var combat_skill_provider: Node
var skill_catalog: Array[Resource] = []
var skill_catalog_provider: Node

func configure_skill_catalog_provider(provider: Node) -> bool:
	if _editing_active() or not is_instance_valid(provider) or not provider.has_method(&"get_skill_catalog_resources"):
		return false
	skill_catalog_provider = provider
	return true
var socket_provider: Node


func configure_checkpoint_provider(provider: Node) -> bool:
	return loadout_service != null and bool(loadout_service.call(&"configure_checkpoint_provider", provider))


func configure_socket_runtime(provider: Node) -> bool:
	if loadout_service == null or not is_instance_valid(provider):
		return false
	for method in [&"socket_item", &"socket_owned_item", &"unsocket", &"get_catalog_items", &"get_owned_catalog_items", &"get_snapshot"]:
		if not provider.has_method(method):
			return false
	if not provider.has_signal(&"sockets_changed"):
		return false
	if not loadout_service.call(&"register_runtime_provider", &"sockets", provider):
		return false
	socket_provider = provider
	provider.connect(&"sockets_changed", func(_snapshot): loadout_state_changed.emit(get_loadout_snapshot()))
	if provider.has_signal(&"catalog_updated"):
		provider.connect(&"catalog_updated", func(_snapshot, _source): loadout_state_changed.emit(get_loadout_snapshot()))
	return true


func toggle_training_socket(item_id: StringName, requested_targets: Dictionary = {}) -> Dictionary:
	if not _editing_active() or not is_instance_valid(socket_provider):
		return {&"success": false, &"reason": &"training_inactive"}
	var slots: Dictionary = socket_provider.call(&"get_snapshot").get(&"slots", {})
	for type in slots:
		for entry in slots[type]:
			if entry.get(&"item_id", &"") == item_id:
				return socket_provider.call(&"unsocket", type, entry.slot_index)
	return socket_provider.call(&"socket_owned_item" if config.owned_sockets_only else &"socket_item", item_id, requested_targets)


func request_stop() -> void:
	stop_requested.emit()


func supports_inventory_item(item_id: StringName) -> bool:
	return _editing_active() and is_instance_valid(socket_provider) and bool(socket_provider.call(&"supports_inventory_item", item_id))


func perform_inventory_item_action(item_id: StringName) -> Dictionary:
	if not supports_inventory_item(item_id):
		return {&"success": false, &"reason": &"training_inactive"}
	return socket_provider.call(&"socket_owned_item", item_id)


func _editing_active() -> bool:
	return loadout_service != null and bool(loadout_service.call(&"get_snapshot").get(&"free_editing", false))


func configure(target: Node2D, dummy_parent: Node2D, scenario_rows: Array[Dictionary],
		ground_config: Resource, equipment_provider: Node = null,
		inventory_provider: Node = null) -> bool:
	if (
		not is_instance_valid(target)
		or not is_instance_valid(dummy_parent)
		or ground_config == null
		or not ground_config.has_method(&"is_valid")
		or not bool(ground_config.call(&"is_valid"))
	):
		return false
	config = ground_config
	definitions.clear()
	scenario_order.clear()
	for row in scenario_rows:
		var definition = DEFINITION.new()
		if not bool(definition.call(&"configure", row)) or definitions.has(definition.get("scenario_id")):
			definitions.clear()
			scenario_order.clear()
			return false
		definitions[definition.get("scenario_id")] = definition
		scenario_order.append(String(definition.get("scenario_id")))
	if definitions.is_empty():
		return false
	spawner = SPAWNER.new()
	add_child(spawner)
	if not bool(spawner.call(&"configure", target, dummy_parent, config)):
		return false
	spawner.connect(&"dummy_spawned", func(dummy): dummy_spawned.emit(dummy))
	spawner.connect(&"all_dummies_defeated", _on_all_dummies_defeated)
	reset_service = RESET_SERVICE.new()
	if not bool(reset_service.call(&"configure", spawner)):
		return false
	telemetry_service = TELEMETRY_SERVICE.new()
	add_child(telemetry_service)
	if not bool(telemetry_service.call(&"configure", float(config.get("telemetry_refresh_seconds")))):
		return false
	telemetry_service.connect(&"snapshot_changed", func(snapshot):
		telemetry_snapshot_changed.emit(snapshot))
	telemetry_service.connect(&"measurement_finalized", func(snapshot):
		telemetry_finalized.emit(snapshot))
	if is_instance_valid(equipment_provider) and is_instance_valid(inventory_provider):
		loadout_service = LOADOUT_SERVICE.new()
		if not bool(loadout_service.call(&"configure", equipment_provider, inventory_provider)):
			return false
		loadout_service.connect(&"state_changed", func(_snapshot):
			loadout_state_changed.emit(get_loadout_snapshot()))
	return true


func activate_scenario(scenario_id: StringName) -> Dictionary:
	var definition: Resource = definitions.get(scenario_id)
	if definition == null:
		return {&"success": false, &"reason": "훈련 시나리오 없음"}
	reset_pending = false
	var starting := StringName(reset_service.call(&"get_snapshot").get(&"active_scenario_id", &"")) == &""
	if starting and is_instance_valid(skill_catalog_provider):
		var candidates: Array[Resource] = []
		candidates.assign(skill_catalog_provider.call(&"get_skill_catalog_resources"))
		if candidates.is_empty(): return {&"success": false, &"reason": "훈련 스킬 수치 검증 실패"}
		skill_catalog = candidates
	if loadout_service != null and not bool(loadout_service.call(&"begin_session")):
		return {&"success": false, &"reason": "훈련 로드아웃 스냅샷 실패"}
	if starting and is_instance_valid(combat_skill_provider) and combat_skill_provider.has_method(&"refresh_inactive_definitions"):
		if not combat_skill_provider.call(&"refresh_inactive_definitions", skill_catalog):
			stop()
			return {&"success": false, &"reason": "훈련 스킬 적용 실패 · 원본 복원"}
	var result: Dictionary = reset_service.call(&"activate", definition)
	if bool(result.get(&"success", false)):
		if is_instance_valid(combat_skill_provider):
			combat_skill_provider.call(&"set_activation_enabled", true)
		telemetry_service.call(&"begin", definition.call(&"get_snapshot"))
		scenario_activated.emit(get_snapshot())
	else:
		stop()
	return result


func activate_next_scenario() -> Dictionary:
	if scenario_order.is_empty():
		return {&"success": false, &"reason": "훈련 시나리오 없음"}
	var current := StringName(reset_service.call(&"get_snapshot").get(&"active_scenario_id", &""))
	var next_index := 0
	if current != &"":
		var current_index := scenario_order.find(String(current))
		next_index = (current_index + 1) % scenario_order.size()
	return activate_scenario(StringName(scenario_order[next_index]))


func reset_active_scenario() -> Dictionary:
	reset_pending = false
	var result: Dictionary = reset_service.call(&"reset")
	if bool(result.get(&"success", false)):
		var scenario: Dictionary = result.get(&"scenario", {})
		if is_instance_valid(telemetry_service) and not scenario.is_empty():
			telemetry_service.call(&"begin", scenario)
		scenario_reset.emit(get_snapshot())
	else:
		stop()
	return result


func stop() -> Dictionary:
	reset_pending = false
	if is_instance_valid(combat_skill_provider):
		combat_skill_provider.call(&"set_activation_enabled", false)
	if loadout_service != null and bool(loadout_service.call(&"get_snapshot").get(&"active", false)) and not bool(loadout_service.call(&"restore_and_finish")):
		return {&"success": false, &"reason": "원래 세팅 복원 실패 · 원본 보존, 다시 종료해 주세요"}
	var result: Dictionary = reset_service.call(&"stop")
	if is_instance_valid(telemetry_service):
		result[&"telemetry"] = telemetry_service.call(&"stop")
	result[&"loadout_restored"] = loadout_service == null or bool(loadout_service.call(&"get_snapshot").get(&"last_restore_success", false))
	scenario_stopped.emit(get_snapshot())
	return result


func record_hit(damage: float, armor_penetration: float = 0.0) -> bool:
	return (
		is_instance_valid(telemetry_service)
		and bool(telemetry_service.call(&"record_hit", damage, armor_penetration))
	)


func record_resource_use(ap_spent: float, cooldown_seconds: float) -> bool:
	return (
		is_instance_valid(telemetry_service)
		and bool(telemetry_service.call(
			&"record_resource_use", ap_spent, cooldown_seconds
		))
	)


func get_telemetry_snapshot() -> Dictionary:
	return telemetry_service.call(&"get_snapshot") if is_instance_valid(telemetry_service) else {}


func get_loadout_snapshot() -> Dictionary:
	var result: Dictionary = loadout_service.call(&"get_snapshot") if loadout_service != null else {}
	result[&"skills"] = (
		combat_skill_provider.call(&"get_skill_states")
		if is_instance_valid(combat_skill_provider) else []
	)
	result[&"socket_catalog"] = socket_provider.call(&"get_owned_catalog_items" if config.owned_sockets_only else &"get_catalog_items") if is_instance_valid(socket_provider) else []
	result[&"owned_sockets_only"] = config.owned_sockets_only if config != null else true
	result[&"sockets"] = socket_provider.call(&"get_snapshot") if is_instance_valid(socket_provider) else {}
	return result


func configure_combat_runtime(new_skill_provider: Node, candidates: Array[Resource]) -> bool:
	if (
		not is_instance_valid(new_skill_provider)
		or not new_skill_provider.has_method(&"get_skill_states")
		or not new_skill_provider.has_method(&"preview_skill_replacement")
		or not new_skill_provider.has_method(&"replace_skill")
		or not new_skill_provider.has_method(&"set_activation_enabled")
	):
		return false
	combat_skill_provider = new_skill_provider
	skill_catalog.clear()
	for candidate in candidates:
		if candidate != null and candidate.has_method(&"is_valid") and bool(candidate.call(&"is_valid")):
			skill_catalog.append(candidate)
	var configured := not skill_catalog.is_empty()
	if configured:
		if loadout_service != null and not loadout_service.call(&"register_runtime_provider", &"skills", new_skill_provider):
			return false
		combat_skill_provider.call(&"set_activation_enabled", false)
		loadout_state_changed.emit(get_loadout_snapshot())
	return configured


func cycle_training_skill(slot_index: int) -> Dictionary:
	if not _editing_active() or not is_instance_valid(combat_skill_provider) or skill_catalog.is_empty():
		return {&"success": false, &"reason": &"runtime_unavailable"}
	var states: Array = combat_skill_provider.call(&"get_skill_states")
	if slot_index < 0 or slot_index >= states.size():
		return {&"success": false, &"reason": &"invalid_slot"}
	var current_id := StringName((states[slot_index] as Dictionary).get(&"skill_id", &""))
	var current_index := -1
	for index in skill_catalog.size():
		if StringName(skill_catalog[index].get("skill_id")) == current_id:
			current_index = index
			break
	for offset in range(1, skill_catalog.size() + 1):
		var candidate := skill_catalog[posmod(current_index + offset, skill_catalog.size())]
		if StringName(candidate.get("skill_id")) == current_id:
			continue
		var preview: Dictionary = combat_skill_provider.call(
			&"preview_skill_replacement", slot_index, candidate
		)
		if not bool(preview.get(&"available", false)):
			continue
		var result: Dictionary = combat_skill_provider.call(&"replace_skill", slot_index, candidate)
		if bool(result.get(&"success", false)):
			result[&"skill_id"] = candidate.get("skill_id")
			result[&"display_name"] = candidate.get("display_name")
			loadout_state_changed.emit(get_loadout_snapshot())
		return result
	return {&"success": false, &"reason": &"no_compatible_skill"}


func get_scenario_rows() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for scenario_id in scenario_order:
		var definition: Resource = definitions.get(StringName(scenario_id))
		result.append(definition.call(&"get_snapshot"))
	return result


func get_active_targets() -> Array[Node2D]:
	return spawner.call(&"get_active_targets") if is_instance_valid(spawner) else []


func get_snapshot() -> Dictionary:
	var reset_snapshot: Dictionary = (
		reset_service.call(&"get_snapshot") if reset_service != null else {}
	)
	return {
		&"scenario_count": definitions.size(),
		&"scenario_ids": scenario_order.duplicate(),
		&"active_scenario_id": reset_snapshot.get(&"active_scenario_id", &""),
		&"active_count": reset_snapshot.get(&"active_count", 0),
		&"reset_revision": reset_snapshot.get(&"reset_revision", 0),
		&"auto_reset_after_clear": bool(config.get("auto_reset_after_clear")) if config != null else false,
		&"general_spawn_budget_impact": 0,
		&"telemetry": get_telemetry_snapshot(),
		&"loadout": get_loadout_snapshot(),
	}


func _on_all_dummies_defeated() -> void:
	if (
		reset_pending
		or config == null
		or not bool(config.get("auto_reset_after_clear"))
		or StringName(reset_service.call(&"get_snapshot").get(&"active_scenario_id", &"")) == &""
	):
		return
	reset_pending = true
	var timer := get_tree().create_timer(float(config.get("reset_delay_seconds")))
	timer.timeout.connect(_perform_delayed_reset, CONNECT_ONE_SHOT)


func _perform_delayed_reset() -> void:
	if not reset_pending:
		return
	reset_pending = false
	reset_active_scenario()
