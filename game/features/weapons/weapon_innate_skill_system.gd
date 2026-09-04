class_name WeaponInnateSkillSystem
extends Node

## 발사 당시 무기 정체성 스냅샷으로 고유 스킬을 해결합니다.
## 성장·모듈 modifier를 입력받지 않는 것이 이 모듈의 핵심 계약입니다.

signal innate_skill_triggered(snapshot: Dictionary)

var confirmed_hits_by_weapon: Dictionary = {}
var total_triggers: int = 0
var last_trigger: Dictionary = {}


func resolve_confirmed_hit(target: Node, world_position: Vector2, identity: Dictionary) -> bool:
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
	if fixed_damage > 0.0:
		target.call(&"take_damage", fixed_damage, context)
	total_triggers += 1
	last_trigger = {
		&"weapon_id": weapon_id,
		&"skill_id": context[&"innate_skill_id"],
		&"fixed_damage": fixed_damage,
		&"world_position": world_position,
		&"trigger_number": total_triggers,
	}
	innate_skill_triggered.emit(last_trigger.duplicate(true))
	return true


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
