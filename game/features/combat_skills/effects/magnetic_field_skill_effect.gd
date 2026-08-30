class_name MagneticFieldSkillEffect
extends "res://game/features/combat_skills/combat_skill_effect.gd"

const ELECTRIC_EFFECT_SCRIPT := preload(
	"res://game/features/combat_skills/effects/electric_arc_effect.gd"
)

@export_range(32.0, 1000.0, 8.0) var radius: float = 230.0
@export_range(0.0, 10000.0, 1.0) var damage: float = 24.0
@export var electric_profile: Resource


func activate(player: Node2D, context: Dictionary) -> Dictionary:
	if not is_instance_valid(player):
		return {&"success": false, &"status": "자기장 중심을 확인할 수 없습니다."}
	var hit_count := 0
	var target_container: Variant = context.get(&"target_container")
	var damage_enabled := bool(context.get(&"damage_enabled", true))
	if is_instance_valid(target_container) and target_container is Node:
		var container := target_container as Node
		for target_index in container.get_child_count():
			var target := container.get_child(target_index)
			if (
				target is Node2D
				and target.has_method(&"take_damage")
				and player.global_position.distance_to((target as Node2D).global_position) <= radius
			):
				if damage_enabled:
					target.call(&"take_damage", damage)
				hit_count += 1
	_spawn_electric_field(context.get(&"effect_parent"), player.global_position)
	return {
		&"success": true,
		&"status": "자기장 전개 · %d개 대상" % hit_count,
		&"hit_count": hit_count,
		&"damage": damage if damage_enabled else 0.0,
	}


func get_parameters() -> Dictionary:
	return {&"radius": radius, &"damage": damage}


func _spawn_electric_field(parent: Variant, world_position: Vector2) -> void:
	if not is_instance_valid(parent) or not parent is Node2D or electric_profile == null:
		return
	var electric := ELECTRIC_EFFECT_SCRIPT.new()
	(parent as Node2D).add_child(electric)
	electric.global_position = world_position
	if not electric.configure_radial(radius, electric_profile):
		electric.queue_free()
