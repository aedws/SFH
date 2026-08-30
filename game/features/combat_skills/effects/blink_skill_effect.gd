class_name BlinkSkillEffect
extends "res://game/features/combat_skills/combat_skill_effect.gd"

const PULSE_EFFECT_SCRIPT := preload(
	"res://game/features/combat_skills/effects/skill_pulse_effect.gd"
)

@export_range(32.0, 1200.0, 8.0) var distance: float = 360.0
@export_range(0.0, 64.0, 1.0) var wall_clearance: float = 24.0
@export_range(0, 4294967295, 1) var obstacle_collision_mask: int = 16
@export var effect_color: Color = Color(0.36, 0.92, 1.0, 1.0)


func activate(player: Node2D, context: Dictionary) -> Dictionary:
	if not is_instance_valid(player) or not player.has_method(&"get_facing_direction"):
		return {&"success": false, &"status": "점멸 방향을 확인할 수 없습니다."}
	var direction: Vector2 = player.call(&"get_facing_direction")
	if direction == Vector2.ZERO:
		direction = Vector2.RIGHT
	direction = direction.normalized()
	var start := player.global_position
	var destination := start + direction * distance
	var world := player.get_world_2d()
	if world != null:
		var query := PhysicsRayQueryParameters2D.create(start, destination, obstacle_collision_mask)
		query.collide_with_areas = false
		query.collide_with_bodies = true
		query.exclude = [player.get_rid()]
		var collision := world.direct_space_state.intersect_ray(query)
		if not collision.is_empty():
			destination = Vector2(collision[&"position"]) - direction * wall_clearance
	if start.distance_to(destination) < 24.0:
		return {&"success": false, &"status": "앞이 막혀 점멸할 수 없습니다."}
	player.global_position = destination
	_spawn_pulse(context.get(&"effect_parent"), start, 72.0)
	_spawn_pulse(context.get(&"effect_parent"), destination, 104.0)
	return {
		&"success": true,
		&"status": "전방 %.0fpx 점멸" % start.distance_to(destination),
		&"distance": start.distance_to(destination),
	}


func get_parameters() -> Dictionary:
	return {&"distance": distance, &"wall_clearance": wall_clearance}


func _spawn_pulse(parent: Variant, world_position: Vector2, radius: float) -> void:
	if not is_instance_valid(parent) or not parent is Node2D:
		return
	var pulse := PULSE_EFFECT_SCRIPT.new()
	(parent as Node2D).add_child(pulse)
	pulse.global_position = world_position
	pulse.configure(radius, effect_color, 0.32)
