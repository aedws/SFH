class_name OperationSetupStepFlow
extends RefCounted

signal step_changed(snapshot: Dictionary)

const STEP_IDS: Array[StringName] = [&"mission", &"loadout", &"confirm"]
const STEP_LABELS := ["지역·작전", "세팅 확인", "검토·투입"]

var current_step: int = 0


func reset() -> Dictionary:
	return go_to(0)


func move(direction: int) -> Dictionary:
	return go_to(current_step + signi(direction))


func go_to(index: int) -> Dictionary:
	current_step = clampi(index, 0, STEP_IDS.size() - 1)
	var snapshot := get_snapshot()
	step_changed.emit(snapshot)
	return snapshot


func get_snapshot() -> Dictionary:
	return {
		&"step_index": current_step,
		&"step_count": STEP_IDS.size(),
		&"step_id": STEP_IDS[current_step],
		&"step_label": STEP_LABELS[current_step],
		&"can_go_previous": current_step > 0,
		&"can_go_next": current_step < STEP_IDS.size() - 1,
		&"is_confirmation": current_step == STEP_IDS.size() - 1,
	}
