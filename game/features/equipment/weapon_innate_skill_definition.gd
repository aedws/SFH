class_name WeaponInnateSkillDefinition
extends Resource

## 무기 종류에 고정된 고유 스킬입니다. 모든 수치는 의도적으로 성장 배율을 받지 않습니다.

@export var skill_id: StringName
@export var display_name: String
@export_range(1, 20, 1) var trigger_every_hits: int = 3
@export_range(0.0, 1000.0, 0.1) var fixed_damage: float = 1.0
@export_range(0.1, 3.0, 0.05) var impact_strength: float = 1.0
@export var effect_color: Color = Color("02e5e1")
@export_multiline var description: String


func is_valid() -> bool:
	return (
		skill_id != &""
		and not display_name.is_empty()
		and trigger_every_hits > 0
		and fixed_damage >= 0.0
		and impact_strength > 0.0
	)


func snapshot() -> Dictionary:
	return {
		&"skill_id": skill_id,
		&"display_name": display_name,
		&"trigger_every_hits": trigger_every_hits,
		&"fixed_damage": fixed_damage,
		&"impact_strength": impact_strength,
		&"effect_color": effect_color,
		&"description": description,
		&"scaling_policy": &"fixed_identity",
	}
