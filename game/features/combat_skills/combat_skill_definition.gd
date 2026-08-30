class_name CombatSkillDefinition
extends Resource

@export var skill_id: StringName
@export var display_name: String = "스킬"
@export_multiline var description: String
@export var input_action: StringName
@export var input_label: String = "?"
@export_range(0.1, 120.0, 0.1) var cooldown_seconds: float = 5.0
@export var accent_color: Color = Color(0.25, 0.85, 0.95, 1.0)
@export var effect: Resource


func is_valid() -> bool:
	return (
		skill_id != &""
		and not display_name.is_empty()
		and input_action != &""
		and cooldown_seconds > 0.0
		and effect != null
	)


func get_snapshot(slot_index: int) -> Dictionary:
	return {
		&"slot_index": slot_index,
		&"skill_id": skill_id,
		&"display_name": display_name,
		&"description": description,
		&"input_action": input_action,
		&"input_label": input_label,
		&"cooldown_seconds": cooldown_seconds,
		&"accent_color": accent_color,
		&"parameters": effect.call(&"get_parameters") if effect != null else {},
	}
