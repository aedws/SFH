class_name MagneticFieldSkillEffect
extends "res://game/features/combat_skills/combat_skill_effect.gd"

const PULSE_EFFECT_SCRIPT := preload(
	"res://game/features/combat_skills/effects/skill_pulse_effect.gd"
)

@export_range(32.0, 1000.0, 8.0) var radius: float = 230.0
@export_range(0.0, 10000.0, 1.0) var damage: float = 24.0
@export_range(0.1, 5.0, 0.1) var visual_duration: float = 0.75
@export var effect_color: Color = Color(0.44, 0.62, 1.0, 1.0)


func activate(player: Node2D, context: Dictionary) -> Dictionary:
	if not is_instance_valid(player):
		return {&"success": false, &"status": "자기장 중심을 확인할 수 없습니다."}
	var hit_count := 0
	var target_container: Variant = context.get(&"target_container")
	var damage_enabled := bool(context.get(&"damage_enabled", true))
	if is_instance_valid(target_container) and target_container is Node:
		for target in (target_container as Node).get_children():
			if (
				target is Node2D
				and target.has_method(&"take_damage")
				and player.global_position.distance_to((target as Node2D).global_position) <= radius
			):
				if damage_enabled:
					target.call(&"take_damage", damage)
				hit_count += 1
	_spawn_pulse(context.get(&"effect_parent"), player.global_position)
	return {
		&"success": true,
		&"status": "자기장 전개 · %d개 대상" % hit_count,
		&"hit_count": hit_count,
		&"damage": damage if damage_enabled else 0.0,
	}


func get_parameters() -> Dictionary:
	return {&"radius": radius, &"damage": damage, &"visual_duration": visual_duration}


func _spawn_pulse(parent: Variant, world_position: Vector2) -> void:
	if not is_instance_valid(parent) or not parent is Node2D:
		return
	var pulse := PULSE_EFFECT_SCRIPT.new()
	(parent as Node2D).add_child(pulse)
	pulse.global_position = world_position
	pulse.configure(radius, effect_color, visual_duration, true)
