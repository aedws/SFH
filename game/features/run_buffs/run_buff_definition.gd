class_name RunBuffDefinition
extends Resource

enum MetaTarget {
	CHARACTER,
	WEAPON,
	ARMOR,
}

@export var buff_id: StringName
@export var display_name: String
@export_multiline var description: String
@export_range(1, 99, 1) var maximum_stacks: int = 5
@export var meta_target: MetaTarget = MetaTarget.CHARACTER
@export var player_modifiers: Dictionary = {}
@export var weapon_modifiers: Dictionary = {}
@export_range(0.0, 10000.0, 0.1) var heal_on_apply: float = 0.0


func is_valid() -> bool:
	return (
		buff_id != &""
		and not display_name.is_empty()
		and not description.is_empty()
		and maximum_stacks > 0
		and (not player_modifiers.is_empty() or not weapon_modifiers.is_empty())
	)


func meta_target_id() -> StringName:
	match meta_target:
		MetaTarget.WEAPON:
			return &"weapon"
		MetaTarget.ARMOR:
			return &"armor"
		_:
			return &"character"


func choice_snapshot(current_stacks: int) -> Dictionary:
	return {
		&"buff_id": buff_id,
		&"display_name": display_name,
		&"description": description,
		&"current_stacks": current_stacks,
		&"maximum_stacks": maximum_stacks,
		&"meta_target": meta_target_id(),
	}
