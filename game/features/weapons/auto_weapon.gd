class_name AutoWeapon
extends Node2D

@export var projectile_scene: PackedScene
@export_range(0.05, 10.0, 0.05) var fire_interval: float = 0.72
@export_range(1.0, 1000.0, 1.0) var projectile_damage: float = 1.0
@export_range(32.0, 2000.0, 16.0) var target_range: float = 760.0

var projectile_parent: Node2D
var cooldown: float = 0.2


func configure(new_projectile_parent: Node2D) -> void:
	projectile_parent = new_projectile_parent


func _process(delta: float) -> void:
	cooldown -= delta
	if cooldown > 0.0:
		return

	var target := _find_nearest_enemy()
	if target != null:
		_fire_at(target)
		cooldown = fire_interval


func apply_level(level: int) -> void:
	fire_interval = maxf(0.22, 0.72 - float(level - 1) * 0.035)
	projectile_damage = 1.0 + floorf(float(level - 1) / 3.0)


func _find_nearest_enemy() -> Node2D:
	var nearest: Node2D
	var nearest_distance_squared := target_range * target_range

	for candidate in get_tree().get_nodes_in_group(&"enemies"):
		if not candidate is Node2D:
			continue

		var candidate_2d := candidate as Node2D
		var distance_squared := global_position.distance_squared_to(candidate_2d.global_position)
		if distance_squared < nearest_distance_squared:
			nearest = candidate_2d
			nearest_distance_squared = distance_squared

	return nearest


func _fire_at(target: Node2D) -> void:
	if projectile_scene == null or not is_instance_valid(projectile_parent):
		return

	var projectile := projectile_scene.instantiate() as Area2D
	if projectile == null:
		return

	var direction := global_position.direction_to(target.global_position)
	projectile_parent.add_child(projectile)
	projectile.global_position = global_position
	projectile.call(&"launch", direction, projectile_damage)
