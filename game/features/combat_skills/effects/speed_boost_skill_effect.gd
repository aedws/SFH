class_name SpeedBoostSkillEffect
extends "res://game/features/combat_skills/combat_skill_effect.gd"

const ELECTRIC_EFFECT_SCRIPT := preload(
	"res://game/features/combat_skills/effects/electric_arc_effect.gd"
)
const TIMED_MODIFIER_SCRIPT := preload(
	"res://game/features/combat_skills/effects/timed_stat_modifier.gd"
)

@export_range(1.01, 5.0, 0.01) var speed_multiplier: float = 1.55
@export_range(0.1, 60.0, 0.1) var duration_seconds: float = 4.0
@export var modifier_source_id: StringName = &"combat_skill_speed_boost"
@export var electric_profile: Resource


func activate(player: Node2D, context: Dictionary) -> Dictionary:
	if (
		not is_instance_valid(player)
		or not player.has_method(&"set_runtime_modifier_source")
		or not player.has_method(&"remove_runtime_modifier_source")
	):
		return {&"success": false, &"status": "이동 속도를 변경할 수 없습니다."}
	var mechanic_override: Dictionary = context.get(&"mechanic_override", {})
	var resolved_multiplier := speed_multiplier * float(mechanic_override.get(&"speed_multiplier", 1.0))
	var resolved_duration := duration_seconds * float(mechanic_override.get(&"duration_multiplier", 1.0))
	var previous := player.get_node_or_null("CombatSkillSpeedBoost")
	if previous != null:
		previous.free()
	var modifier := TIMED_MODIFIER_SCRIPT.new()
	modifier.name = "CombatSkillSpeedBoost"
	player.add_child(modifier)
	if not modifier.configure(
		player,
		modifier_source_id,
		{&"movement_speed": {&"add": 0.0, &"multiply": resolved_multiplier}},
		resolved_duration
	):
		modifier.queue_free()
		return {&"success": false, &"status": "이동 가속 적용에 실패했습니다."}
	_spawn_electric_aura(context.get(&"effect_parent"), player)
	return {
		&"success": true,
		&"status": "이동 속도 %.0f%% · %.1f초" % [resolved_multiplier * 100.0, resolved_duration],
		&"speed_multiplier": resolved_multiplier,
		&"duration_seconds": resolved_duration,
	}


func get_parameters() -> Dictionary:
	return {
		&"speed_multiplier": speed_multiplier,
		&"duration_seconds": duration_seconds,
	}


func _spawn_electric_aura(parent: Variant, player: Node2D) -> void:
	if not is_instance_valid(parent) or not parent is Node2D or electric_profile == null:
		return
	var electric := ELECTRIC_EFFECT_SCRIPT.new()
	(parent as Node2D).add_child(electric)
	electric.global_position = player.global_position
	if not electric.configure_radial(78.0, electric_profile, player):
		electric.queue_free()
