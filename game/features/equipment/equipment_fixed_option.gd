class_name EquipmentFixedOption
extends Resource

## 장비에 영구 귀속되는 고정 옵션입니다.
## 런 버프, 장비 레벨, 모듈 강화와 별도 소스로 계산됩니다.

enum TargetKind {
	PLAYER,
	WEAPON,
}

enum Operation {
	ADD,
	MULTIPLY,
}

@export var option_id: StringName
@export var display_name: String
@export var target_kind: TargetKind = TargetKind.PLAYER
@export var modifier_id: StringName
@export var operation: Operation = Operation.ADD
@export var amount: float = 0.0
@export_multiline var description: String


func is_valid() -> bool:
	return (
		option_id != &""
		and not display_name.is_empty()
		and modifier_id != &""
		and is_finite(amount)
		and (operation != Operation.MULTIPLY or amount > 0.0)
	)


func snapshot() -> Dictionary:
	return {
		&"option_id": option_id,
		&"display_name": display_name,
		&"target_kind": &"player" if target_kind == TargetKind.PLAYER else &"weapon",
		&"modifier_id": modifier_id,
		&"operation": &"add" if operation == Operation.ADD else &"multiply",
		&"amount": amount,
		&"description": description,
		&"scaling_policy": &"fixed_identity",
	}
