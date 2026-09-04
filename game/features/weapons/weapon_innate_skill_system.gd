class_name WeaponInnateSkillSystem
extends Node

## 발사 당시 무기 정체성 스냅샷으로 고유 스킬을 해결합니다.
## 성장·모듈 modifier를 입력받지 않는 것이 이 모듈의 핵심 계약입니다.

signal innate_skill_triggered(snapshot: Dictionary)

var confirmed_hits_by_weapon: Dictionary = {}
var total_triggers: int = 0
var last_trigger: Dictionary = {}


func resolve_confirmed_hit(
	target: Node,
	world_position: Vector2,
	identity: Dictionary,
	candidate_targets: Array = []
) -> bool:
	if not is_instance_valid(target) or not target.has_method(&"take_damage"):
		return false
	var weapon_id := StringName(identity.get(&"weapon_id", &""))
	var skill: Dictionary = identity.get(&"innate_skill", {})
	if weapon_id == &"" or skill.is_empty():
		return false
	var threshold := maxi(1, int(skill.get(&"trigger_every_hits", 1)))
	var confirmed_hits := int(confirmed_hits_by_weapon.get(weapon_id, 0)) + 1
	confirmed_hits_by_weapon[weapon_id] = confirmed_hits
	if confirmed_hits % threshold != 0:
		return false

	var fixed_damage := maxf(0.0, float(skill.get(&"fixed_damage", 0.0)))
	var color: Color = skill.get(&"effect_color", Color("02e5e1"))
	var context := {
		&"source_kind": &"weapon_innate_skill",
		&"source_weapon_id": weapon_id,
		&"innate_skill_id": StringName(skill.get(&"skill_id", &"")),
		&"source_position": world_position,
		&"impact_direction": Vector2.RIGHT,
		&"impact_strength": float(skill.get(&"impact_strength", 1.0)),
		&"impact_color": color,
		&"impact_radius_multiplier": 1.55,
		&"impact_ray_multiplier": 1.5,
		&"camera_trauma_multiplier": 1.25,
		&"fixed_identity_effect": true,
	}
	var effect_kind := StringName(skill.get(&"effect_kind", &"single_target"))
	var affected_targets := _apply_effect(
		target, world_position, fixed_damage, effect_kind, skill, context, candidate_targets
	)
	total_triggers += 1
	last_trigger = {
		&"weapon_id": weapon_id,
		&"skill_id": context[&"innate_skill_id"],
		&"fixed_damage": fixed_damage,
		&"effect_kind": effect_kind,
		&"effect_radius": float(skill.get(&"effect_radius", 0.0)),
		&"affected_targets": affected_targets,
		&"world_position": world_position,
		&"trigger_number": total_triggers,
	}
	innate_skill_triggered.emit(last_trigger.duplicate(true))
	return true


func _apply_effect(
	primary_target: Node,
	world_position: Vector2,
	fixed_damage: float,
	effect_kind: StringName,
	skill: Dictionary,
	base_context: Dictionary,
	candidate_targets: Array
) -> int:
	if fixed_damage <= 0.0:
		return 0
	if effect_kind != &"electric_area":
		primary_target.call(&"take_damage", fixed_damage, base_context)
		return 1

	var radius := maxf(1.0, float(skill.get(&"effect_radius", 1.0)))
	var maximum_targets := maxi(1, int(skill.get(&"maximum_targets", 1)))
	var candidates := candidate_targets
	if candidates.is_empty() and is_inside_tree():
		candidates = get_tree().get_nodes_in_group(&"enemies")
	var ordered: Array[Dictionary] = []
	var seen: Dictionary = {}
	for candidate in [primary_target] + candidates:
		if (
			not is_instance_valid(candidate)
			or not candidate is Node2D
			or not candidate.has_method(&"take_damage")
			or seen.has(candidate.get_instance_id())
		):
			continue
		var distance := world_position.distance_to((candidate as Node2D).global_position)
		if distance > radius:
			continue
		seen[candidate.get_instance_id()] = true
		ordered.append({&"target": candidate, &"distance": distance})
	ordered.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a[&"distance"]) < float(b[&"distance"])
	)

	var affected := 0
	for entry in ordered:
		if affected >= maximum_targets:
			break
		var area_context := base_context.duplicate(true)
		area_context[&"source_kind"] = &"weapon_innate_electric_area"
		area_context[&"area_center"] = world_position
		area_context[&"area_radius"] = radius
		area_context[&"area_primary_target"] = entry[&"target"] == primary_target
		area_context[&"impact_direction"] = world_position.direction_to(
			(entry[&"target"] as Node2D).global_position
		)
		if bool(area_context[&"area_primary_target"]):
			area_context[&"impact_radius_multiplier"] = clampf(radius / 26.0, 1.55, 6.0)
			area_context[&"impact_ray_multiplier"] = 2.0
		(entry[&"target"] as Node).call(&"take_damage", fixed_damage, area_context)
		affected += 1
	return affected


func reset() -> void:
	confirmed_hits_by_weapon.clear()
	total_triggers = 0
	last_trigger.clear()


func get_snapshot() -> Dictionary:
	return {
		&"confirmed_hits_by_weapon": confirmed_hits_by_weapon.duplicate(true),
		&"total_triggers": total_triggers,
		&"last_trigger": last_trigger.duplicate(true),
		&"scaling_policy": &"fixed_identity",
	}
