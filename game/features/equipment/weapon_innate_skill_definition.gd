class_name WeaponInnateSkillDefinition
extends Resource

## 무기 종류에 고정된 고유 스킬입니다. 모든 수치는 의도적으로 성장 배율을 받지 않습니다.

enum EffectKind {
	SINGLE_TARGET,
	ELECTRIC_AREA,
}

@export var skill_id: StringName
@export var display_name: String
@export_range(1, 20, 1) var trigger_every_hits: int = 3
@export_range(0.0, 1000.0, 0.1) var fixed_damage: float = 1.0
@export var effect_kind: EffectKind = EffectKind.SINGLE_TARGET
@export_range(0.0, 512.0, 1.0) var effect_radius: float = 0.0
@export_range(1, 32, 1) var maximum_targets: int = 1
@export_range(0.1, 3.0, 0.05) var impact_strength: float = 1.0
@export var effect_color: Color = Color("02e5e1")
@export_multiline var description: String


func is_valid() -> bool:
	return (
		skill_id != &""
		and not display_name.is_empty()
		and trigger_every_hits > 0
		and fixed_damage >= 0.0
		and maximum_targets > 0
		and (effect_kind != EffectKind.ELECTRIC_AREA or effect_radius > 0.0)
		and impact_strength > 0.0
	)


func snapshot() -> Dictionary:
	return {
		&"skill_id": skill_id,
		&"display_name": display_name,
		&"trigger_every_hits": trigger_every_hits,
		&"fixed_damage": fixed_damage,
		&"effect_kind": effect_kind_name(),
		&"effect_radius": effect_radius,
		&"maximum_targets": maximum_targets,
		&"impact_strength": impact_strength,
		&"effect_color": effect_color,
		&"description": description,
		&"scaling_policy": &"fixed_identity",
	}


func effect_kind_name() -> StringName:
	return &"electric_area" if effect_kind == EffectKind.ELECTRIC_AREA else &"single_target"


func effect_summary() -> String:
	if effect_kind == EffectKind.ELECTRIC_AREA:
		return "%d회 명중마다 반경 %.0f 내 최대 %d명에게 고정 %.1f 전기 피해" % [
			trigger_every_hits, effect_radius, maximum_targets, fixed_damage,
		]
	return "%d회 명중마다 고정 %.1f 피해" % [trigger_every_hits, fixed_damage]
