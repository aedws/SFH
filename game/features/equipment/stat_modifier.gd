class_name EquipmentStatModifier
extends Resource

enum Operation {
	ADD,
	MULTIPLY,
}

@export var stat_id: StringName
@export var operation: Operation = Operation.ADD
@export var amount: float = 0.0


func is_valid() -> bool:
	return stat_id != &"" and is_finite(amount)
