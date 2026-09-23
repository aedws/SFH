class_name InventoryCapacityCatalog
extends RefCounted
const PATH := "res://game/features/inventory/data/container_capacity.csv"
const PAYLOAD := preload("res://game/features/inventory/data/container_capacity_payload.tres")
const COLUMNS := "container_id,stage,display_name,columns,rows,credit_cost,upgrade_enabled,policy_status,planner_note"
var rows: Array[Dictionary] = []
var error := ""

func _init() -> void:
	load_csv(FileAccess.get_file_as_string(PATH) if FileAccess.file_exists(PATH) else PAYLOAD.csv_text)

func load_csv(text: String) -> bool:
	var matrix := preload("res://game/features/balance_data/csv_rows.gd").parse(text)
	if matrix.size() < 4 or ",".join(matrix[0]) != COLUMNS: error = "ContainerCapacity 헤더 오류"; return false
	var next: Array[Dictionary] = []
	var previous := {}
	for i in range(2, matrix.size()):
		var cells := matrix[i]
		if cells.size() != 9 or cells[0] not in ["backpack", "pouch"] or cells[2].is_empty() or cells[6].to_lower() not in ["true", "false"] or cells[7] not in ["confirmed", "provisional", "pending"]: error = "가방 단계 행 오류"; return false
		for index in [1, 3, 4, 5]:
			if not cells[index].is_valid_int(): error = "가방 정수 수치 오류"; return false
		var prior: Dictionary = previous.get(cells[0], {})
		var stage := int(cells[1])
		var columns := int(cells[3])
		var height := int(cells[4])
		var cost := int(cells[5])
		if stage != int(prior.get(&"stage", -1)) + 1 or columns != (12 if cells[0] == "backpack" else 2) or height < 1 or height > (6 if cells[0] == "backpack" else 4) or height <= int(prior.get(&"rows", 0)) or cost < 0 or cost > 10000000 or (stage == 0 and cost != 0): error = "가방 단계 순서/크기/가격 오류"; return false
		var row := {&"container_id": StringName(cells[0]), &"stage": stage, &"display_name": cells[2], &"columns": columns, &"rows": height, &"credit_cost": cost, &"upgrade_enabled": cells[6].to_lower() == "true", &"policy_status": cells[7], &"planner_note": cells[8]}
		if row.policy_status == "pending" and row.upgrade_enabled: error = "미정 가격은 구매 활성화 불가"; return false
		previous[cells[0]] = row
		next.append(row)
	if not previous.has("backpack") or not previous.has("pouch"): error = "가방과 주머니 단계 필요"; return false
	rows = next
	error = ""
	return true

func get_rows() -> Array[Dictionary]: return rows.duplicate(true)
