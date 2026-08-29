class_name EnemySpawner
extends Node

signal enemy_spawned(enemy: Node)

const MAP_PROVIDER_METHODS := [&"get_enemy_spawn_position", &"get_world_path"]

@export var enemy_scene: PackedScene
@export_range(0.1, 10.0, 0.1) var initial_interval: float = 1.1
@export_range(0.1, 10.0, 0.1) var minimum_interval: float = 0.3
@export_range(100.0, 2000.0, 10.0) var spawn_radius: float = 620.0
@export_range(1, 1000, 1) var maximum_enemies: int = 180

var target: Node2D
var enemy_parent: Node2D
var map_provider: Node
var contact_damage_enabled: bool = true
var enemy_armor_enabled: bool = true
var enemy_status_ui_enabled: bool = true
var elapsed_time: float = 0.0
var spawn_cooldown: float = 0.15


func configure(
	new_target: Node2D,
	new_enemy_parent: Node2D,
	enable_contact_damage: bool,
	new_map_provider: Node = null,
	enable_enemy_armor: bool = true,
	enable_enemy_status_ui: bool = true
) -> void:
	target = new_target
	enemy_parent = new_enemy_parent
	contact_damage_enabled = enable_contact_damage
	map_provider = new_map_provider if _supports_map_provider(new_map_provider) else null
	enemy_armor_enabled = enable_enemy_armor
	enemy_status_ui_enabled = enable_enemy_status_ui


func _process(delta: float) -> void:
	if not is_instance_valid(target) or not is_instance_valid(enemy_parent):
		return

	elapsed_time += delta
	spawn_cooldown -= delta
	if spawn_cooldown > 0.0:
		return

	var enemy_count := get_tree().get_nodes_in_group(&"enemies").size()
	if enemy_count < maximum_enemies:
		_spawn_enemy()

	spawn_cooldown = maxf(minimum_interval, initial_interval - elapsed_time * 0.008)


func _spawn_enemy() -> void:
	if enemy_scene == null:
		push_error("EnemySpawner에 Enemy Scene이 지정되지 않았습니다.")
		return

	var enemy := enemy_scene.instantiate() as Node2D
	if enemy == null:
		push_error("Enemy Scene의 루트는 Node2D여야 합니다.")
		return

	var angle := randf_range(0.0, TAU)
	var distance := randf_range(spawn_radius * 0.85, spawn_radius * 1.15)
	var spawn_position := target.global_position + Vector2.RIGHT.rotated(angle) * distance
	if is_instance_valid(map_provider) and map_provider.has_method(&"get_enemy_spawn_position"):
		spawn_position = map_provider.call(
			&"get_enemy_spawn_position",
			target.global_position,
			spawn_radius * 0.5
		)

	enemy_parent.add_child(enemy)
	enemy.global_position = spawn_position
	enemy.call(
		&"configure",
		target,
		contact_damage_enabled,
		map_provider,
		enemy_armor_enabled,
		enemy_status_ui_enabled
	)
	enemy_spawned.emit(enemy)


func _supports_map_provider(candidate: Node) -> bool:
	if not is_instance_valid(candidate):
		return false

	for method_name in MAP_PROVIDER_METHODS:
		if not candidate.has_method(method_name):
			return false

	return true
