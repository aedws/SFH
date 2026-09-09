class_name TacticalPatternEffect
extends "res://game/features/combat_skills/combat_skill_effect.gd"

## Data-defined attack geometry and lifetime; never owns equipment or input state.
@export_enum("circle", "ring", "cone", "line", "chain", "single", "self") var shape := "circle"
@export var radius := 220.0
@export var inner_radius := 80.0
@export var width := 48.0
@export var angle_degrees := 90.0
@export var damage := 12.0
@export var pulses := 1
@export var interval := 0.5
@export var delay := 0.0
@export var follow_player := false
@export var anchor_on_target := false
@export var maximum_targets := 24
@export var chain_range := 150.0
@export var status_id: StringName
@export var status_duration := 2.0
@export var consume_status_id: StringName
@export var combo_multiplier := 2.0
@export var rotation_per_pulse := 0.0
@export var defense_add := 0.0
@export var speed_multiplier := 1.0
@export var buff_duration := 4.0
@export var color := Color("02e5e1")

func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if shape not in ["circle", "ring", "cone", "line", "chain", "single", "self"]:
		errors.append("지원하지 않는 효과 기하")
	for value in [radius, inner_radius, width, angle_degrees, damage, interval, delay, chain_range, status_duration, combo_multiplier, rotation_per_pulse, defense_add, speed_multiplier, buff_duration]:
		if not is_finite(value): errors.append("유한한 효과 수치 필요")
	if radius <= 0 or inner_radius < 0 or inner_radius >= radius or width <= 0 or angle_degrees <= 0 or angle_degrees > 360 or damage < 0 or pulses < 1 or pulses > 40 or interval < 0.1 or delay < 0 or maximum_targets < 1 or maximum_targets > 64 or chain_range <= 0 or speed_multiplier <= 0 or buff_duration <= 0:
		errors.append("효과 수치 범위 오류")
	if status_id not in [&"", &"shock", &"slow", &"stun", &"vulnerable"] or consume_status_id not in [&"", &"shock", &"slow", &"stun", &"vulnerable"]:
		errors.append("지원하지 않는 상태 효과")
	if status_duration < 0 or status_duration > 30 or combo_multiplier < 1 or combo_multiplier > 10 or defense_add < 0 or buff_duration > 30 or interval > 10 or delay > 10 or radius > 2400 or speed_multiplier > 5:
		errors.append("효과 안전 예산 초과")
	return errors

func activate(player: Node2D, context: Dictionary) -> Dictionary:
	if not validation_errors().is_empty() or not is_instance_valid(player) or not is_instance_valid(context.get(&"effect_parent")) or not is_instance_valid(context.get(&"target_container")):
		return {&"success": false, &"status": "효과 계약 오류"}
	if anchor_on_target and not is_instance_valid(context.get(&"target")) and context.get(&"target_point", player.global_position) == player.global_position:
		return {&"success": false, &"status": "사거리 내 대상 없음"}
	var runtime := preload("res://game/features/combat_skills/effects/tactical_pattern_runtime.gd").new()
	context.effect_parent.add_child(runtime)
	runtime.configure(player, self, context)
	var registrar: Callable = context.get(&"register_runtime_effect", Callable())
	if registrar.is_valid(): registrar.call(runtime)
	return {&"success": true, &"status": "스킬 전개", &"runtime": runtime, &"pulses": pulses}

func get_parameters() -> Dictionary:
	return {&"shape": shape, &"radius": radius, &"inner_radius": inner_radius, &"width": width,
		&"angle_degrees": angle_degrees, &"damage": damage, &"pulses": pulses,
		&"interval": interval, &"delay": delay, &"follow_player": follow_player,
		&"anchor_on_target": anchor_on_target, &"maximum_targets": maximum_targets,
		&"chain_range": chain_range, &"status_id": status_id, &"status_duration": status_duration,
		&"consume_status_id": consume_status_id, &"combo_multiplier": combo_multiplier,
		&"rotation_per_pulse": rotation_per_pulse, &"defense_add": defense_add,
		&"speed_multiplier": speed_multiplier, &"buff_duration": buff_duration}
