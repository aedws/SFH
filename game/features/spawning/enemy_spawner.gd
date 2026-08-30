class_name EnemySpawner
extends Node

signal enemy_spawned(enemy: Node)
signal reinforcement_dispatched(spawned_count: int, active_count: int, target_count: int)
signal spawn_budget_exhausted(total_spawned: int, maximum_total_spawns: int)

const MAP_PROVIDER_METHODS := [&"get_enemy_spawn_position", &"get_world_path"]

@export var enemy_scene: PackedScene
var target: Node2D
var enemy_parent: Node2D
var map_provider: Node
var spawn_config: Resource
var contact_damage_enabled: bool = true
var enemy_armor_enabled: bool = true
var enemy_status_ui_enabled: bool = true
var target_active_enemies: int = 0
var reinforcement_cooldown: float = 0.0
var total_spawned: int = 0
var reinforcement_count: int = 0
var initial_fill_complete: bool = false
var spawn_budget_is_exhausted: bool = false
var tracked_enemies: Array[Node] = []
var enemy_stat_multipliers: Dictionary = {}
var reinforcement_pause_sources: Dictionary = {}
var random := RandomNumberGenerator.new()


func _ready() -> void:
	random.randomize()


func configure(
	new_target: Node2D,
	new_enemy_parent: Node2D,
	enable_contact_damage: bool,
	new_map_provider: Node = null,
	enable_enemy_armor: bool = true,
	enable_enemy_status_ui: bool = true,
	new_spawn_config: Resource = null,
	new_enemy_stat_multipliers: Dictionary = {}
) -> bool:
	if (
		not is_instance_valid(new_target)
		or not is_instance_valid(new_enemy_parent)
		or new_spawn_config == null
		or not new_spawn_config.has_method(&"is_valid")
		or not new_spawn_config.call(&"is_valid")
	):
		push_error("EnemySpawner 구성에 대상, 적 부모, 유효한 등급 정책이 필요합니다.")
		return false
	target = new_target
	enemy_parent = new_enemy_parent
	contact_damage_enabled = enable_contact_damage
	map_provider = new_map_provider if _supports_map_provider(new_map_provider) else null
	enemy_armor_enabled = enable_enemy_armor
	enemy_status_ui_enabled = enable_enemy_status_ui
	spawn_config = new_spawn_config
	enemy_stat_multipliers = new_enemy_stat_multipliers.duplicate(true)
	for enemy in tracked_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	total_spawned = 0
	reinforcement_count = 0
	initial_fill_complete = false
	spawn_budget_is_exhausted = false
	tracked_enemies.clear()
	reinforcement_pause_sources.clear()
	target_active_enemies = random.randi_range(
		int(spawn_config.get("minimum_active_enemies")),
		int(spawn_config.get("maximum_active_enemies"))
	)
	reinforcement_cooldown = float(spawn_config.get("initial_delay_seconds"))
	return true


func _process(delta: float) -> void:
	if not is_instance_valid(target) or not is_instance_valid(enemy_parent):
		return
	if not reinforcement_pause_sources.is_empty():
		return

	reinforcement_cooldown -= delta
	if reinforcement_cooldown > 0.0 or spawn_config == null:
		return
	var maximum_total_spawns := int(spawn_config.get("maximum_total_spawns"))
	var remaining_spawn_budget := maxi(0, maximum_total_spawns - total_spawned)
	if remaining_spawn_budget <= 0:
		_mark_spawn_budget_exhausted()
		return

	var active_count := tracked_enemies.size()
	var reinforcement_trigger := ceili(
		float(target_active_enemies) * float(spawn_config.get("reinforcement_trigger_ratio"))
	)
	if active_count >= target_active_enemies:
		initial_fill_complete = true
		return
	if initial_fill_complete and active_count > reinforcement_trigger:
		return

	var requested_batch := random.randi_range(
		int(spawn_config.get("minimum_reinforcement_batch")),
		int(spawn_config.get("maximum_reinforcement_batch"))
	)
	var batch_size := mini(
		requested_batch,
		mini(target_active_enemies - active_count, remaining_spawn_budget)
	)
	var spawned_count := 0
	for _index in range(batch_size):
		if _spawn_enemy():
			spawned_count += 1
	if spawned_count > 0:
		reinforcement_count += 1
		reinforcement_dispatched.emit(
			spawned_count,
			tracked_enemies.size(),
			target_active_enemies
		)
	if tracked_enemies.size() >= target_active_enemies:
		initial_fill_complete = true
	if total_spawned >= maximum_total_spawns:
		_mark_spawn_budget_exhausted()
	reinforcement_cooldown = float(spawn_config.get("reinforcement_interval_seconds"))


func _spawn_enemy() -> bool:
	var angle := random.randf_range(0.0, TAU)
	var configured_radius := float(spawn_config.get("spawn_radius"))
	var distance := random.randf_range(configured_radius * 0.85, configured_radius * 1.15)
	var spawn_position := target.global_position + Vector2.RIGHT.rotated(angle) * distance
	if is_instance_valid(map_provider) and map_provider.has_method(&"get_enemy_spawn_position"):
		spawn_position = map_provider.call(
			&"get_enemy_spawn_position",
			target.global_position,
			configured_radius * 0.5
		)
	return spawn_enemy_at(spawn_position) != null


func spawn_enemy_at(world_position: Vector2, encounter_id: StringName = &"") -> Node2D:
	if enemy_scene == null or spawn_config == null:
		push_error("EnemySpawner에 Enemy Scene 또는 등급 정책이 지정되지 않았습니다.")
		return null
	if total_spawned >= int(spawn_config.get("maximum_total_spawns")):
		_mark_spawn_budget_exhausted()
		return null
	var enemy := enemy_scene.instantiate() as Node2D
	if enemy == null:
		push_error("Enemy Scene의 루트는 Node2D여야 합니다.")
		return null
	if not enemy.has_method(&"configure") or not enemy.has_signal(&"defeated"):
		push_error("Enemy Scene이 생성기 공개 계약을 구현하지 않았습니다.")
		enemy.free()
		return null

	enemy_parent.add_child(enemy)
	enemy.global_position = world_position
	enemy.set_meta(&"room_encounter_id", encounter_id)
	enemy.call(
		&"configure",
		target,
		contact_damage_enabled,
		map_provider,
		enemy_armor_enabled,
		enemy_status_ui_enabled,
		enemy_stat_multipliers
	)
	tracked_enemies.append(enemy)
	enemy.tree_exited.connect(_on_enemy_tree_exited.bind(enemy), CONNECT_ONE_SHOT)
	total_spawned += 1
	enemy_spawned.emit(enemy)
	return enemy


func set_reinforcement_paused(source_id: StringName, is_paused: bool) -> void:
	if source_id == &"":
		return
	if is_paused:
		reinforcement_pause_sources[source_id] = true
	else:
		reinforcement_pause_sources.erase(source_id)


func get_remaining_spawn_budget() -> int:
	return (
		maxi(0, int(spawn_config.get("maximum_total_spawns")) - total_spawned)
		if spawn_config != null else 0
	)


func get_snapshot() -> Dictionary:
	_prune_invalid_enemies()
	return {
		&"tier_id": spawn_config.get("tier_id") if spawn_config != null else &"",
		&"minimum_active_enemies": (
			spawn_config.get("minimum_active_enemies") if spawn_config != null else 0
		),
		&"maximum_active_enemies": (
			spawn_config.get("maximum_active_enemies") if spawn_config != null else 0
		),
		&"maximum_total_spawns": (
			spawn_config.get("maximum_total_spawns") if spawn_config != null else 0
		),
		&"target_active_enemies": target_active_enemies,
		&"active_enemies": tracked_enemies.size(),
		&"total_spawned": total_spawned,
		&"reinforcement_count": reinforcement_count,
		&"initial_fill_complete": initial_fill_complete,
		&"remaining_spawn_budget": (
			get_remaining_spawn_budget()
		),
		&"spawn_budget_exhausted": spawn_budget_is_exhausted,
		&"reinforcement_paused": not reinforcement_pause_sources.is_empty(),
		&"reinforcement_pause_sources": reinforcement_pause_sources.keys(),
		&"enemy_stat_multipliers": enemy_stat_multipliers.duplicate(true),
	}


func get_active_targets() -> Array[Node2D]:
	_prune_invalid_enemies()
	var result: Array[Node2D] = []
	for enemy in tracked_enemies:
		if enemy is Node2D:
			result.append(enemy as Node2D)
	return result


func _on_enemy_tree_exited(enemy: Node) -> void:
	tracked_enemies.erase(enemy)


func _mark_spawn_budget_exhausted() -> void:
	if spawn_budget_is_exhausted or spawn_config == null:
		return
	spawn_budget_is_exhausted = true
	spawn_budget_exhausted.emit(
		total_spawned,
		int(spawn_config.get("maximum_total_spawns"))
	)


func _prune_invalid_enemies() -> void:
	for index in range(tracked_enemies.size() - 1, -1, -1):
		if not is_instance_valid(tracked_enemies[index]):
			tracked_enemies.remove_at(index)


func _supports_map_provider(candidate: Node) -> bool:
	if not is_instance_valid(candidate):
		return false

	for method_name in MAP_PROVIDER_METHODS:
		if not candidate.has_method(method_name):
			return false

	return true
