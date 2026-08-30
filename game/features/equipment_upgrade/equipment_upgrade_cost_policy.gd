class_name EquipmentUpgradeCostPolicy
extends Resource

@export var module_credit_costs := PackedInt32Array([120, 240])
@export var part_credit_costs := PackedInt32Array([180, 360])
@export_range(1, 99, 1) var material_quantity_per_upgrade: int = 1


func validation_errors() -> PackedStringArray:
	var errors := PackedStringArray()
	if module_credit_costs.is_empty() or part_credit_costs.is_empty():
		errors.append("모듈과 파츠 강화 크레딧 표가 필요합니다.")
	for cost in module_credit_costs:
		if cost < 0:
			errors.append("모듈 강화 크레딧은 음수일 수 없습니다.")
	for cost in part_credit_costs:
		if cost < 0:
			errors.append("파츠 강화 크레딧은 음수일 수 없습니다.")
	if material_quantity_per_upgrade <= 0:
		errors.append("강화 재료 수량은 1 이상이어야 합니다.")
	return errors


func quote(
	target_kind: StringName,
	current_level: int,
	_target_id: StringName = &""
) -> Dictionary:
	var costs := module_credit_costs if target_kind == &"module" else part_credit_costs
	var index := clampi(current_level - 1, 0, costs.size() - 1)
	return {
		&"credit_cost": int(costs[index]),
		&"material_quantity": material_quantity_per_upgrade,
	}
