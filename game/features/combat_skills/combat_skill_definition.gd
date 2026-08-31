class_name CombatSkillDefinition
extends Resource

@export var skill_id: StringName
@export var display_name: String = "스킬"
@export_multiline var description: String
@export var input_action: StringName
@export var input_label: String = "?"
@export_enum("self", "nearest", "highest_health", "elite", "densest", "direction") var targeting_mode: String = "self"
@export_range(32.0, 2400.0, 8.0) var targeting_range: float = 820.0
@export var required_combat_tags: Array[StringName] = []
@export_range(0.1, 120.0, 0.1) var cooldown_seconds: float = 5.0
@export_range(0.0, 1000.0, 1.0) var energy_cost: float = 0.0
@export_range(1, 10, 1) var maximum_charges: int = 1
@export_range(0.1, 120.0, 0.1) var charge_recovery_seconds: float = 8.0
@export var accent_color: Color = Color(0.25, 0.85, 0.95, 1.0)
@export var effect: Resource


func is_valid() -> bool:
	return (
		skill_id != &""
		and not display_name.is_empty()
		and input_action != &""
		and cooldown_seconds > 0.0
		and energy_cost >= 0.0
		and maximum_charges > 0
		and charge_recovery_seconds > 0.0
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
		&"targeting_mode": targeting_mode,
		&"targeting_range": targeting_range,
		&"required_combat_tags": required_combat_tags.duplicate(),
		&"cooldown_seconds": cooldown_seconds,
		&"energy_cost": energy_cost,
		&"maximum_charges": maximum_charges,
		&"charge_recovery_seconds": charge_recovery_seconds,
		&"accent_color": accent_color,
		&"parameters": effect.call(&"get_parameters") if effect != null else {},
	}
