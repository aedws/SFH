class_name MagneticFieldSkillEffect
extends "res://game/features/combat_skills/combat_skill_effect.gd"

const PERSISTENT_FIELD_SCRIPT := preload(
	"res://game/features/combat_skills/effects/persistent_magnetic_field.gd"
)

@export_range(32.0, 1000.0, 8.0) var radius: float = 230.0
@export_range(0.0, 10000.0, 1.0) var tick_damage: float = 6.0
@export_range(0.1, 8.0, 0.1) var duration_seconds: float = 5.0
@export_range(0.1, 2.0, 0.05) var tick_interval_seconds: float = 0.5
@export var electric_profile: Resource


func activate(player: Node2D, context: Dictionary) -> Dictionary:
	if not is_instance_valid(player):
		return {&"success": false, &"status": "자기장 중심을 확인할 수 없습니다."}
	var target_container: Variant = context.get(&"target_container")
	var effect_parent: Variant = context.get(&"effect_parent")
	var damage_enabled := bool(context.get(&"damage_enabled", true))
	var mechanic_override: Dictionary = context.get(&"mechanic_override", {})
	var resolved_radius := radius * float(mechanic_override.get(&"radius_multiplier", 1.0))
	var resolved_damage := tick_damage * float(mechanic_override.get(&"tick_damage_multiplier", 1.0))
	var resolved_duration := duration_seconds * float(mechanic_override.get(&"duration_multiplier", 1.0))
	if (
		not is_instance_valid(target_container)
		or not target_container is Node
		or not is_instance_valid(effect_parent)
		or not effect_parent is Node2D
	):
		return {&"success": false, &"status": "자기장 전개 공간을 확인할 수 없습니다."}
	var field := PERSISTENT_FIELD_SCRIPT.new()
	(effect_parent as Node2D).add_child(field)
	if not field.configure(
		player,
		target_container as Node,
		effect_parent as Node2D,
		resolved_radius,
		resolved_damage,
		resolved_duration,
		tick_interval_seconds,
		damage_enabled,
		electric_profile,
		StringName(mechanic_override.get(&"applied_status_id", &"shock")),
		float(mechanic_override.get(&"status_duration", 3.0))
	):
		field.queue_free()
		return {&"success": false, &"status": "자기장 전개에 실패했습니다."}
	var registrar: Callable = context.get(&"register_runtime_effect", Callable())
	if registrar.is_valid():
		registrar.call(field)
	return {
		&"success": true,
		&"status": "자기장 전개 · %.1f초 지속" % resolved_duration,
		&"tick_damage": resolved_damage if damage_enabled else 0.0,
		&"duration_seconds": resolved_duration,
		&"tick_interval_seconds": tick_interval_seconds,
	}


func get_parameters() -> Dictionary:
	return {
		&"radius": radius,
		&"tick_damage": tick_damage,
		&"duration_seconds": duration_seconds,
		&"tick_interval_seconds": tick_interval_seconds,
	}
